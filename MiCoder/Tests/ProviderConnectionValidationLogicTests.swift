import Foundation
import Testing
@testable import MiCoder

@Suite("PROV-08 provider connection validation")
struct ProviderConnectionValidationLogicTests {
    @Test("valid OpenAI-compatible model response is connected")
    func validModelResponse() {
        let body = Data(#"{"data":[{"id":"gpt-test"}]}"#.utf8)
        #expect(ProviderConnectionValidationLogic.isValidModelsResponse(statusCode: 200, body: body))
    }

    @Test("HTTP success with invalid body is not connected")
    func invalidBodyFails() {
        #expect(!ProviderConnectionValidationLogic.isValidModelsResponse(statusCode: 200, body: Data("<html>login</html>".utf8)))
    }

    @Test("empty model list is not connected")
    func emptyModelsFail() {
        let body = Data(#"{"data":[]}"#.utf8)
        #expect(!ProviderConnectionValidationLogic.isValidModelsResponse(statusCode: 200, body: body))
    }

    @Test("non-success HTTP status is not connected even with model JSON")
    func nonSuccessFails() {
        let body = Data(#"{"data":[{"id":"gpt-test"}]}"#.utf8)
        #expect(!ProviderConnectionValidationLogic.isValidModelsResponse(statusCode: 401, body: body))
    }
}
