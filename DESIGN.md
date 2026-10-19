---
name: Notch Prompter
description: A matte broadcast cue console anchored to the MacBook camera notch.
colors:
  live-red: "rgb(78% 8% 6%)"
  canvas: "rgb(5.5% 5.5% 6%)"
  raised: "rgb(9% 9% 10%)"
  control: "rgb(14% 13.5% 14%)"
  warm-text: "rgb(96% 93% 87%)"
  secondary-text: "rgb(65% 62% 57%)"
  separator: "rgb(100% 100% 100% / 12%)"
  prompt-black: "#000000"
  prominent-text: "#ffffff"
typography:
  countdown:
    fontFamily: "SF Pro Rounded, -apple-system, sans-serif"
    fontSize: "118pt"
    fontWeight: 700
  prompt:
    fontFamily: "SF Pro, -apple-system, sans-serif"
    fontSize: "38pt"
    fontWeight: 500
  headline:
    fontFamily: "SF Pro, -apple-system, sans-serif"
    fontSize: "20pt"
    fontWeight: 600
  body:
    fontFamily: "SF Pro, -apple-system, sans-serif"
    fontSize: "17pt"
    fontWeight: 400
  control:
    fontFamily: "SF Pro, -apple-system, sans-serif"
    fontSize: "12pt"
    fontWeight: 600
  measurement:
    fontFamily: "SF Mono, ui-monospace, monospace"
    fontSize: "15pt"
    fontWeight: 600
rounded:
  control: "7pt"
  panel-collapsed: "12pt"
  panel-expanded: "16pt"
spacing:
  compact: "8pt"
  tight: "10pt"
  standard: "12pt"
  section: "20pt"
  workspace: "22pt"
---

# Design System: Notch Prompter

## Overview

**Creative North Star: Broadcast Cue**

Notch Prompter behaves like a compact confidence monitor built into studio
hardware. Near-black planes, warm reading text, fine separators, restrained
controls, and a single live-red signal create a focused operating environment.
The physical notch is the camera and cue anchor; the interface expands
downward from that axis.

The system is dense but calm. Native macOS behavior remains visible through
system typography, sliders, switches, menus, alerts, keyboard commands, and SF
Symbols. Expression comes from disciplined tonal layering, the central reading
guide, tactile transport controls, and the red 3-2-1 countdown—not gradients,
decorative glass, or collections of floating cards.

The application icon condenses this world into a matte macOS squircle: the
notch-attached shell surrounds warm prompt lines with the active line crossing
the single Live Red reading guide. It stays geometric and legible at Dock size
without introducing a separate logo language.

## Colors

- **Live Red:** Primary Play action, active status, countdown numerals,
  progress, and the reading guide. White on Live Red is verified at 5.94:1.
- **Prompt Black:** Expanded notch panel and preview field.
- **Canvas Graphite:** Lowest editor plane.
- **Raised Graphite:** Title bar, script surface, preview rail, and controls.
- **Control Graphite:** Secondary and inactive transport controls.
- **Warm Reading White:** Scripts, headings, and primary labels.
- **Studio Gray:** Metadata, inactive status, and supporting guidance.
- **Fine Separator:** One-pixel boundaries between adjoining surfaces.

**The Live Red Rule.** Reserve Live Red for playback-critical actions and
states. It does not decorate neutral setup surfaces.

**The Warm Legibility Rule.** Reading content and primary labels use Warm
Reading White. Studio Gray is secondary information only.

## Typography

The typography is direct and operational. Medium and semibold weights establish
hierarchy without ornament. Large type belongs to delivered words and the
countdown; surrounding controls remain compact.

- **Countdown:** 118pt, bold, rounded, tabular.
- **Prompt:** Adjustable 24–72pt, default 38pt, medium, centered.
- **Workspace headline:** 20pt semibold.
- **Editor body:** 17pt regular with 5pt additional line spacing.
- **Application title:** 15pt semibold.
- **Controls:** 12pt medium or semibold.
- **Measurements:** 15pt semibold monospaced tabular figures.
- **Timing and metadata:** 10–11pt monospaced tabular figures.

**The Utility Mono Rule.** Monospaced figures belong only to timing, progress,
word count, WPM, rate, and point measurements.

**The Prompt Owns the Scale Rule.** Prompt copy and countdown digits own the
largest type. Application chrome never competes with the script.

## Layout

The editor opens at 1040×680pt and remains usable down to 820×570pt. A 58pt
title bar sits over a split workspace. The script side has a 480pt minimum and
680pt ideal width; the control rail has a 286pt minimum, 320pt ideal, and
360pt maximum. The rail keeps a functional preview above transport and reading
controls.

