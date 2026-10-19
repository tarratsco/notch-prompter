#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSET_DIR="$ROOT/Assets"
ICONSET_DIR="$ASSET_DIR/AppIcon.iconset"
MASTER_ICON="$ICONSET_DIR/icon_512x512@2x.png"

rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

swift "$ROOT/scripts/generate-app-icon.swift" "$MASTER_ICON"

while read -r filename size; do
    sips -z "$size" "$size" "$MASTER_ICON" --out "$ICONSET_DIR/$filename" >/dev/null
done <<'SIZES'
icon_16x16.png 16
icon_16x16@2x.png 32
icon_32x32.png 32
icon_32x32@2x.png 64
icon_128x128.png 128
icon_128x128@2x.png 256
icon_256x256.png 256
icon_256x256@2x.png 512
icon_512x512.png 512
SIZES

iconutil -c icns "$ICONSET_DIR" -o "$ASSET_DIR/AppIcon.icns"
echo "Created: $ASSET_DIR/AppIcon.icns"

