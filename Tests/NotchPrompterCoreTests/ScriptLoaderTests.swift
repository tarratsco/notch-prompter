import Foundation
import Testing
@testable import NotchPrompterCore

@Suite("Script loading")
struct ScriptLoaderTests {
    @Test("Plain text remains unchanged")
    func loadsText() throws {
        let url = try fixture(named: "script.txt", data: Data("Line one\nLine two".utf8))
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(try ScriptLoader.load(from: url) == "Line one\nLine two")
    }

    @Test("Markdown is converted to readable text")
    func loadsMarkdown() throws {
        let url = try fixture(named: "script.md", data: Data("# Cue\nRead **now**.".utf8))
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(try ScriptLoader.load(from: url) == "Cue\nRead now.")
    }

    @Test("Unsupported extensions are rejected before reading")
    func rejectsUnsupportedType() throws {
        let url = fixtureDirectory.appendingPathComponent("script.rtf")

        #expect(throws: ScriptLoadError.unsupportedFileType("rtf")) {
            try ScriptLoader.load(from: url)
        }
    }

    @Test("Invalid UTF-8 is rejected")
    func rejectsInvalidUTF8() throws {
        let url = try fixture(named: "invalid.txt", data: Data([0xFF, 0xFE, 0xFD]))
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: ScriptLoadError.invalidUTF8) {
            try ScriptLoader.load(from: url)
        }
    }

    private var fixtureDirectory: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/script-loader-tests", isDirectory: true)
    }

    private func fixture(named name: String, data: Data) throws -> URL {
        try FileManager.default.createDirectory(at: fixtureDirectory, withIntermediateDirectories: true)
        let url = fixtureDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }
}
