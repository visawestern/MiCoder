import Testing
import Foundation
@testable import MiCoder

@Suite("MiCoderAutoFreeProvider — anonymous OpenCode free catalog")
struct MiCoderAutoFreeProviderTests {

    @Test("provider uses the renamed built-in ID and Big Pickle default")
    func providerIdentityAndDefaultModel() {
        let provider = MiCoderAutoFreeProvider()

        #expect(MiCoderAutoFreeProvider.builtInID == "micoder-auto-free")
        #expect(provider.displayName == "MiCoder Auto Free")
        #expect(provider.selectedModel == "big-pickle")
        #expect(provider.isReady == false)
        #expect(MiCoderAutoFreeClient.defaultModelID == "big-pickle")
    }

    @Test("free allow-list contains Big Pickle and official alternatives only")
    func freeAllowList() {
        #expect(MiCoderAutoFreeClient.freeModelIDs.first == "big-pickle")
        #expect(MiCoderAutoFreeClient.freeModelIDs.contains("deepseek-v4-flash-free"))
        #expect(MiCoderAutoFreeClient.freeModelIDs.contains("mimo-v2.5-free"))
        #expect(!MiCoderAutoFreeClient.freeModelIDs.contains("claude-opus-5"))
        #expect(!MiCoderAutoFreeClient.freeModelIDs.contains("gpt-5.5"))
    }

    @Test("anonymous provider starts without a synthetic model")
    func noSyntheticModelBeforeDiscovery() {
        let provider = MiCoderAutoFreeProvider()

        #expect(provider.models.isEmpty)
        #expect(provider.isReady == false)
        #expect(provider.statusMessage.isEmpty)
        #expect(provider.isModelLocked == false)
    }

    @Test("model profiles expose honest free-route characteristics")
    func modelProfiles() {
        let profile = MiCoderAutoFreeClient.profile(for: "big-pickle")
        let model = MiCoderAutoFreeClient.Model(id: "big-pickle")

        #expect(profile.displayName == "Big Pickle")
        #expect(profile.capabilities.contains("Free"))
        #expect(profile.capabilities.contains("Anonymous"))
        #expect(model.effectiveDescription.contains("OpenCode"))
        #expect(model.contextDescription == "Not reported by live catalog")
    }

    @Test("system prompt is Codable provider state")
    func systemPromptRoundTrips() throws {
        var provider = MiCoderAutoFreeProvider()
        provider.systemPrompt = "You are a precise coding assistant."
        provider.isModelLocked = true

        let data = try JSONEncoder().encode(provider)
        let decoded = try JSONDecoder().decode(MiCoderAutoFreeProvider.self, from: data)

        #expect(decoded.systemPrompt == provider.systemPrompt)
        #expect(decoded.selectedModel == "big-pickle")
        #expect(decoded.isModelLocked)
    }
}

@Suite("MiCoderAutoFreeClient — anonymous OpenCode contract")
struct MiCoderAutoFreeClientContractTests {
    @Test("uses the official Zen base URL and OpenAI-compatible endpoint family")
    func endpointAndModelContract() {
        #expect(MiCoderAutoFreeClient.providerBaseURL.absoluteString == "https://opencode.ai/zen/v1")
        #expect(MiCoderAutoFreeProvider.defaultModelID == "big-pickle")
        #expect(MiCoderAutoFreeClient.maxConsecutiveFailures == 5)
    }

    @Test("rate limit and model errors switch immediately")
    func immediateFailoverErrors() {
        #expect(MiCoderAutoFreeClient.shouldSwitchImmediately(for: MiCoderAutoFreeError.rateLimited("429")))
        #expect(MiCoderAutoFreeClient.shouldSwitchImmediately(for: MiCoderAutoFreeError.modelUnavailable("big-pickle", "404")))
        #expect(!MiCoderAutoFreeClient.shouldSwitchImmediately(for: MiCoderAutoFreeError.apiError("HTTP 500")))
    }

    @Test("five consecutive generic failures are the switch threshold")
    func fiveFailureThreshold() {
        #expect(!MiCoderAutoFreeClient.shouldSwitch(for: MiCoderAutoFreeError.apiError("HTTP 500"), consecutiveFailures: 4))
        #expect(MiCoderAutoFreeClient.shouldSwitch(for: MiCoderAutoFreeError.apiError("HTTP 500"), consecutiveFailures: 5))
    }
}

@Suite("MiCoder Auto Free conversation context")
struct MiCoderAutoFreeConversationContextTests {
    @Test("multi-turn history preserves prior finished turns and drops in-flight placeholders")
    func preservesPriorConversationTurns() {
        let history = MiCoderAutoFreeHistoryLogic.history(from: [
            .init(role: "user", content: "Remember project name", isFinished: true),
            .init(role: "assistant", content: "MiCoder", isFinished: true),
            .init(role: "assistant", content: "in-flight placeholder", isFinished: false)
        ])
        #expect(history.map(\.role) == ["user", "assistant"])
        #expect(history.map(\.content) == ["Remember project name", "MiCoder"])
    }
}
