import Testing
@testable import MiCoder

@Suite("Activity 14 provider send readiness")
struct SendProviderReadinessLogicTests {
    @Test("Serve connectivity cannot approve an unrelated expired web route")
    func serveDoesNotMasqueradeAsWebReadiness() {
        let error = SendProviderReadinessLogic.connectionValidationError(
            serverConnected: true,
            selectedProviderID: "web:qwen",
            autoFreeReady: true,
            customProviders: [],
            localProviderIDs: [],
            webProviderIDs: ["qwen"],
            serverProviderIDs: ["serve:gpt"],
            webConnected: false
        )
        #expect(error?.contains("web provider") == true)
    }

    @Test("connected web route is ready without Serve")
    func connectedWebRouteDoesNotNeedServe() {
        #expect(SendProviderReadinessLogic.connectionValidationError(
            serverConnected: false,
            selectedProviderID: "web:qwen",
            autoFreeReady: true,
            customProviders: [],
            localProviderIDs: [],
            webProviderIDs: ["qwen"],
            serverProviderIDs: [],
            webConnected: true
        ) == nil)
    }

    @Test("effective web model satisfies model preflight when legacy selection is empty")
    func effectiveModelSatisfiesPreflight() {
        #expect(SendProviderReadinessLogic.modelValidationID(
            selectedModel: "",
            effectiveModel: "qwen-max"
        ) == "qwen-max")
        #expect(SendProviderReadinessLogic.modelValidationID(
            selectedModel: "local-model",
            effectiveModel: ""
        ) == "local-model")
    }
}
