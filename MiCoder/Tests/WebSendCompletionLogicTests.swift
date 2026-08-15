import Foundation
import Testing
@testable import MiCoder

@Suite("Web send completion journal")
struct WebSendCompletionLogicTests {
    @Test("visible final answer is the only successful completion event")
    func visibleFinalCompletes() {
        #expect(WebSendCompletionLogic.recordsCompletion(for: .final("done")))
    }

    @Test("failure and user-action events are not completed sends")
    func failureDoesNotComplete() {
        #expect(!WebSendCompletionLogic.recordsCompletion(for: .error("timeout")))
        #expect(!WebSendCompletionLogic.recordsCompletion(for: .loggedOut))
        #expect(!WebSendCompletionLogic.recordsCompletion(for: .captchaDetected(screenshotPNG: Data())))
        #expect(!WebSendCompletionLogic.recordsCompletion(for: .iterationLimitReached))
        #expect(!WebSendCompletionLogic.recordsCompletion(for: .modelInjectionFailed("not found")))
    }

    @Test("blank final answer is not a successful completion")
    func blankFinalDoesNotComplete() {
        #expect(!WebSendCompletionLogic.recordsCompletion(for: .final("  \n")))
    }
}
