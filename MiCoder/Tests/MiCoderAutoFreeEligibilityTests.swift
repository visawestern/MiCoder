import Testing
@testable import MiCoder

@Suite("MODEL-19 Auto Free eligibility")
struct MiCoderAutoFreeEligibilityTests {
    @Test("only trusted temporary free IDs are eligible")
    func rejectsUntrustedFreeSuffix() {
        #expect(!MiCoderAutoFreeClient.isEligibleFreeModel("untrusted-random-free"))
        #expect(MiCoderAutoFreeClient.isEligibleFreeModel("big-pickle"))
        #expect(MiCoderAutoFreeClient.isEligibleFreeModel("mimo-v2.5-free"))
    }
}
