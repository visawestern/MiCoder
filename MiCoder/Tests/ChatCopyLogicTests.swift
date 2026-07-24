import Testing
@testable import MiCoder

@Suite("Chat copy")
struct ChatCopyLogicTests {

    @Test("Builds transcript from user and assistant messages")
    func buildsTranscript() {
        let messages = [
            Message(role: .user, content: "Hello"),
            Message(role: .assistant, content: "Hi there", parts: [.text("Hi there")])
        ]

        let transcript = ChatCopyLogic.transcript(from: messages)

        #expect(transcript.contains("User"))
        #expect(transcript.contains("Hello"))
        #expect(transcript.contains("Assistant"))
        #expect(transcript.contains("Hi there"))
    }

    @Test("Skips empty messages")
    func skipsEmpty() {
        let messages = [
            Message(role: .user, content: "Only this"),
            Message(role: .assistant, content: "")
        ]

        let transcript = ChatCopyLogic.transcript(from: messages)

        #expect(transcript.contains("Only this"))
        #expect(transcript.contains("Assistant") == false)
    }
}
