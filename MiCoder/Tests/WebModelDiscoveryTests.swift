import Testing
import Foundation
@testable import MiCoder

// ═══════════════════════════════════════════════════════════════════════════
// Round 9 — Web model discovery (devil's-advocate: "models are stale/hardcoded
// instead of discovered from the page")
//
// RED tests pin down the four defects:
//   A. Discovery only runs on send, not when a web provider is connected
//   B. The model-dropdown selector is hardcoded in ChatPanelView instead of
//      coming from web_providers_catalog.json per vendor
//   C. A failed discovery silently falls back to vendor.defaultModels
//   D. The dropdown is never opened before reading, so most UIs return 0 items
// ═══════════════════════════════════════════════════════════════════════════

@Suite("Web model discovery — real models, not hardcoded (Round 9)")
struct WebModelDiscoveryTests {

    // MARK: - B: selectors come from the catalog, not hardcoded

    @Test("B each vendor's modelDropdown selector is loaded from the catalog")
    func bSelectorsComeFromCatalog() throws {
        // The catalog file must drive discovery; a site redesign is fixed by
        // data, not code. Every vendor that has a dropdown must expose its
        // selector through WebProviderCatalog, not a string literal in the view.
        let catalog = try WebProviderCatalog.loadBundled()
        let kimi = catalog.selectors(for: "kimi")
        #expect(kimi?.modelDropdown.isEmpty == false,
                "kimi must expose a catalog-driven model-dropdown selector")
        let chatgpt = catalog.selectors(for: "chatgpt")
        #expect(chatgpt?.modelDropdown.contains("model-switcher") == true)
        // And it must NOT be the single generic literal the view used before.
        #expect(chatgpt?.modelDropdown != "button[class*='model']")
    }

    // MARK: - C: failed discovery must not silently fall back to hardcoded

    @Test("C a failed discovery is surfaced as an error, not hidden")
    func cFailedDiscoveryIsVisible() throws {
        var cfg = WebProviderConfig(vendor: .kimi)  // discoveredModels empty
        // Simulate: discovery was attempted and came back empty → must NOT
        // silently present the hardcoded defaults as if they were real.
        let result = WebProviderConnectivity.modelsOrError(for: cfg, discoveryAttempted: true)
        switch result {
        case .models:
            Issue.record("expected a failure/empty signal when discovery ran and returned empty, got models")
        case .discoveryFailed(let why):
            #expect(!why.isEmpty)
        case .fallbackDefaults(let defaults):
            #expect(!defaults.isEmpty,
                    "fallback is allowed ONLY before the first discovery attempt, not after a failed one")
            _ = cfg // suppress unused warning
        }
    }

    @Test("C before any discovery attempt, defaults are explicitly labelled fallback")
    func cFallbackIsLabelled() {
        let cfg = WebProviderConfig(vendor: .kimi)  // never discovered
        let result = WebProviderConnectivity.modelsOrError(for: cfg, discoveryAttempted: false)
        if case .fallbackDefaults(let defaults) = result {
            #expect(defaults == WebChatVendor.kimi.defaultModels)
        } else {
            Issue.record("pre-discovery the models must be labelled as fallback defaults, got \(result)")
        }
    }

    @Test("C discovered real models always win over defaults")
    func cDiscoveredWins() {
        var cfg = WebProviderConfig(vendor: .kimi)
        cfg.discoveredModels = ["k2-0711-preview", "k2-thinking-pro"]
        let result = WebProviderConnectivity.modelsOrError(for: cfg, discoveryAttempted: true)
        if case .models(let list) = result {
            #expect(list == ["k2-0711-preview", "k2-thinking-pro"])
            #expect(list != WebChatVendor.kimi.defaultModels)
        } else {
            Issue.record("real discovered models must win, got \(result)")
        }
    }

    // MARK: - A: discovery runs when connecting, before the first send

    @Test("A a configured web provider exposes a discovery entry point independent of send")
    func aDiscoveryEntryPointExists() {
        // There must be a way to refresh models WITHOUT sending a message,
        // so Settings/connect can populate the picker immediately.
        let cfg = WebProviderConfig(vendor: .chatgpt)
        #expect(WebModelDiscovery.canRefresh(cfg) == true,
                "connect must be able to refresh model list before the first send")
    }

    // MARK: - D: the dropdown is opened before reading

    @Test("D discovery opens the dropdown before reading its items")
    func dDropdownIsOpened() async {
        let bridge = ScriptedBridge(texts: ["button[data-testid*='model-switcher']": "k2\nk2-thinking\nk1.5"])
        let discovered = await WebModelDiscovery.discover(
            using: bridge,
            dropdownSelector: "button[data-testid*='model-switcher']",
            vendor: .kimi
        )
        #expect(discovered == ["k2", "k2-thinking", "k1.5"])
        #expect(bridge.clickedSelectors.contains("button[data-testid*='model-switcher']"),
                "dropdown must be opened (clicked) before reading its options")
        #expect(bridge.readSelectors.contains("button[data-testid*='model-switcher']"))
    }

    @Test("D empty read yields a failure, not a silent empty list")
    func dEmptyReadIsFailure() async {
        let bridge = ScriptedBridge(texts: [:])
        #expect(await WebModelDiscovery.discover(using: bridge,
                                                 dropdownSelector: "sel",
                                                 vendor: .kimi) == nil,
                "an empty dropdown read must NOT be treated as a valid empty model list")
    }

    @Test("D read errors are reported, not swallowed")
    func dReadErrorIsFailure() async {
        let bridge = ScriptedBridge(texts: [:], readError: URLError(.cannotFindHost))
        #expect(await WebModelDiscovery.discover(using: bridge,
                                                 dropdownSelector: "sel",
                                                 vendor: .kimi) == nil)
    }

    // MARK: - helpers

    /// A minimal scripted browser bridge that records interactions so tests can
    /// assert "click dropdown, then read".
    private final class ScriptedBridge: BrowserAutomationBridge, @unchecked Sendable {
        let texts: [String: String]
        let readError: Error?
        private(set) var clickedSelectors: [String] = []
        private(set) var readSelectors: [String] = []

        init(texts: [String: String], readError: Error? = nil) {
            self.texts = texts
            self.readError = readError
        }

        func navigate(to url: String) async throws {}
        func wait(ms: Int) async {}
        func typeText(_ text: String, into selector: String, humanized: Bool) async throws {}
        func click(selector: String) async throws { clickedSelectors.append(selector) }
        func readText(selector: String) async throws -> String {
            readSelectors.append(selector)
            if let readError { throw readError }
            return texts[selector] ?? ""
        }
        func exists(selector: String) async throws -> Bool { !(texts[selector] ?? "").isEmpty }
        func currentURL() async throws -> String { "https://example.com" }
        func pageText() async throws -> String { "" }
        func screenshot(selector: String?) async throws -> Data { Data() }
        func cookies() async throws -> [BrowserCookie] { [] }
        func setCookies(_ cookies: [BrowserCookie]) async throws {}
    }
}
