import Testing
import Foundation
@testable import MiCoder

@Suite("MiCoderAutoFreeProvider — OpenCode Zen Big Pickle contract")
struct MiCoderAutoFreeProviderTests {

    @Test("provider uses the renamed built-in ID and Big Pickle default")
    func providerIdentityAndDefaultModel() {
        let provider = MiCoderAutoFreeProvider()

        #expect(MiCoderAutoFreeProvider.builtInID == "micoder-auto-free")
        #expect(provider.displayName == "MiCoder Auto Free")
        #expect(provider.selectedModel == "big-pickle")
        #expect(MiCoderAutoFreeClient.defaultModelID == "big-pickle")
    }

    @Test("empty key returns no models and never invents a fallback")
    func emptyKeyHasNoSyntheticFallback() async {
        var provider = MiCoderAutoFreeProvider()
        provider.models = [MiCoderAutoFreeClient.Model(id: "stale-model", isFree: false)]
        provider.apiKey = ""

        let result = await provider.refreshModels()

        #expect(result.isEmpty)
        #expect(!result.contains { $0.id == "big-pickle" })
        #expect(await provider.validateKey() == false)
    }

    @Test("refreshModels returns an empty result when key is absent")
    func refreshModelsClearsStaleResult() async {
        var provider = MiCoderAutoFreeProvider()
        provider.models = [MiCoderAutoFreeClient.Model(id: "old-model", isFree: false)]

        let result = await provider.refreshModels()

        #expect(result.isEmpty)
    }

    @Test("non-empty key is not treated as anonymous access")
    func nonEmptyKeyUsesAuthenticatedValidationPath() async {
        var provider = MiCoderAutoFreeProvider()
        provider.apiKey = "test-opencode-zen-key"

        // A malformed test key must fail validation; the client must not
        // synthesize Big Pickle or silently downgrade to anonymous access.
        #expect(await provider.validateKey() == false)
    }

    @Test("system prompt is Codable provider state")
    func systemPromptRoundTrips() throws {
        var provider = MiCoderAutoFreeProvider()
        provider.systemPrompt = "You are a precise coding assistant."

        let data = try JSONEncoder().encode(provider)
        let decoded = try JSONDecoder().decode(MiCoderAutoFreeProvider.self, from: data)

        #expect(decoded.systemPrompt == provider.systemPrompt)
        #expect(decoded.selectedModel == "big-pickle")
    }
}

@Suite("MiCoderAutoFreeClient — OpenCode Zen endpoint contract")
struct MiCoderAutoFreeClientContractTests {
    @Test("uses the official Zen base URL")
    func endpointAndModelContract() {
        #expect(MiCoderAutoFreeClient.providerBaseURL.absoluteString == "https://opencode.ai/zen/v1")
        #expect(MiCoderAutoFreeClient.defaultModelID == "big-pickle")
    }
}
