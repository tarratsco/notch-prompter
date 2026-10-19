import AppKit
import Foundation

#if DEBUG
if let snapshotDirectory = ProcessInfo.processInfo.environment["NOTCH_PROMPTER_SNAPSHOT_DIR"] {
    let application = NSApplication.shared
    application.setActivationPolicy(.prohibited)
    do {
        try SnapshotRenderer.capture(to: URL(fileURLWithPath: snapshotDirectory, isDirectory: true))
    } catch {
        FileHandle.standardError.write(Data("Snapshot capture failed: \(error.localizedDescription)\n".utf8))
        exit(EXIT_FAILURE)
    }
    exit(EXIT_SUCCESS)
}
#endif

let application = NSApplication.shared
let applicationDelegate = AppDelegate()
application.delegate = applicationDelegate
application.run()
