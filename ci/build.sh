#!/bin/bash

set -e

VOID_PACKAGES=${VOID_PACKAGES:-~/void-packages}
OVERLAY_DIR=$(dirname "$(readlink -f "$0")")/..

for pkg in "$OVERLAY_DIR"/srcpkgs/*/; do
	pkgname=$(basename "$pkg")
	ln -sf "$pkg" "$VOID_PACKAGES/srcpkgs/$pkgname"
done

cd "$VOID_PACKAGES"
./xbps-src pkg snares-kernel-config
./xbps-src pkg snares-dinit
./xbps-src pkg snares-apparmor-profiles
./xbps-src pkg snares-dinit-services
./xbps-src pkg snares-release
./xbps-src pkg snares-base

echo "All packages built successfully."
