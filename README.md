# Notch Prompter

Notch Prompter is a native macOS teleprompter that keeps your script close to
the camera. It has a normal script editor and an always-on-top notch panel with
a 3–2–1 cue, smooth WPM-based scrolling, and compact playback controls.

## Requirements

- macOS 14 Sonoma or newer
- Apple Command Line Tools with Swift 6 (validated with Swift 6.1.2; full Xcode
  is not required)

Check Swift:

```bash
swift --version
```

## Run from source

From this folder:

```bash
swift run NotchPrompterApp
```

Or use the convenience script:

```bash
./scripts/run.sh
```

The first build can take a little longer. The editor opens with a sample script
ready to try. Press **Command-Shift-P** to play or pause.

## Use the app

1. Paste or type in the editor, click **Open Script**, or drop a UTF-8 `.txt`,
   `.md`, or `.markdown` file onto the editor.
2. Set WPM, speed trim, text size, and the countdown option.
3. Keep the panel expanded while reading, or collapse it to a small status pill.
4. Press Play. When the cue is enabled, the notch shows a red 3–2–1 before the
   script moves.
5. Read the warm-white line crossing the fixed red guide, positioned 22% down
   the reading viewport to keep your gaze near the camera. Wrapped lines are
   tracked individually while the surrounding script remains dimmed.
6. If you miss a line, scroll directly over the prompt with a mouse or
   trackpad. Manual scrolling pauses playback so it does not fight your
   correction.
7. Use the footer’s up/down controls to step one visual line at a time, drag
   the progress slider to scrub farther, or use Reset to return to the
   beginning.

The menu-bar caption icon can show the editor or panel and control playback
when the editor is hidden.

## Keyboard shortcut

**Command-Shift-P** works system-wide while Notch Prompter is running. It uses
macOS's exact hotkey registration API and does not monitor keystrokes or require
Accessibility or Input Monitoring permission. If another app has already
reserved the shortcut, Notch Prompter reports that registration failed and the
Play / Pause command remains available from its app and status menus.

## Test and build

Run unit tests for Markdown conversion and playback logic:

```bash
swift test
```

Build a debug executable:

```bash
swift build
```

Build a release executable:

```bash
swift build -c release
```

## Create a local app bundle

No Xcode project is needed:

```bash
./scripts/build-app.sh
open "dist/Notch Prompter.app"
```

The script builds for the current Mac's architecture, verifies the executable
with `lipo`, and assembles:

```text
dist/Notch Prompter.app/
└── Contents/
    ├── Info.plist
    ├── MacOS/NotchPrompter
    └── Resources/AppIcon.icns
```

The packaged app includes a custom Broadcast Cue icon. To regenerate its
complete macOS icon set after changing the vector drawing:

```bash
./scripts/generate-app-icon.sh
```

This bundle is host-architecture-only (`arm64` on Apple silicon or `x86_64` on
Intel), unsigned, and unnotarized. Build separately on each architecture when
sharing with a different kind of Mac. If macOS quarantines a copied bundle,
Control-click it in Finder and choose **Open**.

## Development and validation

Render deterministic snapshots of the shipping SwiftUI views without launching
the interactive app. The expanded-panel snapshot includes the active
warm-white visual line and dimmed surrounding lines:

```bash
./scripts/capture-ui.sh
```

This writes `editor.png` (1040×680) and `prompter-panel.png` (640×420) under
`.impeccable/review/`.

## Current limitations

- Command-Shift-P is unavailable if another running app has reserved the same
  system-wide hotkey.
- The panel uses the active editor display. On a notched screen it derives the
  camera gap from `safeAreaInsets` and the auxiliary top areas; other displays
  use a centered top pill.
- “Always on top” uses a status-bar-level panel that joins all Spaces and is
  allowed beside full-screen windows. macOS and some exclusive full-screen apps
  can still place protected content above it.
- Markdown is intentionally converted conservatively to readable plain text;
  complex tables and embedded media are not rendered.
- Settings and scripts are not persisted between launches in this first build.