The primary rhythm uses 20–22pt section spacing and outer insets, with 8–12pt
gaps inside compact control groups. The script editor uses 22pt horizontal
insets; panel chrome uses 10–12pt insets and prompt copy uses 28pt.

The notch panel has two postures. On a notched screen, both begin at the
physical top edge and use the top band for controls positioned on either side
of the camera housing. Collapsed mode is 50pt high and reserves 148pt of
control clearance on each side of the physical notch, clamped between 520 and
680pt overall. Expanded mode grows to at most 640×420pt. Non-notched screens
use the visible-frame top center.

**The Camera Axis Rule.** Prompt text, countdown numerals, and reading guide
stay centered on the notch or fallback screen axis.

**The Working Split Rule.** The first editor view preserves both the script
workspace and the preview/control rail; it is not replaced by a dashboard.

## Elevation and Shape

Hierarchy comes from graphite tone changes and fine borders, not custom
decorative shadows. The always-on-top AppKit panel keeps its native window
shadow, while inner surfaces remain matte and flat.

Controls use continuous 7pt corners. The script workspace and live preview use
9–10pt corners. The notch shell uses 12pt while collapsed and 16pt while
expanded. When attached to a physical notch, its upper corners are concave
20pt shoulders with a continuous cubic curve: the shell spans wider along the
screen edge, then eases inward to its narrower body. The non-notched fallback
keeps ordinary rounded top corners.

**The Matte Layer Rule.** Do not introduce gradients, glow effects, decorative
translucency, or ornamental texture.

**The Native Shadow Rule.** Reserve elevation for the operating-system panel
shadow.

**The Posture Radius Rule.** The panel becomes more rounded as it expands.

**The Screen-Edge Shoulder Rule.** A notched panel uses concave upper
shoulders and rounded lower corners; only the fallback pill is rounded on all
four corners.

## Components and Motion

- **Primary playback button:** Live Red, prominent white label, 32pt minimum
  height, 13pt horizontal padding, and 7pt corners. It appears only while
  playback is idle.
- **Secondary studio button:** Control Graphite with Warm Reading White.
- **Transport button:** SF Symbol at 14pt semibold in a 34×32pt control, with
  an accessibility label and help text.
- **Status indicator:** Unfilled 6pt dot and compact label. Active states use
  Live Red and Warm Reading White; inactive states use Studio Gray.
- **Measurement label:** 15pt semibold monospaced value paired with a smaller
  tracked unit.
- **Live preview:** 126pt-high black field with centered warm text and a
  one-pixel Live Red reading guide.
- **Expanded panel:** 52pt status header, centered reading viewport,
  separators, and a 56pt transport footer.
- **Manual navigation:** Scrolling over the prompt pauses playback and seeks
  by the trackpad or wheel delta. Separated single-arrow controls step to exact
  neighboring TextKit line centers and disable at the script bounds; the
  progress slider supports larger scrubs.
- **Prompt line focus:** The exact wrapped line fragment crossing the fixed
  reading guide—positioned 22% down the reading viewport—uses Warm Reading
  White at full opacity. All other visual lines use the same color at 42%
  opacity, retaining large-text contrast while making the current line
  unmistakable.

Attached panel chrome uses 32pt horizontal insets, clearing the 20pt shoulders
and leaving 12pt of visible breathing room inside the narrower body. The
expanded header is 52pt high; 32pt controls therefore keep 10pt above and
below. The 50pt compact panel keeps 9pt above and below.

Panel posture changes use a 180ms ease-out transition. Countdown digits use
the native numeric transition. Both defer to Reduce Motion. Button press
feedback lowers opacity to 76%.

The expanded prompt uses the macOS 14 TextKit layout stack
(`NSTextStorage`/`NSLayoutManager`/`NSTextContainer`) so line focus follows
actual centered wrapping at every panel width and prompt size. Layout reporting
is coalesced onto the next main-run-loop turn for stable playback math. The
first visual line begins centered on the guide, and completion centers the last
visual line there using exact TextKit fragment centers. The prompt exposes the
full script to accessibility, with the current visual line available as help
text only when the selected fragment changes.

## Do and Don't

Do reserve Live Red for playback-critical actions and states; keep prompt copy
warm-white, centered, and dominant; use SF Symbols; use tabular figures for
changing measurements; preserve the working split; honor Reduce Motion; and
make pause immediate during countdown and playback.

Do not introduce gradients, decorative glass, glow, or custom offset shadows;
spread Live Red across secondary controls; turn each setting group into a
card; use monospaced type for prose; or replace native controls with web-style
imitations.

The current implementation contains compact uppercase group labels for
scannability. They are implementation evidence, not a reusable requirement for
future surfaces.
