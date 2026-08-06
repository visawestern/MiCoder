import Testing
import Foundation
@testable import MiCoder

@Suite("Web chat driver — agentic loop over web chat (plan Раздел 12 Блок 2/3)")
struct WebChatDriverTests {

    /// Scripted browser: returns queued responses for readText, records actions.
    final class FakeBridge: BrowserAutomationBridge, @unchecked Sendable {
        var responses: [String]           // successive response-container texts
        var responseIndex = -1            // advances to 0 on the first send
        var url = "https://kimi.com/chat"
        var pageTextValue = "chat ready"
        var hasInput = true
        var stopButtonVisible = false
        var typed: [String] = []
        var clicks = 0
        var cookiesValue: [BrowserCookie] = []
        var navigations = 0

        init(responses: [String]) { self.responses = responses }

        func navigate(to url: String) async throws { self.url = url; navigations += 1 }
        func typeText(_ text: String, into selector: String, humanized: Bool) async throws { typed.append(text) }
        func click(selector: String) async throws {
            clicks += 1
            // Each send (click) yields the next scripted response.
            if responseIndex < responses.count - 1 { responseIndex += 1 }
        }
        func readText(selector: String) async throws -> String {
            guard !responses.isEmpty else { return "" }
            let idx = max(0, min(responseIndex, responses.count - 1))
            return responses[idx]
        }
        func exists(selector: String) async throws -> Bool {
            if selector.contains("stop") || selector.contains("top") { return stopButtonVisible }
            // Option selectors (model/effort dropdown items) only "exist" if they
            // reference a model/effort that is in the scripted responses. This
            // prevents injection from advancing the response index in tests.
            if selector.contains("option") || selector.contains("has-text") {
                return responses.contains { response in
                    selector.contains(response) || selector.lowercased().contains(response.lowercased())
                }
            }
            return hasInput
        }
        func pageText() async throws -> String { pageTextValue }
        func currentURL() async throws -> String { url }
        func cookies() async throws -> [BrowserCookie] { cookiesValue }
        func setCookies(_ cookies: [BrowserCookie]) async throws { cookiesValue = cookies }
        func screenshot(selector: String?) async throws -> Data { Data("png".utf8) }
        func wait(ms: Int) async {}
    }

    final class RecordingExecutor: WebToolExecutor, @unchecked Sendable {
        var executed: [WebToolCall] = []
        var resultFor: (WebToolCall) -> String
        init(resultFor: @escaping (WebToolCall) -> String = { _ in "OK" }) { self.resultFor = resultFor }
        func execute(_ call: WebToolCall) async -> String {
            executed.append(call)
            return resultFor(call)
        }
    }

    private let selectors = WebVendorSelectors(
        input: "textarea", sendButton: "button.send",
        responseContainer: "div.response", stopButton: "button.stop"
    )

    private func makeDriver(bridge: FakeBridge, executor: WebToolExecutor) -> WebChatDriver {
        var driver = WebChatDriver(
            bridge: bridge, executor: executor, selectors: selectors,
            config: WebProviderConfig(vendor: .kimi, toolCallDelayMs: 0, acknowledgedToS: true),
            projectRoot: "/proj",
            accessLevel: .askBeforeChanges
        )
        // Disable model/effort injection in tests — the fake bridge has no real
        // web UI, and injection clicks would advance the scripted response index.
        driver.injectModelAndEffortEnabled = false
        driver.randomUnit = { 0.5 }
        driver.pollIntervalMs = 0
        driver.stabilityChecks = 1
        return driver
    }

    @Test func finalAnswerWithNoToolCallEmitsFinal() async {
        let bridge = FakeBridge(responses: ["The answer is 42."])
        let exec = RecordingExecutor()
        let driver = makeDriver(bridge: bridge, executor: exec)

        var events: [WebChatEvent] = []
        await driver.runTurn(userMessage: "hi", isFirstMessage: false) { events.append($0) }

        #expect(events.contains(.final("The answer is 42.")))
        #expect(exec.executed.isEmpty)
    }

