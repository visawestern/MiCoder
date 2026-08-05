import Testing
import Foundation
@testable import MiCoder

@Suite("Local provider config + unified providers logic (plan Раздел 1)")
struct LocalProviderConfigTests {

    @Test func kindDefaults() {
        #expect(LocalProviderKind.ollama.defaultPort == 11434)
        #expect(LocalProviderKind.localAgent.defaultPort == 4096)
        #expect(LocalProviderKind.ollama.healthPath == "/api/tags")
        #expect(LocalProviderKind.localAgent.healthPath == "/global/health")
    }

    @Test func configUsesKindDefaults() {
        // Every local provider is reached over HTTP only — no CLI, no exec path.
        let ollama = LocalProviderConfig(kind: .ollama)
        #expect(ollama.port == 11434)
        #expect(ollama.serveBaseURL == "http://127.0.0.1:11434")
        #expect(ollama.healthURL == "http://127.0.0.1:11434/api/tags")

        let agent = LocalProviderConfig(kind: .localAgent)
        #expect(agent.port == 4096)
        #expect(agent.healthURL == "http://127.0.0.1:4096/global/health")
    }

    @Test func localAgentUsesNeutralNameNoBranding() {
        let agent = LocalProviderConfig(kind: .localAgent)
        #expect(agent.displayName == "Local Agent")
        #expect(!agent.displayName.contains("MiMo"))
    }

    @Test func persistenceRoundTrip() {
        let defaults = UserDefaults(suiteName: "test-local-providers-\(UUID().uuidString)")!
        let providers = [LocalProviderConfig(kind: .ollama), LocalProviderConfig(kind: .localAgent)]
        LocalProviderLogic.save(providers, defaults: defaults)
        let loaded = LocalProviderLogic.load(defaults: defaults)
        #expect(loaded.count == 2)
        #expect(loaded.contains { $0.kind == .ollama })
        #expect(loaded.contains { $0.kind == .localAgent })
    }

    @Test func providerOptionsIncludeOnlyEnabledLocals() {
        let providers = [
            LocalProviderConfig(kind: .ollama, isEnabled: true),
            LocalProviderConfig(kind: .openCode, isEnabled: false)
        ]
        let options = LocalProviderLogic.providerOptions(from: providers)
        #expect(options.count == 1)
        #expect(options.first?.name == "Ollama")
        #expect(options.first?.isCustom == true)
    }

    @Test func configRoundTripsThroughCodable() throws {
        let cfg = LocalProviderConfig(kind: .openCode, port: 5000)
        let data = try JSONEncoder().encode(cfg)
        let decoded = try JSONDecoder().decode(LocalProviderConfig.self, from: data)
        #expect(decoded == cfg)
    }
}
