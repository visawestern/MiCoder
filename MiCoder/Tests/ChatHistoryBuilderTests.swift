import Testing
@testable import MiCoder

@Suite("Chat history builder (audit P1 — stateless chat fix)")
struct ChatHistoryBuilderTests {

    private func t(_ role: String, _ content: String, finished: Bool = true) -> ChatHistoryBuilder.Turn {
        ChatHistoryBuilder.Turn(role: role, content: content, isFinished: finished)
    }

    @Test func keepsFinishedUserAndAssistant() {
        let h = ChatHistoryBuilder.history(from: [
            t("user", "q1"), t("assistant", "a1"), t("user", "q2")
        ])
        #expect(h == [
            DirectChatMessage(role: "user", content: "q1"),
            DirectChatMessage(role: "assistant", content: "a1"),
            DirectChatMessage(role: "user", content: "q2"),
        ])
    }

    @Test func dropsEmptyStreamingAssistantPlaceholder() {
        // The just-appended empty assistant message (isFinished false, empty) must
        // NOT enter history — this is the exact placeholder created before a turn.
        let h = ChatHistoryBuilder.history(from: [
            t("user", "q"), t("assistant", "", finished: false)
        ])
        #expect(h == [DirectChatMessage(role: "user", content: "q")])
    }

    @Test func dropsUnfinishedAssistantWithPartialText() {
        // A mid-stream assistant turn (not finished) is excluded to avoid feeding
        // partial output back as history.
        let h = ChatHistoryBuilder.history(from: [
            t("user", "q"), t("assistant", "partial...", finished: false)
        ])
        #expect(h == [DirectChatMessage(role: "user", content: "q")])
    }

    @Test func dropsSystemRole() {
        let h = ChatHistoryBuilder.history(from: [t("system", "sys"), t("user", "q")])
        #expect(h == [DirectChatMessage(role: "user", content: "q")])
    }

    @Test func dropsWhitespaceOnlyContent() {
        let h = ChatHistoryBuilder.history(from: [t("user", "   \n "), t("user", "real")])
        #expect(h == [DirectChatMessage(role: "user", content: "real")])
    }

    @Test func capsToMaxTurns() {
        let many = (0..<50).map { t("user", "m\($0)") }
        let h = ChatHistoryBuilder.history(from: many, maxTurns: 10)
        #expect(h.count == 10)
        #expect(h.first?.content == "m40")   // most recent kept
        #expect(h.last?.content == "m49")
    }

    @Test func messagesPrependsSystemAndAppendsUser() {
        let msgs = ChatHistoryBuilder.messages(
            systemPrompt: "be brief",
            priorTurns: [t("user", "q1"), t("assistant", "a1")],
            userText: "q2"
        )
        #expect(msgs.first == DirectChatMessage(role: "system", content: "be brief"))
        #expect(msgs.last == DirectChatMessage(role: "user", content: "q2"))
        #expect(msgs.count == 4)   // system + 2 history + new user
    }

    @Test func messagesWithoutSystemOmitsIt() {
        let msgs = ChatHistoryBuilder.messages(systemPrompt: nil, priorTurns: [], userText: "hi")
        #expect(msgs == [DirectChatMessage(role: "user", content: "hi")])
    }

    @Test func emptyHistoryProducesJustUser() {
        #expect(ChatHistoryBuilder.history(from: []).isEmpty)
    }
}
