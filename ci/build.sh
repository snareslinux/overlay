#!/bin/bash
set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
VOID_PACKAGES="${VOID_PACKAGES:-$HOME/void-packages}"
OVERLAY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRCPKGS_DIR="$OVERLAY_DIR/srcpkgs"
LOGDIR="$OVERLAY_DIR/ci/logs"

# Build order matters — deps before dependents
PACKAGES=(
    snares-release
    snares-kernel-config
    snares-dinit
    snares-apparmor-profiles
    snares-dinit-services
    snares-base
)

# ─── Checks ───────────────────────────────────────────────────────────────────
if [[ ! -d "$VOID_PACKAGES" ]]; then
    echo "ERROR: void-packages not found at $VOID_PACKAGES"
    echo "Set VOID_PACKAGES=/path/to/void-packages or clone it there."
    exit 1
fi

if [[ ! -x "$VOID_PACKAGES/xbps-src" ]]; then
    echo "ERROR: xbps-src not found or not executable in $VOID_PACKAGES"
    exit 1
fi

# ─── Setup ────────────────────────────────────────────────────────────────────
mkdir -p "$LOGDIR"

echo "==> Linking overlay packages into void-packages..."
for pkg in "$SRCPKGS_DIR"/*/; do
    pkgname="$(basename "$pkg")"
    target="$VOID_PACKAGES/srcpkgs/$pkgname"

    if [[ -e "$target" && ! -L "$target" ]]; then
        echo "ERROR: $target exists and is not a symlink — refusing to overwrite"
        exit 1
    fi

    ln -sf "$pkg" "$target"
    echo "    linked: $pkgname"
done

# ─── Build ────────────────────────────────────────────────────────────────────
cd "$VOID_PACKAGES"

FAILED=()

for pkg in "${PACKAGES[@]}"; do
    echo ""
    echo "==> Building $pkg..."
    logfile="$LOGDIR/${pkg}.log"

    if ./xbps-src pkg "$pkg" > "$logfile" 2>&1; then
        echo "    OK: $pkg"
    else
        echo "    FAILED: $pkg (see ci/logs/${pkg}.log)"
        FAILED+=("$pkg")
    fi
done

# ─── Report ───────────────────────────────────────────────────────────────────
echo ""
echo "─── Build summary ───────────────────────────────────────────────────────"

if [[ ${#FAILED[@]} -eq 0 ]]; then
    echo "All packages built successfully."
    echo ""
    echo "Packages are in:"
    echo "  $VOID_PACKAGES/hostdir/binpkgs/"
    exit 0
else
    echo "Failed packages:"
    for pkg in "${FAILED[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    echo "Check ci/logs/ for details."
    exit 1
fi#!/bin/bash
set -e

VOID_PACKAGES=${VOID_PACKAGES:-~/void-packages}
OVERLAY_DIR=$(dirname "$(readlink -f "$0")")/..

# Symlink overlay packages into void-packages
for pkg in "$OVERLAY_DIR"/srcpkgs/*/; do
    pkgname=$(basename "$pkg")
    ln -sf "$pkg" "$VOID_PACKAGES/srcpkgs/$pkgname"
done

# Build all snares packages in dependency order
cd "$VOID_PACKAGES"
./xbps-src pkg snares-kernel-config
./xbps-src pkg snares-dinit
./xbps-src pkg snares-apparmor-profiles
./xbps-src pkg snares-dinit-services
./xbps-src pkg snares-base

echo "All packages built successfully."
