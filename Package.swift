// swift-tools-version: 6.0
import PackageDescription

// Notch Prompter is split into two targets:
//   - NotchPrompterCore: reusable logic (view model, playback math, Markdown
//     stripping, script loading) with no SwiftUI view code, so it can be
//     unit tested quickly with `swift test`.
//   - NotchPrompterApp: the executable that wires the core logic into an
//     AppKit + SwiftUI app (windows, panel, menu bar item, shortcuts).
//
// Both targets opt into the Swift 5 language mode. The package still uses
// the Swift 6 toolchain/compiler (see README for the exact version we
// validated against), but Swift 6's strict concurrency checker adds a lot
// of ceremony around AppKit delegate callbacks and Timer closures that
// would not meaningfully improve correctness for a small, single-window
// desktop utility like this one.
let swiftSettings: [SwiftSetting] = [.swiftLanguageMode(.v5)]

let package = Package(
    name: "NotchPrompter",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(
            name: "NotchPrompterCore",
            path: "Sources/NotchPrompterCore",
            swiftSettings: swiftSettings
        ),
        .executableTarget(
            name: "NotchPrompterApp",
            dependencies: ["NotchPrompterCore"],
            path: "Sources/NotchPrompterApp",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "NotchPrompterCoreTests",
            dependencies: ["NotchPrompterCore"],
            path: "Tests/NotchPrompterCoreTests",
            swiftSettings: swiftSettings
        )
    ]
)
