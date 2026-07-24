import Testing
@testable import MiCoder

@Suite("Message content sanitizer")
struct MessageContentSanitizerLogicTests {

    @Test("Strips system-reminder blocks from displayed text")
    func stripsSystemReminder() {
        let raw = """
        составь план улучшения

        <system-reminder>
        Plan mode is active. Do not execute yet.
        </system-reminder>
        """
        let cleaned = MessageContentSanitizerLogic.sanitizedForDisplay(raw)
        #expect(cleaned.contains("составь план улучшения"))
        #expect(cleaned.contains("system-reminder") == false)
        #expect(cleaned.contains("Plan mode is active") == false)
    }

    @Test("Returns nil for empty text after sanitization")
    func emptyAfterSanitization() {
        #expect(
            MessageContentSanitizerLogic.sanitizedTextPart(
                "<system-reminder>only reminder</system-reminder>"
            ) == nil
        )
    }

    @Test("Falls back to formatted content when parts contain only service text")
    func formattedFallbackAfterEmptyParts() {
        let texts = MessageContentSanitizerLogic.displayTexts(
            partTexts: ["<system-reminder>only reminder</system-reminder>"],
            fallback: "✨ **Готово**"
        )

        #expect(texts == ["✨ **Готово**"])
    }

    @Test("Does not duplicate fallback when a visible text part exists")
    func visiblePartWinsOverFallback() {
        let texts = MessageContentSanitizerLogic.displayTexts(
            partTexts: ["✅ **Собрано**"],
            fallback: "duplicate"
        )

        #expect(texts == ["✅ **Собрано**"])
    }
}

@Suite("OpenCode tool status")
struct OpenCodeToolStatusLogicTests {

    @Test("Completed status with output is not pending")
    func completedWithOutput() {
        #expect(
            OpenCodeToolStatusLogic.isPending(status: "completed", output: "file contents")
            == false
        )
    }

    @Test("Running status stays pending without output")
    func runningPending() {
        #expect(OpenCodeToolStatusLogic.isPending(status: "running", output: nil))
    }

    @Test("Empty status with output is completed")
    func emptyStatusWithOutput() {
        #expect(OpenCodeToolStatusLogic.isPending(status: nil, output: "done") == false)
    }

    @Test("Extracts structured output as JSON")
    func extractsStructuredOutput() {
        let output = OpenCodeToolStatusLogic.extractOutput(from: [
            "output": ["content": "hello"]
        ])
        #expect(output?.contains("hello") == true)
    }
}
