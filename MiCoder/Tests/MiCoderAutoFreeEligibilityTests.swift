import Testing
@testable import MiCoder

@Suite("MODEL-19 Auto Free eligibility")
struct MiCoderAutoFreeEligibilityTests {
    @Test("trusted IDs and any live -free route are eligible, paid IDs are not")
    func freeSuffixEligibility() {
        #expect(MiCoderAutoFreeClient.isEligibleFreeModel("big-pickle"))
        #expect(MiCoderAutoFreeClient.isEligibleFreeModel("mimo-v2.5-free"))
        #expect(MiCoderAutoFreeClient.isEligibleFreeModel("muse-spark-1.3-contributor-free"))
        // Auto-discovery: a future -free route the app has never seen must
        // still be eligible so refresh picks it up without an app update.
        #expect(MiCoderAutoFreeClient.isEligibleFreeModel("untrusted-random-free"))
        // Paid models carry no -free suffix and stay unreachable anonymously.
        #expect(!MiCoderAutoFreeClient.isEligibleFreeModel("claude-opus-5"))
        #expect(!MiCoderAutoFreeClient.isEligibleFreeModel("gpt-5.5"))
        #expect(!MiCoderAutoFreeClient.isEligibleFreeModel("muse-spark-1.2"))
    }
}
