import Testing
@testable import MiCoder

@Suite("MiCoder Auto Free conversation context")
struct MiCoderAutoFreeHistoryLogicTests {
    @Test("multi-turn history preserves prior finished turns and drops in-flight placeholders")
    func preservesPriorConversationTurns() {
        let history = MiCoderAutoFreeHistoryLogic.history(from: [
            .init(role: "user", content: "Remember project name", isFinished: true),
            .init(role: "assistant", content: "MiCoder", isFinished: true),
            .init(role: "assistant", content: "in-flight placeholder", isFinished: false)
        ])
        #expect(history.map(\.role) == ["user", "assistant"])
        #expect(history.map(\.content) == ["Remember project name", "MiCoder"])
    }

    @Test("history limit keeps only the newest finished turns and zero disables history")
    func historyLimitEdges() {
        let turns = (1...3).map {
            MiCoderAutoFreeHistoryLogic.Turn(role: "user", content: "turn \($0)", isFinished: true)
        }
        #expect(MiCoderAutoFreeHistoryLogic.history(from: turns, maxTurns: 2).map(\.content) == ["turn 2", "turn 3"])
        #expect(MiCoderAutoFreeHistoryLogic.history(from: turns, maxTurns: 0).isEmpty)
    }

    @Test("unfinished prior user turns are excluded just like unfinished assistant placeholders")
    func dropsUnfinishedUserTurns() {
        let history = MiCoderAutoFreeHistoryLogic.history(from: [
            .init(role: "user", content: "submitted", isFinished: true),
            .init(role: "assistant", content: "reply", isFinished: true),
            .init(role: "user", content: "still streaming", isFinished: false)
        ])
        #expect(history.map(\.content) == ["submitted", "reply"])
    }

    @Test("negative history limits fail closed instead of disabling the cap")
    func negativeLimitDisablesHistory() {
        let turns = [
            MiCoderAutoFreeHistoryLogic.Turn(role: "user", content: "old", isFinished: true),
            MiCoderAutoFreeHistoryLogic.Turn(role: "assistant", content: "reply", isFinished: true)
        ]
        #expect(MiCoderAutoFreeHistoryLogic.history(from: turns, maxTurns: -1).isEmpty)
    }
}
