import Foundation

public enum MarkdownStripper {
    /// Converts common Markdown constructs into calm, readable teleprompter text.
    /// It intentionally preserves wording and line breaks rather than attempting
    /// to implement the entire Markdown specification.
    public static func strip(_ source: String) -> String {
        var lines = source.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")

        if lines.first?.trimmingCharacters(in: .whitespaces) == "---",
           let end = lines.dropFirst().firstIndex(where: {
               $0.trimmingCharacters(in: .whitespaces) == "---"
           }) {
            lines.removeSubrange(lines.startIndex...end)
        }

        var inFence = false
        var output: [String] = []

        for originalLine in lines {
            let trimmed = originalLine.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inFence.toggle()
                continue
            }

            var line = originalLine
            if !inFence {
                line = line.replacingOccurrences(
                    of: #"^\s{0,3}#{1,6}\s+"#,
                    with: "",
                    options: .regularExpression
                )
                line = line.replacingOccurrences(
                    of: #"^\s{0,3}>\s?"#,
                    with: "",
                    options: .regularExpression
                )
                line = line.replacingOccurrences(
                    of: #"^\s*(?:[-+*]|\d+[.)])\s+"#,
                    with: "• ",
                    options: .regularExpression
                )
                line = line.replacingOccurrences(
                    of: #"!\[([^\]]*)\]\([^)]+\)"#,
                    with: "$1",
                    options: .regularExpression
                )
                line = line.replacingOccurrences(
                    of: #"\[([^\]]+)\]\([^)]+\)"#,
                    with: "$1",
                    options: .regularExpression
                )
                line = line.replacingOccurrences(
                    of: #"<(?:https?://|mailto:)[^>]+>"#,
                    with: "",
                    options: .regularExpression
                )
                line = line.replacingOccurrences(
                    of: #"</?[A-Za-z][^>]*>"#,
                    with: "",
                    options: .regularExpression
                )
                if line.range(
                    of: #"^\s*(?:-{3,}|\*{3,}|_{3,})\s*$"#,
                    options: .regularExpression
                ) != nil {
                    line = ""
                } else {
                    line = stripInlineDelimiters(in: line)
                }
            }
            output.append(line)
        }

        return output
            .joined(separator: "\n")
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stripInlineDelimiters(in source: String) -> String {
        var protectedValues: [String] = []
        var line = protectEscapedCharacters(in: source, values: &protectedValues)
        line = protectInlineCode(in: line, values: &protectedValues)

        let balancedPatterns = [
            #"(?<![\p{L}\p{N}_])\*\*(?=\S)([^\n]*?\S)\*\*(?!\*)"#,
            #"(?<![\p{L}\p{N}_])__(?=\S)([^\n]*?\S)__(?![\p{L}\p{N}_])"#,
            #"(?<!~)~~(?=\S)([^\n]*?\S)~~(?!~)"#,
            #"(?<![\p{L}\p{N}_*])\*(?=\S)([^\n]*?\S)\*(?!\*)"#,
            #"(?<![\p{L}\p{N}_])_(?=\S)([^\n]*?\S)_(?![\p{L}\p{N}_])"#
        ]
        for pattern in balancedPatterns {
            line = line.replacingOccurrences(
                of: pattern,
                with: "$1",
                options: .regularExpression
            )
        }

        for (index, value) in protectedValues.enumerated() {
            line = line.replacingOccurrences(of: placeholder(index), with: value)
        }
        return line
    }

    private static func protectEscapedCharacters(in source: String, values: inout [String]) -> String {
        let escapable = CharacterSet(charactersIn: "\\`*_{}[]()#+-.!>")
        var result = ""
        var index = source.startIndex
        while index < source.endIndex {
            let next = source.index(after: index)
            if source[index] == "\\", next < source.endIndex {
                let character = source[next]
                if character.unicodeScalars.allSatisfy({ escapable.contains($0) }) {
                    result += store(String(character), in: &values)
                    index = source.index(after: next)
                    continue
                }
            }
            result.append(source[index])
            index = next
        }
        return result
    }

    private static func protectInlineCode(in source: String, values: inout [String]) -> String {
        var result = ""
        var index = source.startIndex
        while index < source.endIndex {
            guard source[index] == "`" else {
                result.append(source[index])
                index = source.index(after: index)
                continue
            }

            var openingEnd = index
            while openingEnd < source.endIndex, source[openingEnd] == "`" {
                openingEnd = source.index(after: openingEnd)
            }
            let delimiter = String(source[index..<openingEnd])
            guard let closingRange = source.range(of: delimiter, range: openingEnd..<source.endIndex) else {
                result.append(contentsOf: delimiter)
                index = openingEnd
                continue
            }

            result += store(String(source[openingEnd..<closingRange.lowerBound]), in: &values)
            index = closingRange.upperBound
        }
        return result
    }

    private static func store(_ value: String, in values: inout [String]) -> String {
        let token = placeholder(values.count)
        values.append(value)
        return token
    }

    private static func placeholder(_ index: Int) -> String {
        "\u{E000}\(index)\u{E001}"
    }
}
