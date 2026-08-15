import Testing
@testable import MiCoder

@Suite("Provider response validation")
struct ProviderResponseValidationLogicTests {
    @Test("whitespace-only provider content is not a usable response")
    func whitespaceIsRejected() {
        #expect(!ProviderResponseValidationLogic.hasVisibleContent("  \n\t"))
    }

    @Test("meaningful provider content is accepted")
    func meaningfulContentIsAccepted() {
        #expect(ProviderResponseValidationLogic.hasVisibleContent("answer"))
    }
}
