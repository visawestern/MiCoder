import Foundation
import Testing
@testable import MiCoder

@Suite("WEB-LOGIN-12: detection mode honesty")
struct WebDetectionStatusLogicTests {
    @Test("empty status names the built-in MiCoder detector")
    func emptyStatus() {
        #expect(WebDetectionStatusLogic.statusText(modelCount: 0) == "MiCoder will detect models after login")
        #expect(!WebDetectionStatusLogic.statusText(modelCount: 0).contains("Auto Free"))
    }

    @Test("detected status names the built-in detector")
    func detectedStatus() {
        #expect(WebDetectionStatusLogic.statusText(modelCount: 4) == "MiCoder detected 4 models")
        #expect(!WebDetectionStatusLogic.statusText(modelCount: 4).contains("Auto Free"))
    }
}
