import Testing
@testable import MiCoder

@Suite("MiCoder Auto Free failover notification reason")
struct MiCoderAutoFreeFailoverLogicTests {
    @Test("HTTP 429 and rate-limit text map to the red rate-limit reason")
    func rateLimitTextUsesRedReason() {
        #expect(MiCoderAutoFreeFailoverLogic.reason(errorDescription: "OpenCode failed (HTTP 429)", failureCount: 1) == "rate limit")
        #expect(MiCoderAutoFreeFailoverLogic.reason(errorDescription: "provider rate limit reached", failureCount: 1) == "rate limit")
    }

    @Test("model and generic failures preserve distinct switch reasons")
    func nonRateLimitReasonsRemainSpecific() {
        #expect(MiCoderAutoFreeFailoverLogic.reason(errorDescription: "model unavailable", failureCount: 1) == "model unavailable")
        #expect(MiCoderAutoFreeFailoverLogic.reason(errorDescription: "HTTP 500", failureCount: 3) == "3 consecutive failures")
    }
}
