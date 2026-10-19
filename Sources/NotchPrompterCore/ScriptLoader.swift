import Foundation

public enum ScriptLoadError: LocalizedError, Equatable {
    case unsupportedFileType(String)
    case unreadableFile
    case invalidUTF8

    public var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let fileExtension):
            return "“.\(fileExtension)” files are not supported. Choose a UTF-8 .txt or .md file."
        case .unreadableFile:
            return "The file could not be read. Check its permissions and try again."
        case .invalidUTF8:
            return "The file is not valid UTF-8 text. Save it as UTF-8 and try again."
        }
    }
}

public enum ScriptLoader {
    public static func load(from url: URL) throws -> String {
        let fileExtension = url.pathExtension.lowercased()
        guard ["txt", "md", "markdown"].contains(fileExtension) else {
            throw ScriptLoadError.unsupportedFileType(fileExtension.isEmpty ? "unknown" : fileExtension)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ScriptLoadError.unreadableFile
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw ScriptLoadError.invalidUTF8
        }
        return fileExtension == "txt" ? text : MarkdownStripper.strip(text)
    }
}