    @Test func toolCallRoundTripExecutesAndContinues() async {
        // 1st response: model asks to read a file. 2nd: final answer.
        let bridge = FakeBridge(responses: [
            "```tool\n{\"name\": \"read_file\", \"args\": {\"path\": \"a.txt\"}}\n```",
            "File says hello. Done."
        ])
        let exec = RecordingExecutor { _ in "hello" }
        let driver = makeDriver(bridge: bridge, executor: exec)

        var events: [WebChatEvent] = []
        await driver.runTurn(userMessage: "read a.txt", isFirstMessage: false) { events.append($0) }

        #expect(exec.executed.count == 1)
        #expect(exec.executed.first?.name == "read_file")
        #expect(events.contains(.toolResult(name: "read_file", result: "hello")))
        #expect(events.contains(.final("File says hello. Done.")))
    }

    @Test func firstMessagePrependsPreamble() async {
        let bridge = FakeBridge(responses: ["done"])
        let exec = RecordingExecutor()
        let driver = makeDriver(bridge: bridge, executor: exec)
        await driver.runTurn(userMessage: "task", isFirstMessage: true) { _ in }
        // First typed text must contain the tool preamble + the user message.
        #expect(bridge.typed.first?.contains("```tool") == true)
        #expect(bridge.typed.first?.contains("task") == true)
    }

    @Test func captchaInterruptsWithScreenshot() async {
        let bridge = FakeBridge(responses: ["irrelevant"])
        bridge.pageTextValue = "Please verify you are human"
        let exec = RecordingExecutor()
        let driver = makeDriver(bridge: bridge, executor: exec)

        var events: [WebChatEvent] = []
        await driver.runTurn(userMessage: "hi", isFirstMessage: false) { events.append($0) }

        let hasCaptcha = events.contains { if case .captchaDetected = $0 { return true }; return false }
        #expect(hasCaptcha)
        #expect(exec.executed.isEmpty)   // stopped before executing anything
    }

    @Test func loggedOutInterrupts() async {
        let bridge = FakeBridge(responses: ["x"])
        bridge.url = "https://chatgpt.com/auth/login"
        bridge.hasInput = false
        let driver = makeDriver(bridge: bridge, executor: RecordingExecutor())

        var events: [WebChatEvent] = []
        await driver.runTurn(userMessage: "hi", isFirstMessage: false) { events.append($0) }
        #expect(events.contains(.loggedOut))
    }

    @Test func iterationLimitStopsRunawayLoop() async {
        // Always returns a tool call → would loop forever without the limit.
        let bridge = FakeBridge(responses: ["```tool\n{\"name\": \"list_dir\", \"args\": {\"path\": \".\"}}\n```"])
        let exec = RecordingExecutor { _ in "[]" }
        var driver = makeDriver(bridge: bridge, executor: exec)
        driver = WebChatDriver(
            bridge: bridge, executor: exec, selectors: selectors,
            config: WebProviderConfig(vendor: .kimi, toolCallDelayMs: 0, maxToolIterations: 3, acknowledgedToS: true),
            projectRoot: "/proj",
            accessLevel: .askBeforeChanges,
            randomUnit: { 0.5 }, pollIntervalMs: 0, stabilityChecks: 1
        )
        var events: [WebChatEvent] = []
        await driver.runTurn(userMessage: "loop", isFirstMessage: false) { events.append($0) }
        #expect(events.contains(.iterationLimitReached))
        #expect(exec.executed.count <= 3)
    }

    @Test func invalidToolPathReturnsValidationErrorNotExecution() async {
        let bridge = FakeBridge(responses: [
            "```tool\n{\"name\": \"read_file\", \"args\": {\"path\": \"../../etc/passwd\"}}\n```",
            "stopped."
        ])
        let exec = RecordingExecutor()
        let driver = makeDriver(bridge: bridge, executor: exec)
        var events: [WebChatEvent] = []
        await driver.runTurn(userMessage: "hack", isFirstMessage: false) { events.append($0) }
        // Executor never runs the escaping path; a validation error is fed back.
        #expect(exec.executed.isEmpty)
        let hasValidationResult = events.contains { e in
            if case .toolResult(_, let r) = e { return r.contains("validation error") }
            return false
        }
        #expect(hasValidationResult)
    }

