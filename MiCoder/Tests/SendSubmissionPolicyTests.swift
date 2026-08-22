import Testing
import Foundation
@testable import MiCoder

/// Round 30 — live finding: FallbackRouter declared browserAutomation sends
/// "successful" right after one click(), without verifying that the vendor page
/// actually submitted. On a freshly-hydrated qwen.ai page the click lands before
/// React attaches the submit handler → nothing is sent, yet downstream flow
/// trusted the fake success (and the remote-chat gate later blocked honestly).
@Suite("Round 30 — send submission verification logic")
struct SendSubmissionPolicyTests {

    @Test("url gains a chat id → submitted")
    func urlGainMeansSubmitted() {
        #expect(SendSubmissionPolicy.submissionDetected(
            beforeURL: "https://chat.qwen.ai/",
            afterURL: "https://chat.qwen.ai/c/06ee9c0b-916e-4044-9e9f-424ca91f5646"))
        #expect(SendSubmissionPolicy.submissionDetected(
            beforeURL: "https://www.kimi.com/",
            afterURL: "https://www.kimi.com/chat/cv8xk9abcd"))
    }

    @Test("unchanged url is never treated as submitted")
    func unchangedURLNotSubmitted() {
        #expect(!SendSubmissionPolicy.submissionDetected(
            beforeURL: "https://chat.qwen.ai/",
            afterURL: "https://chat.qwen.ai/"))
    }

    @Test("changed url without a chat id is not submission proof")
    func changedURLWithoutChatIDNotSubmitted() {
        #expect(!SendSubmissionPolicy.submissionDetected(
            beforeURL: "https://chat.qwen.ai/",
            afterURL: "https://chat.qwen.ai/?login=1"))
    }

    @Test("chat-id parser handles query, fragment and short junk segments")
    func urlHasChatIDParsing() {
        #expect(SendSubmissionPolicy.urlHasChatID("https://x.io/chat/abc12345-def"))
        #expect(SendSubmissionPolicy.urlHasChatID("https://x.io/c/abc12345?tab=2#top"))
        #expect(!SendSubmissionPolicy.urlHasChatID("https://x.io/chat/"))
        #expect(!SendSubmissionPolicy.urlHasChatID("https://x.io/c/short"))   // <8 chars junk
        #expect(!SendSubmissionPolicy.urlHasChatID("https://x.io/other/abc12345-def"))
        #expect(!SendSubmissionPolicy.urlHasChatID(""))
    }

    @Test("retry budget is small and bounded")
    func retryBudgetBounded() {
        #expect(SendSubmissionPolicy.maxClickAttempts >= 2)
        #expect(SendSubmissionPolicy.maxClickAttempts <= 5)
        #expect(SendSubmissionPolicy.verifyDelayMs >= 800)
        #expect(SendSubmissionPolicy.verifyDelayMs <= 3000)
    }
}
