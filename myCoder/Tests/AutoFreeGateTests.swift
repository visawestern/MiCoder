import Testing
import Foundation
@testable import myCoder

/// Upstream Zen free-tier gate (observed 2026-10-13, probed live):
/// anonymous + header variants all return 403 FreeTierError /
/// 400 MissingSessionID — "can only be used from within OpenCode".
/// Impersonating the official client is refused as a fix path;
/// the honest behavior is: detect once, stop the model carousel,
/// tell the user exactly what unlocks it (OpenCode client or Zen key).
@Suite("Auto Free tier-gate honesty (upstream 403 FreeTierError)")
struct AutoFreeGateTests {

    @Test func detectsGateSignatures() {
        #expect(MiCoderAutoFreeError.isFreeTierGate(
            statusCode: 403,
            body: #"{"type":"error","error":{"type":"FreeTierError","message":"OpenCode's free tier can only be used from within OpenCode."}}"#))
        #expect(MiCoderAutoFreeError.isFreeTierGate(
            statusCode: 400,
            body: #"{"type":"error","error":{"type":"MissingSessionID","message":"Error from provider (Console)"}}"#))
        #expect(!MiCoderAutoFreeError.isFreeTierGate(statusCode: 429, body: "rate limit"))
        #expect(!MiCoderAutoFreeError.isFreeTierGate(statusCode: 500, body: "boom"))
        #expect(!MiCoderAutoFreeError.isFreeTierGate(statusCode: 403, body: "forbidden"))
    }

    @Test func gateErrorMessageIsActionable() {
        let text = MiCoderAutoFreeError.freeTierBlocked("probe").localizedDescription
        #expect(text.contains("OpenCode"))
        #expect(text.contains("Zen") || text.contains("API key") || text.contains("key"))
    }

    @Test func gateHaltsFailoverInsteadOfCarousel() {
        let err = MiCoderAutoFreeError.freeTierBlocked("probe")
        #expect(MiCoderAutoFreeClient.shouldHaltFailover(for: err))
        #expect(!MiCoderAutoFreeClient.shouldSwitchImmediately(for: err))
        #expect(!MiCoderAutoFreeClient.shouldSwitch(for: err, consecutiveFailures: 99))
        #expect(MiCoderAutoFreeFailoverLogic.reason(
            errorDescription: "FreeTierError gate", failureCount: 3) == "free-tier gate")
    }

    @Test func bare403OnFreeChatMapsToGate() {
        // Live 2026-10-13: the streaming path validates before any SSE line
        // arrives, so the gate shows up as a bare 403 with an empty body.
        // On the anonymous free-chat operations the only observed 400/403
        // shapes are the gate itself.
        let err = MiCoderAutoFreeError.mapHttpError(statusCode: 403, body: "", operation: "Free model streaming")
        guard case .freeTierBlocked = err else {
            Issue.record("bare 403 on streaming must map to the gate, got \(err)")
            return
        }
        let err2 = MiCoderAutoFreeError.mapHttpError(statusCode: 403, body: "", operation: "Free model chat")
        guard case .freeTierBlocked = err2 else {
            Issue.record("bare 403 on chat must map to the gate, got \(err2)")
            return
        }
    }

    @Test func listPathKeepsBodyBasedMapping() {
        // The catalog operation keeps the old contract: no body sniffing.
        let err = MiCoderAutoFreeError.mapHttpError(statusCode: 403, body: "", operation: "OpenCode free model list")
        guard case .modelUnavailable = err else {
            Issue.record("list path must keep modelUnavailable, got \(err)")
            return
        }
    }
}