    @Test func sessionLimitTriggersRestartWithCarryOver() async {
        // 1st response: Kimi length-limit notice. 2nd (after restart): final.
        let bridge = FakeBridge(responses: [
            "Your conversation with Kimi is getting too long. Try starting a new session.",
            "Continuing. Done."
        ])
        let exec = RecordingExecutor()
        let driver = makeDriver(bridge: bridge, executor: exec)

        var events: [WebChatEvent] = []
        await driver.runTurn(userMessage: "hi", isFirstMessage: false) { events.append($0) }

        #expect(events.contains(.sessionLimitReached))
        #expect(events.contains(.sessionRestarted))
        #expect(bridge.navigations >= 1)          // navigated to a fresh chat
        #expect(events.contains(.final("Continuing. Done.")))
    }

    @Test func largeFirstMessageIsSplitIntoParts() async {
        let bridge = FakeBridge(responses: ["ok done"])
        let exec = RecordingExecutor()
        let driver = makeDriver(bridge: bridge, executor: exec)
        // A prompt well over the chunk budget forces a split.
        let big = Array(repeating: "This is a sentence about the task.", count: 400).joined(separator: "\n\n")

        var events: [WebChatEvent] = []
        await driver.runTurn(userMessage: big, isFirstMessage: true) { events.append($0) }

        let split = events.contains { if case .promptSplit = $0 { return true }; return false }
        #expect(split)
        // More than one message was typed for the single user turn.
        #expect(bridge.typed.count > 1)
        // Exactly one message carries the numbered FINAL PART header (the literal
        // "FINAL PART N/N" in the preamble instruction is not numbered).
        let numberedFinal = bridge.typed.filter { msg in
            msg.range(of: "FINAL PART [0-9]+/[0-9]+", options: .regularExpression) != nil
        }
        #expect(numberedFinal.count == 1)
    }
}

@Suite("Web session manager — cookie persistence (plan Раздел 12 Блок 3)")
struct WebSessionManagerTests {

    private func makeTempHome() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimo-websess-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func persistAndRestoreRoundTrip() throws {
        let home = try makeTempHome()
        let store = WebSessionStore(
            cookies: [BrowserCookie(name: "sid", value: "abc", domain: "kimi.com", expiresEpoch: 9_999_999_999)],
            localStorage: ["theme": "dark"], savedAt: Date()
        )
        try WebSessionManager.persist(store, providerId: "p1", homeDirectory: home)
        let restored = WebSessionManager.restore(providerId: "p1", homeDirectory: home)
        #expect(restored?.cookies.first?.value == "abc")
        #expect(restored?.localStorage["theme"] == "dark")
    }

    @Test func restoreReturnsNilWhenAbsent() throws {
        let home = try makeTempHome()
        #expect(WebSessionManager.restore(providerId: "none", homeDirectory: home) == nil)
    }

    @Test func clearRemovesStore() throws {
        let home = try makeTempHome()
        let store = WebSessionStore(cookies: [], localStorage: [:], savedAt: Date())
        try WebSessionManager.persist(store, providerId: "p2", homeDirectory: home)
        try WebSessionManager.clear(providerId: "p2", homeDirectory: home)
        #expect(WebSessionManager.restore(providerId: "p2", homeDirectory: home) == nil)
    }

    @Test func expiredWhenAllCookiesPast() {
        let store = WebSessionStore(
            cookies: [BrowserCookie(name: "s", value: "v", domain: "d", expiresEpoch: 100)],
            localStorage: [:], savedAt: Date(timeIntervalSince1970: 50)
        )
        #expect(WebSessionManager.isExpired(store, now: Date(timeIntervalSince1970: 200)))
        #expect(!WebSessionManager.isExpired(store, now: Date(timeIntervalSince1970: 50)))
    }
}
