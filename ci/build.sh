#!/usr/bin/env bash
set -e

OVERLAY="$HOME/snares-overlay/srcpkgs"
VOIDSRC="$HOME/void-packages/srcpkgs"
XBPS="$HOME/void-packages/xbps-src"

echo "=== Syncing overlay → void-packages ==="

if [ ! -d "$OVERLAY" ]; then
    echo "Overlay not found: $OVERLAY"
    exit 1
fi

if [ ! -d "$VOIDSRC" ]; then
    echo "void-packages srcpkgs not found: $VOIDSRC"
    exit 1
fi

# Sync step
for pkg in "$OVERLAY"/*; do
    name=$(basename "$pkg")
    dest="$VOIDSRC/$name"

    echo "Syncing $name"

    rm -rf "$dest"
    cp -a "$pkg" "$dest"
done

echo "=== Sync complete ==="
echo

echo "=== Starting builds ==="

# Build step
for pkg in "$OVERLAY"/*; do
    name=$(basename "$pkg")

    echo ">>> Building $name"

    if ! "$XBPS" pkg "$name"; then
        echo "!!! Build failed: $name"
        echo "Continuing with next package..."
    fi

    echo
done

echo "=== All done ==="
