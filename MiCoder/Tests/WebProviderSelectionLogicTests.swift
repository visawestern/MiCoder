import Foundation
@testable import MiCoder

@Suite("Web provider selection and send contract")
struct WebProviderSelectionLogicTests {
    @Test("Selecting a web model updates the persisted config value")
    func selectingModelUsesOneSourceOfTruth() {
        let config = WebProviderConfig(
            vendor: .kimi,
            selectedModel: "k2",
            discoveredModels: [WebProviderModel(name: "k2"), WebProviderModel(name: "k2-thinking")]
        )
        let updated = WebProviderSelectionLogic.selectingModel(
            "k2-thinking",
            in: config,
            availableModels: ["k2", "k2-thinking"]
        )
        #expect(updated.selectedModel == "k2-thinking")
    }

    @Test("Unknown web model cannot silently replace the selected model")
    func selectingUnknownModelIsIgnored() {
        let config = WebProviderConfig(vendor: .qwen, selectedModel: "qwen-plus")
        let updated = WebProviderSelectionLogic.selectingModel(
            "not-in-menu",
            in: config,
            availableModels: ["qwen-plus"]
        )
        #expect(updated.selectedModel == "qwen-plus")
    }

    @Test("Built-in web providers expose an effort menu before discovery")
    func effortMenuIsNotHiddenBeforeDiscovery() {
        for vendor in [WebChatVendor.kimi, .qwen, .chatgpt] {
            let config = WebProviderConfig(vendor: vendor)
            #expect(WebProviderSelectionLogic.availableEfforts(for: config) == WebEffort.allCases)
        }
        #expect(WebProviderSelectionLogic.availableEfforts(for: WebProviderConfig(vendor: .custom)).isEmpty)
    }

    @Test("Selecting web effort updates only the web provider config")
    func selectingEffortUsesConfig() {
        let config = WebProviderConfig(vendor: .qwen, effort: .medium)
        let updated = WebProviderSelectionLogic.selectingEffort(.high, in: config)
        #expect(updated.effort == .high)
    }
}

@Suite("Web driver model and effort guard")
struct WebDriverSelectionGuardTests {
    final class InjectionBridge: BrowserAutomationBridge, @unchecked Sendable {
        var typed: [String] = []
        var sendClicks = 0
        var menuClicks = 0
        let acceptsOption: Bool

        init(acceptsOption: Bool) { self.acceptsOption = acceptsOption }

        func navigate(to url: String) async throws {}
        func typeText(_ text: String, into selector: String, humanized: Bool) async throws { typed.append(text) }
        func click(selector: String) async throws {
            menuClicks += 1
            if selector.contains("send") { sendClicks += 1 }
        }
        func clickByText(selector: String, text: String) async throws -> Bool { acceptsOption }
        func readText(selector: String) async throws -> String { "final answer" }
        func exists(selector: String) async throws -> Bool { true }
        func pageText() async throws -> String { "chat ready" }
        func currentURL() async throws -> String { "https://kimi.com/chat" }
        func cookies() async throws -> [BrowserCookie] { [] }
        func setCookies(_ cookies: [BrowserCookie]) async throws {}
        func screenshot(selector: String?) async throws -> Data { Data() }
        func wait(ms: Int) async {}
    }

    struct NoopExecutor: WebToolExecutor {
        func execute(_ call: WebToolCall) async -> String { "ok" }
    }

    private let selectors = WebVendorSelectors(
        input: "textarea",
        sendButton: "button.send",
        responseContainer: "div.response",
        stopButton: "button.stop"
    )

    @Test("A failed model injection blocks the send")
    func failedModelInjectionBlocksSend() async {
        let bridge = InjectionBridge(acceptsOption: false)
        let driver = WebChatDriver(
            bridge: bridge,
            executor: NoopExecutor(),
            selectors: selectors,
            config: WebProviderConfig(vendor: .kimi, selectedModel: "missing-model", effort: .high),
            projectRoot: "/tmp",
            accessLevel: .askBeforeChanges,
            pollIntervalMs: 0,
            stabilityChecks: 1
        )
        var events: [WebChatEvent] = []
        await driver.runTurn(userMessage: "hello", isFirstMessage: false) { events.append($0) }
        #expect(bridge.typed.isEmpty)
        #expect(bridge.sendClicks == 0)
        #expect(events.contains { event in
            if case .error(let message) = event { return message.contains("not found") }
            return false
        })
    }

    @Test("A confirmed model and effort are injected before send")
    func successfulInjectionPrecedesSend() async {
        let bridge = InjectionBridge(acceptsOption: true)
        let driver = WebChatDriver(
            bridge: bridge,
            executor: NoopExecutor(),
            selectors: selectors,
            config: WebProviderConfig(vendor: .kimi, selectedModel: "k2", effort: .high),
            projectRoot: "/tmp",
            accessLevel: .askBeforeChanges,
            pollIntervalMs: 0,
            stabilityChecks: 1
        )
        await driver.runTurn(userMessage: "hello", isFirstMessage: false) { _ in }
        #expect(bridge.typed.count == 1)
        #expect(bridge.sendClicks == 1)
    }
}
