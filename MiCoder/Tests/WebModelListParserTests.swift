import Testing
@testable import MiCoder

@Suite("Web model list parser (plan Раздел 13 п.4)")
struct WebModelListParserTests {

    @Test func parsesNewlineSeparatedModels() {
        let text = "k2\nk2-thinking\nk1.5"
        let models = WebModelListParser.parse(dropdownText: text, vendor: .kimi)
        #expect(models == ["k2", "k2-thinking", "k1.5"])
    }

    @Test func stripsSelectionMarkersAndDedupes() {
        let text = "✓ gpt-4o\ngpt-4o\ngpt-4.1"
        let models = WebModelListParser.parse(dropdownText: text, vendor: .chatgpt)
        #expect(models == ["gpt-4o", "gpt-4.1"])
    }

    @Test func dropsUINoiseEntries() {
        let text = "qwen-max\nUpgrade\nNew\nqwen2.5-coder\nSettings"
        let models = WebModelListParser.parse(dropdownText: text, vendor: .qwen)
        #expect(models == ["qwen-max", "qwen2.5-coder"])
    }

    @Test func normalizeRejectsChrome() {
        #expect(WebModelListParser.normalize("", vendor: .kimi) == nil)
        #expect(WebModelListParser.normalize("New", vendor: .kimi) == nil)
        #expect(WebModelListParser.normalize("✓ k2", vendor: .kimi) == "k2")
        #expect(WebModelListParser.normalize(String(repeating: "x", count: 80), vendor: .kimi) == nil)
    }

    @Test func updatedSetsDiscoveredModels() {
        let cfg = WebProviderConfig(vendor: .kimi)
        let updated = WebModelListParser.updated(cfg, withDropdownText: "k2\nk2-thinking")
        #expect(updated.discoveredModels == ["k2", "k2-thinking"])
        // And connectivity now returns the real models over defaults.
        #expect(WebProviderConnectivity.models(for: updated) == ["k2", "k2-thinking"])
    }

    @Test func updatedKeepsDefaultsWhenParseEmpty() {
        let cfg = WebProviderConfig(vendor: .kimi)
        let updated = WebModelListParser.updated(cfg, withDropdownText: "New\nUpgrade")
        #expect(updated.discoveredModels.isEmpty)  // nothing real parsed
    }

    @Test func pipeAndCommaSeparators() {
        let models = WebModelListParser.parse(dropdownText: "a | b, c", vendor: .custom)
        #expect(models == ["a", "b", "c"])
    }
}
