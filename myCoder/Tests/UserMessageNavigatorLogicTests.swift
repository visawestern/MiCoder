import Foundation
import Testing
@testable import myCoder

struct UserMessageNavigatorLogicTests {

    @Test("Only user messages with content are navigable")
    func filtersToUserMessages() {
        let messages = [
            Message(role: .assistant, content: "answer"),
            Message(role: .user, content: "first question"),
            Message(role: .user, content: "   "),
            Message(role: .user, content: "second question")
        ]

        let navigable = UserMessageNavigatorLogic.userMessages(messages)

        #expect(navigable.map(\.content) == ["first question", "second question"])
    }

    @Test("Attachment-only user messages stay navigable")
    func keepsAttachmentOnlyMessages() {
        let message = Message(
            role: .user,
            content: "",
            files: [FileInfo(name: "Notes.swift", type: .swift)]
        )

        let navigable = UserMessageNavigatorLogic.userMessages([message])

        #expect(navigable.count == 1)
        #expect(UserMessageNavigatorLogic.preview(for: message) == "Notes.swift")
    }

    @Test("Preview collapses newlines and repeated whitespace")
    func normalizesPreview() {
        let message = Message(role: .user, content: "  First line\n\nSecond   line  ")

        #expect(UserMessageNavigatorLogic.preview(for: message) == "First line Second line")
    }

    @Test("Preview truncates to one hundred characters")
    func truncatesPreview() {
        let message = Message(role: .user, content: String(repeating: "a", count: 140))

        let preview = UserMessageNavigatorLogic.preview(for: message)

        #expect(preview == String(repeating: "a", count: 100) + "…")
        #expect(preview.count == 101)
    }

    @Test("Preview exactly at the limit is not truncated")
    func keepsExactLimit() {
        let message = Message(role: .user, content: String(repeating: "b", count: 100))

        #expect(UserMessageNavigatorLogic.preview(for: message) == String(repeating: "b", count: 100))
    }

    @Test("Preview trims whitespace exposed by truncation")
    func trimsTrailingWhitespaceAfterTruncation() {
        let message = Message(role: .user, content: String(repeating: "a", count: 99) + "   tail")

        let preview = UserMessageNavigatorLogic.preview(for: message)

        #expect(preview == String(repeating: "a", count: 99) + "…")
    }

    @Test("Button title uses a one-based index")
    func buttonTitle() {
        #expect(UserMessageNavigatorLogic.buttonTitle(index: 0) == "1")
        #expect(UserMessageNavigatorLogic.buttonTitle(index: 11) == "12")
    }
}
