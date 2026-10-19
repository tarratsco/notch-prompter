#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

OUTPUT_DIR="$ROOT/.impeccable/review"
mkdir -p "$OUTPUT_DIR"
rm -f \
    "$OUTPUT_DIR/editor.png" \
    "$OUTPUT_DIR/prompter-panel.png" \
    "$OUTPUT_DIR/prompter-panel-collapsed.png"

swift build
BIN_DIR="$(swift build --show-bin-path)"
NOTCH_PROMPTER_SNAPSHOT_DIR="$OUTPUT_DIR" "$BIN_DIR/NotchPrompterApp"

test -s "$OUTPUT_DIR/editor.png"
test -s "$OUTPUT_DIR/prompter-panel.png"
test -s "$OUTPUT_DIR/prompter-panel-collapsed.png"

EDITOR_SIZE="$(sips -g pixelWidth -g pixelHeight "$OUTPUT_DIR/editor.png" 2>/dev/null | awk '/pixelWidth:/{w=$2} /pixelHeight:/{h=$2} END{print w "x" h}')"
PANEL_SIZE="$(sips -g pixelWidth -g pixelHeight "$OUTPUT_DIR/prompter-panel.png" 2>/dev/null | awk '/pixelWidth:/{w=$2} /pixelHeight:/{h=$2} END{print w "x" h}')"
COLLAPSED_SIZE="$(sips -g pixelWidth -g pixelHeight "$OUTPUT_DIR/prompter-panel-collapsed.png" 2>/dev/null | awk '/pixelWidth:/{w=$2} /pixelHeight:/{h=$2} END{print w "x" h}')"

test "$EDITOR_SIZE" = "1040x680"
test "$PANEL_SIZE" = "640x420"
test "$COLLAPSED_SIZE" = "548x50"

echo "Captured: $OUTPUT_DIR/editor.png ($EDITOR_SIZE)"
echo "Captured: $OUTPUT_DIR/prompter-panel.png ($PANEL_SIZE)"
echo "Captured: $OUTPUT_DIR/prompter-panel-collapsed.png ($COLLAPSED_SIZE)"
