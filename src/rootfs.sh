#!/bin/sh
set -eu

die() {
	echo "rootfs: $*" >&2
	exit 1
}

main() {
	install_binaries
	create_user
	echo "rootfs: aube $AUBE_VERSION installed with the aubr and aubx links"
}

install_binaries() {
	install -D -m 0755 /src/aube/aube /rootfs/usr/local/bin/aube
	ln -s aube /rootfs/usr/local/bin/aubr
	ln -s aube /rootfs/usr/local/bin/aubx
	reported="$(/rootfs/usr/local/bin/aube --version)"
	[ "${reported%% *}" = "$AUBE_VERSION" ] || die "aube reports '$reported', expected $AUBE_VERSION"
}

create_user() {
	install -d /rootfs/etc
	echo "nonroot:x:65532:65532:nonroot:/:/sbin/nologin" > /rootfs/etc/passwd
	echo "nonroot:x:65532:" > /rootfs/etc/group
}

main
