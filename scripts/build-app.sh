#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Building Notch Prompter (release)…"
HOST_ARCH="$(uname -m)"
case "$HOST_ARCH" in
    arm64|x86_64) ;;
    *)
        echo "Unsupported host architecture: $HOST_ARCH" >&2
        exit 1
        ;;
esac
swift build -c release --arch "$HOST_ARCH"

BIN_DIR="$(swift build -c release --arch "$HOST_ARCH" --show-bin-path)"
APP_DIR="$ROOT/dist/Notch Prompter.app"
CONTENTS="$APP_DIR/Contents"

rm -rf "$APP_DIR"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BIN_DIR/NotchPrompterApp" "$CONTENTS/MacOS/NotchPrompter"
cp "$ROOT/Assets/AppIcon.icns" "$CONTENTS/Resources/AppIcon.icns"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Notch Prompter</string>
    <key>CFBundleExecutable</key>
    <string>NotchPrompter</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.NotchPrompter</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Notch Prompter</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSArchitecturePriority</key>
    <array>
        <string>$HOST_ARCH</string>
    </array>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

chmod +x "$CONTENTS/MacOS/NotchPrompter"
BUILT_ARCHS="$(lipo -archs "$CONTENTS/MacOS/NotchPrompter")"
if [[ "$BUILT_ARCHS" != "$HOST_ARCH" ]]; then
    echo "Expected a host-only $HOST_ARCH executable, found: $BUILT_ARCHS" >&2
    exit 1
fi
echo "Created: $APP_DIR"
echo "Architecture: $BUILT_ARCHS (host-only bundle)"
echo "Launch with: open \"$APP_DIR\""
