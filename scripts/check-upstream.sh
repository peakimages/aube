#!/usr/bin/env bash
set -euo pipefail

OPTION="$*"
REPOSITORY=aubepkg/aube
IDENTITY="^https://github\\.com/$REPOSITORY/\\.github/workflows/[^/@]+@refs/heads/main$"
ISSUER=https://token.actions.githubusercontent.com
# https://github.com/sigstore/cosign/releases/tag/v3.1.4
COSIGN=ghcr.io/sigstore/cosign/cosign:v3.1.4
WORK_DIR="$(mktemp -d)"

BOLD=$'\033[1m' BLUE=$'\033[34m' GREEN=$'\033[32m' RED=$'\033[31m' RESET=$'\033[0m'

info() { printf '  %sℹ%s %s\n' "$BLUE" "$RESET" "$*"; }
ok() { printf '  %s✔%s %s\n' "$GREEN" "$RESET" "$*"; }
die() {
	printf '  %s✖%s %s\n' "$RED" "$RESET" "$*" >&2
	exit 1
}

cd "$(dirname "$0")/.."
trap 'rm -rf "$WORK_DIR"' EXIT

main() {
	[ -z "$OPTION" ] || die "'$OPTION' is not an option, expected none"
	docker info > /dev/null 2>&1 || die "docker is not running"
	read_newest_release
	compare_with_pinned
	download_release
	verify_signatures
	write_upstream_json
	verify_archives
	update_dockerfile
}

read_newest_release() {
	version="$(gh api "repos/$REPOSITORY/releases/latest" --jq '.tag_name | ltrimstr("v")')"
	[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "the latest release of $REPOSITORY is '$version', expected major.minor.patch"
}

compare_with_pinned() {
	local pinned
	pinned="$(jq -r '.aube.latest.version // empty' src/upstream.json)"
	if [ "$version" = "$pinned" ]; then
		ok "aube $BOLD$pinned$RESET is pinned and the newest release on GitHub"
		exit 0
	fi
	info "GitHub lists aube $BOLD$version$RESET, ${pinned:-no version} is pinned"
}

download_release() {
	local arch
	fetch "$WORK_DIR/packslip.sigstore.json" packslip.sigstore.json
	for arch in x86_64 aarch64; do
		fetch "$WORK_DIR/$(archive "$arch")" "$(archive "$arch")"
	done
	ok "downloaded the signed manifest and the archives for linux/amd64 and linux/arm64"
}

verify_signatures() {
	local arch described
	for arch in x86_64 aarch64; do
		docker run --rm --user "$(id -u):$(id -g)" -e HOME=/mnt -v "$WORK_DIR:/mnt" -w /mnt "$COSIGN" verify-blob-attestation "$(archive "$arch")" \
			--bundle packslip.sigstore.json --type https://packslip.dev/release/v1 \
			--certificate-identity-regexp "$IDENTITY" --certificate-oidc-issuer "$ISSUER" > /dev/null 2>&1 \
			|| die "$(archive "$arch") is not signed by a workflow on the main branch of $REPOSITORY"
	done
	jq -r '.dsseEnvelope.payload | @base64d' "$WORK_DIR/packslip.sigstore.json" > "$WORK_DIR/statement.json"
	described="$(jq -r .predicate.version "$WORK_DIR/statement.json")"
	[ "$described" = "$version" ] || die "the signed manifest describes aube $described, expected $version"
	ok "both archives are in the manifest signed by a workflow on the main branch of $REPOSITORY"
}

write_upstream_json() {
	jq --tab --arg version "$version" --slurpfile statement "$WORK_DIR/statement.json" '
		def pin($arch): $statement[0] as $signed
			| ($signed.predicate.artifacts[] | select(.os == "linux" and .libc == "musl" and .arch == $arch)) as $artifact
			| {url: $artifact.url, size: $artifact.size, sha256: ($signed.subject[] | select(.name == $artifact.name) | .digest.sha256)};
		.aube.latest = {$version, commit: $statement[0].predicate.source.commit, platforms: {"linux/amd64": pin("x86_64"), "linux/arm64": pin("aarch64")}}' src/upstream.json > "$WORK_DIR/upstream.json"
	cp "$WORK_DIR/upstream.json" src/upstream.json
	ok "src/upstream.json pins $BOLD$version$RESET with url, size and SHA-256 per platform from the signed manifest"
}

verify_archives() {
	local platform
	for platform in linux/amd64:x86_64 linux/arm64:aarch64; do
		mkdir -p "$WORK_DIR/${platform%:*}"
		cp src/verify.sh "$WORK_DIR/${platform%:*}"
		cp "$WORK_DIR/$(archive "${platform#*:}")" "$WORK_DIR/${platform%:*}/aube.tar.gz"
		jq --arg platform "${platform%:*}" '.aube.latest.platforms[$platform]' src/upstream.json > "$WORK_DIR/${platform%:*}/aube.json"
		AUBE_VERSION="$version" TARGETPLATFORM="${platform%:*}" sh "$WORK_DIR/${platform%:*}/verify.sh" > /dev/null
	done
	ok "src/verify.sh accepts the downloads for linux/amd64 and linux/arm64 against the new pin"
}

update_dockerfile() {
	sed -E "s|^ARG AUBE_VERSION=.*|ARG AUBE_VERSION=$version|" src/Dockerfile > "$WORK_DIR/Dockerfile"
	cp "$WORK_DIR/Dockerfile" src/Dockerfile
	ok "src/Dockerfile sets AUBE_VERSION $BOLD$version$RESET"
}

fetch() {
	curl --proto '=https' --tlsv1.2 -sSfL --retry 3 -o "$1" "https://github.com/$REPOSITORY/releases/download/v$version/$2"
}

archive() {
	echo "aube-v$version-$1-unknown-linux-musl.tar.gz"
}

main
