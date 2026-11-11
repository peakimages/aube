#!/bin/sh
set -eu

die() {
	echo "verify: $*" >&2
	exit 1
}

cd "$(dirname "$0")"

main() {
	check_download
	unpack
	echo "verify: aube $AUBE_VERSION for $TARGETPLATFORM, $(pin size) bytes and SHA-256 match"
}

check_download() {
	size="$(wc -c < aube.tar.gz | tr -d ' ')"
	[ "$size" = "$(pin size)" ] || die "aube.tar.gz has $size bytes, expected $(pin size)"
	[ "$(sha256sum aube.tar.gz | cut -d ' ' -f 1)" = "$(pin sha256)" ] || die "SHA-256 of aube.tar.gz does not match upstream.json"
}

unpack() {
	mkdir aube
	tar -xzf aube.tar.gz -C aube --no-same-owner
}

pin() {
	jq -r ".$1" aube.json
}

main
