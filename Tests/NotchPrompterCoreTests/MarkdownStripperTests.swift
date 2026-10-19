import Testing
@testable import NotchPrompterCore

@Suite("Markdown stripping")
struct MarkdownStripperTests {
    @Test("Common formatting is removed without removing words")
    func stripsCommonFormattingWithoutRemovingWords() {
        let markdown = """
        # Opening

        Welcome to **Notch Prompter**. Read the [full guide](https://example.com).

        - Keep your eyes up
        - Speak *naturally*

        > You are ready.
        """

        #expect(
            MarkdownStripper.strip(markdown) == """
            Opening

            Welcome to Notch Prompter. Read the full guide.

            • Keep your eyes up
            • Speak naturally

            You are ready.
            """
        )
    }

    @Test("Front matter and fence markers are removed")
    func removesFrontMatterAndFenceMarkersButKeepsCodeContent() {
        let markdown = """
        ---
        title: Draft
        ---
        ## Demo
        ```swift
        let cue = "ready"
        ```
        """

        #expect(
            MarkdownStripper.strip(markdown) == """
            Demo
            let cue = "ready"
            """
        )
    }

    @Test("Literal intraword underscores are preserved")
    func preservesIntrawordUnderscores() {
        #expect(MarkdownStripper.strip("Read snake_case and user_id aloud.") == "Read snake_case and user_id aloud.")
    }

    @Test("Unmatched formatting markers are preserved")
    func preservesUnmatchedMarkers() {
        #expect(MarkdownStripper.strip("Keep **this and _that marker.") == "Keep **this and _that marker.")
    }

    @Test("Escaped delimiters become literal characters")
    func preservesEscapedDelimiters() {
        #expect(MarkdownStripper.strip(#"Say \*asterisks\* and \_underscores\_."#) == "Say *asterisks* and _underscores_.")
    }

    @Test("Inline code loses only its balanced code delimiter")
    func preservesInlineCodeContent() {
        #expect(MarkdownStripper.strip("Use `snake_case * literally` now.") == "Use snake_case * literally now.")
        #expect(MarkdownStripper.strip("Keep an unmatched `backtick.") == "Keep an unmatched `backtick.")
    }
}
