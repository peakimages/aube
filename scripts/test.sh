#!/usr/bin/env bash
set -euo pipefail

OPTION="$*"
IMAGE="${1:-}"
PACKAGE=picocolors
PACKAGE_VERSION=1.1.1
WORK_DIR="$(mktemp -d)"

BOLD=$'\033[1m' GREEN=$'\033[32m' RED=$'\033[31m' RESET=$'\033[0m'

heading() { printf '\n  %s%s%s\n' "$BOLD" "$*" "$RESET"; }
ok() { printf '  %s✔%s %s\n' "$GREEN" "$RESET" "$*"; }
die() {
	printf '  %s✖%s %s\n' "$RED" "$RESET" "$*" >&2
	exit 1
}

cd "$(dirname "$0")/.."
trap 'rm -rf "$WORK_DIR"' EXIT

main() {
	[[ "$OPTION" =~ ^[^-][^[:space:]]*$ ]] || die "'$OPTION' is not an option, expected an image"
	heading "Testing $IMAGE"
	read_labels
	check_version
	if [ -z "$node_version" ]; then
		check_copied_binary
	else
		heading "Build"
		build_project
		check_unprivileged_user
		check_runtime_pin
		check_package_manager_pin
	fi
	heading "All tests passed for $IMAGE"
}

read_labels() {
	version="$(label aube.version)"
	node_version="$(label node.version)"
}

check_version() {
	local printed
	jq -e --arg version "$version" 'any(.aube[]; .version == $version)' src/upstream.json > /dev/null || die "the image is labeled aube $version, src/upstream.json pins no such version"
	printed="$(aube --version)"
	[[ "$printed" == "$version "* ]] || die "aube --version prints '$printed', expected $version"
	ok "aube --version prints $version, a version src/upstream.json pins"
}

check_copied_binary() {
	local container base printed
	container="$(docker create "$IMAGE")"
	docker cp "$container:/usr/local/bin" "$WORK_DIR/bin" > /dev/null
	docker rm "$container" > /dev/null
	base="$(sed -n 's/^ARG BASE_IMAGE=//p' src/Dockerfile)"
	printed="$(docker run --rm -v "$WORK_DIR/bin:/usr/local/bin:ro" "$base" sh -c 'aube --version && aubr --version && aubx --version' | cut -d ' ' -f 1 | tr '\n' ' ')"
	[ "$printed" = "$version $version $version " ] || die "aube, aubr and aubx print '$printed' in ${base%%@*}, expected $version three times"
	ok "aube, aubr and aubx run when copied into ${base%%@*}"
}

build_project() {
	local result
	mkdir "$WORK_DIR/project"
	jq -n --arg package "$PACKAGE" --arg version "$PACKAGE_VERSION" \
		'{name: "aube-test", private: true, type: "module", scripts: {build: "node build.js"}, dependencies: {($package): $version}}' > "$WORK_DIR/project/package.json"
	echo "import colors from \"$PACKAGE\"; console.log(typeof colors.bold === \"function\" ? \"built with $PACKAGE\" : \"broken\");" > "$WORK_DIR/project/build.js"
	tar -cf "$WORK_DIR/project.tar" -C "$WORK_DIR/project" package.json build.js
	result="$(in_project sh -c 'tar -xf - && aube install > /dev/null 2>&1 && aube ci > /dev/null 2>&1 && aube run --no-install build 2> /dev/null | tail -n 1 && ls aube-lock.yaml && { find node_modules -type l -exec readlink {} \; | grep -c "^/" || true; }' | tr '\n' ' ')"
	[ "$result" = "built with $PACKAGE aube-lock.yaml 0 " ] || die "install and build gave '$result', expected the build output, a lockfile and no link out of node_modules"
	ok "aube install, aube ci and aube run build work, node_modules has no link that leaves the project"
}

check_unprivileged_user() {
	local result
	result="$(docker run --rm -i --user 65532:65532 --workdir /home/nonroot "$IMAGE" sh -c 'tar -xf - && aube install > /dev/null 2>&1 && aube run --no-install build 2> /dev/null | tail -n 1' < "$WORK_DIR/project.tar")"
	[ "$result" = "built with $PACKAGE" ] || die "install and build as 65532 gave '$result', expected the build output"
	ok "aube install and aube run build work as the unprivileged user 65532 too"
}

check_runtime_pin() {
	local output
	output="$(in_project sh -c 'tar -xf - && echo 18 > .node-version && aube install 2>&1; ls /root/.local/share/aube/nodejs 2> /dev/null' || true)"
	[[ "$output" == *ERR_AUBE_RUNTIME_VERSION_UNSATISFIED* ]] || die "a project that pins Node.js 18 did not fail with ERR_AUBE_RUNTIME_VERSION_UNSATISFIED"
	[[ "$output" != *18.* ]] || die "aube downloaded Node.js 18"
	ok "a project that pins another Node.js fails with ERR_AUBE_RUNTIME_VERSION_UNSATISFIED, nothing is downloaded"
}

check_package_manager_pin() {
	local printed
	printed="$(in_project sh -c 'tar -xf - && echo "{\"packageManager\": \"aube@2.0.0\"}" > package.json && aube --version; ls /root/.local/share/aube/self 2> /dev/null; true')"
	[[ "$printed" == "$version "* && "$printed" != *$'\n'* ]] || die "a project that pins aube 2.0.0 gave '$printed', expected $version and no download"
	ok "a project that pins another aube still runs $version, nothing is downloaded"
}

label() { docker image inspect "$IMAGE" --format "{{index .Config.Labels \"dev.peakimages.$1\"}}"; }

run() { docker run --rm "$IMAGE" "$@"; }

aube() {
	if [ -z "$node_version" ]; then
		run "$@"
	else
		run aube "$@"
	fi
}

in_project() { docker run --rm -i "$IMAGE" "$@" < "$WORK_DIR/project.tar"; }

main
