import Testing
import Foundation
@testable import MiCoder

@Suite("Local provider config + unified providers logic (plan Раздел 1)")
struct LocalProviderConfigTests {

    @Test func kindDefaults() {
        #expect(LocalProviderKind.ollama.defaultPort == 11434)
        #expect(LocalProviderKind.mimoCLI.defaultPort == 4096)
        #expect(LocalProviderKind.ollama.healthPath == "/api/tags")
        #expect(LocalProviderKind.mimoCLI.healthPath == "/global/health")
        #expect(!LocalProviderKind.ollama.supportsCLIMode)
        #expect(LocalProviderKind.mimoCLI.supportsCLIMode)
    }

    @Test func configUsesKindDefaults() {
        let ollama = LocalProviderConfig(kind: .ollama)
        #expect(ollama.mode == .serve)           // ollama has no CLI mode
        #expect(ollama.port == 11434)
        #expect(ollama.serveBaseURL == "http://127.0.0.1:11434")
        #expect(ollama.healthURL == "http://127.0.0.1:11434/api/tags")

        let mimo = LocalProviderConfig(kind: .mimoCLI)
        #expect(mimo.mode == .cli)               // mimoCLI defaults to CLI
        #expect(mimo.executablePath.contains("mimo"))
    }

    @Test func mimoServeModeGetsNeutralNameNoBranding() {
        let serve = LocalProviderConfig(kind: .mimoCLI, mode: .serve)
        #expect(serve.displayName == "MiMo (Local Serve)")
        #expect(!serve.displayName.contains("MiMo Serve"))
        let cli = LocalProviderConfig(kind: .mimoCLI, mode: .cli)
        #expect(cli.displayName == "MiMo (Local CLI)")
    }

    @Test func persistenceRoundTrip() {
        let defaults = UserDefaults(suiteName: "test-local-providers-\(UUID().uuidString)")!
        let providers = [LocalProviderConfig(kind: .ollama), LocalProviderConfig(kind: .mimoCLI, mode: .serve)]
        LocalProviderLogic.save(providers, defaults: defaults)
        let loaded = LocalProviderLogic.load(defaults: defaults)
        #expect(loaded.count == 2)
        #expect(loaded.contains { $0.kind == .ollama })
        #expect(loaded.contains { $0.kind == .mimoCLI })
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

    @Test func neutralizeServeBrandingRemovesMiMoServe() {
        #expect(LocalProviderLogic.neutralizeServeBranding("MiMo Serve") == "Local Agent")
        #expect(LocalProviderLogic.neutralizeServeBranding("Connected to MiMoServe") == "Connected to Local Agent")
        #expect(LocalProviderLogic.neutralizeServeBranding("OpenAI") == "OpenAI")
    }

    @Test func configRoundTripsThroughCodable() throws {
        let cfg = LocalProviderConfig(kind: .openCode, mode: .cli, port: 5000, autoStart: true)
        let data = try JSONEncoder().encode(cfg)
        let decoded = try JSONDecoder().decode(LocalProviderConfig.self, from: data)
        #expect(decoded == cfg)
    }
}
