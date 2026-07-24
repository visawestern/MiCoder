import Testing
import Foundation
@testable import MiCoder

@Suite("Provider auto-detector (plan Раздел 9)")
struct ProviderAutoDetectorTests {

    /// Scriptable probe: maps URL substring -> (status, body). First matching
    /// entry wins; unknown URLs return nil (connection failure).
    private struct ScriptedProbe: ProviderProbe {
        let routes: [(String, Int, Data?)]
        func get(url: String, headers: [String: String]) async -> (Int, Data)? {
            for (path, status, body) in routes where url.contains(path) {
                return (status, body ?? Data())
            }
            return nil
        }
    }

    private func data(_ json: String) -> Data { Data(json.utf8) }

    @Test func detectsOllamaFromTags() async {
        let probe = ScriptedProbe(routes: [
            ("/api/tags", 200, data(#"{"models":[{"name":"llama3"},{"name":"qwen"}]}"#))
        ])
        let info = await ProviderAutoDetector.detect(host: "localhost", port: 11434, probe: probe)
        #expect(info?.kind == .ollama)
        #expect(info?.models == ["llama3", "qwen"])
        #expect(info?.baseURL == "http://localhost:11434")
    }

    @Test func detectsMimoCLIFromGlobalHealth() async {
        let probe = ScriptedProbe(routes: [
            ("/global/health", 200, nil),
            ("/global/models", 200, data(#"{"data":[{"id":"gpt-4o"}]}"#))
        ])
        let info = await ProviderAutoDetector.detect(host: "127.0.0.1", port: 4096, probe: probe)
        #expect(info?.kind == .mimoCLI)
        #expect(info?.models == ["gpt-4o"])
    }

    @Test func detectsACPFromAcpModels() async {
        let probe = ScriptedProbe(routes: [
            ("/acp/v1/models", 200, data(#"{"data":[{"id":"model-a"}]}"#))
        ])
        let info = await ProviderAutoDetector.detect(host: "localhost", port: 8080, probe: probe)
        #expect(info?.kind == .acp)
    }

    @Test func fallsBackToGenericOpenAICompatible() async {
        // Explicit 404 for /acp/v1/models so the ACP probe step fails before the
        // generic /v1/models fallback (ScriptedProbe matches by url substring).
        let probe = ScriptedProbe(routes: [
            ("/acp/v1/models", 404, Data()),
            ("/v1/models", 200, data(#"{"data":[{"id":"llama"}]}"#))
        ])
        let info = await ProviderAutoDetector.detect(host: "localhost", port: 1234, probe: probe)
        #expect(info?.kind == .openAICompatible)
        #expect(info?.models == ["llama"])
    }

    @Test func returnsNilWhenNothingResponds() async {
        let probe = ScriptedProbe(routes: [])
        let info = await ProviderAutoDetector.detect(host: "localhost", port: 9999, probe: probe)
        #expect(info == nil)
    }

    @Test func ollamaProbedBeforeGenericSoItIsNotMisclassified() async {
        // Both /api/tags and /v1/models respond — Ollama must win.
        let probe = ScriptedProbe(routes: [
            ("/api/tags", 200, data(#"{"models":[{"name":"llama3"}]}"#)),
            ("/v1/models", 200, data(#"{"data":[{"id":"other"}]}"#))
        ])
        let info = await ProviderAutoDetector.detect(host: "localhost", port: 11434, probe: probe)
        #expect(info?.kind == .ollama)
        #expect(info?.models == ["llama3"])
    }

    @Test func parseOllamaTagsReturnsNilForEmpty() {
        #expect(ProviderAutoDetector.parseOllamaTags(data(#"{"models":[]}"#)) == nil)
        #expect(ProviderAutoDetector.parseOllamaTags(data("not json")) == nil)
    }

    @Test func parseOpenAIModelsExtractsIds() {
        let ids = ProviderAutoDetector.parseOpenAIModels(data(#"{"data":[{"id":"a"},{"id":"b"}]}"#))
        #expect(ids == ["a", "b"])
        #expect(ProviderAutoDetector.parseOpenAIModels(data(#"{"data":[]}"#)) == nil)
    }

    @Test func isLikelyLocalRecognizesLocalAddresses() {
        #expect(ProviderAutoDetector.isLikelyLocal("localhost"))
        #expect(ProviderAutoDetector.isLikelyLocal("127.0.0.1"))
        #expect(ProviderAutoDetector.isLikelyLocal("192.168.1.10"))
        #expect(ProviderAutoDetector.isLikelyLocal("10.0.0.5"))
        #expect(ProviderAutoDetector.isLikelyLocal("172.16.0.1"))
        #expect(ProviderAutoDetector.isLikelyLocal("myhost.local"))
        #expect(!ProviderAutoDetector.isLikelyLocal("example.com"))
        #expect(!ProviderAutoDetector.isLikelyLocal("8.8.8.8"))
    }
}
