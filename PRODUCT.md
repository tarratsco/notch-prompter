# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack

Swift 6 package executable using SwiftUI and AppKit, targeting macOS 14 and
newer. The app must run with `swift run` using Apple's Command Line Tools and
also ship with a CLI script that assembles an unsigned `.app` bundle.

## Users

The primary user records videos or joins video calls on a notched MacBook and
wants to read a prepared script while keeping their gaze close to the camera.
The initial release is designed for personal use by someone who is new to
Swift.

## Product Purpose

Notch Prompter places an auto-scrolling script immediately below the MacBook
camera notch. Success means the user can load a script, set a comfortable
reading pace, start with a short countdown, and deliver it naturally without
looking away from the camera.

## Positioning

Unlike a conventional floating teleprompter window, Notch Prompter uses the
physical notch as the visual anchor and expands downward only when needed,
keeping the words and the camera in the same line of sight.

## Operating Context

The user prepares a script by pasting text or opening or dropping a `.txt` or
`.md` file. They adjust words per minute, a manual speed multiplier, and font
size in an editor window, then control playback from the notch panel or a
keyboard shortcut while another recording or calling app is active.

## Capabilities and Constraints

- The first release targets macOS 14+ and must build without full Xcode.
- The primary launch path is `swift run`.
- A CLI packaging script must create an unsigned, host-architecture `.app`
  bundle for local use or sharing between Macs of the same architecture;
  signing, notarization, and universal binaries are outside the first release.
- The notch surface is a transparent, always-on-top AppKit panel hosting
  SwiftUI content.
- Notched MacBooks receive physical-notch alignment; other screens receive a
  centered floating-pill fallback.
- Script input supports paste, `.txt`, Markdown, and drag and drop.
- Playback supports WPM-based scrolling, a manual multiplier, play/pause,
  adjustable font size, and a 3-2-1 countdown.
- Remote iPhone control and mirror-rig text reversal are outside v1.

## Brand Commitments

The product name is **Notch Prompter**. Boring Notch is a functional and
quality reference for making the physical notch feel like part of a native
macOS interface, not a requirement to copy its visual identity.

## Evidence on Hand

There are no existing brand assets, screenshots, user research, testimonials,
or performance claims. Future work must not fabricate them.

## Product Principles

- Keep the reader's eyes close to the camera.
- Make starting, pausing, and correcting pace possible without breaking flow.
- Treat the notch as useful hardware, not decoration.
- Keep setup legible to a Swift beginner and dependency-free where practical.
- Preserve a usable fallback on displays without a notch.

## Accessibility & Inclusion

Controls must support keyboard use, VoiceOver labels, reduced-motion
preferences, and high-contrast text. Font size and scroll pace must remain
adjustable during use.
