import Foundation

/// Abstraction over a controllable browser (plan Раздел 12 Блок 3 п.27). The
/// live implementation drives Playwright MCP; tests inject a scripted bridge.
/// All methods are async and side-effecting on a real browser tab.
protocol BrowserAutomationBridge {
    /// Navigate the tab to a URL.
    func navigate(to url: String) async throws
    /// Type text into the element matching `selector` (optionally char-by-char).
    func typeText(_ text: String, into selector: String, humanized: Bool) async throws
    /// Click the element matching `selector`.
    func click(selector: String) async throws
    /// Click the first element matching `selector` whose visible text equals
    /// `text` (exact match, then partial fallback). Returns true if matched.
    /// Default implementation falls back to `click(selector:)` for test fakes.
    @discardableResult func clickByText(selector: String, text: String) async throws -> Bool
    /// Read the text content of the element matching `selector` (latest response).
    func readText(selector: String) async throws -> String
    /// Return a lightweight DOM fingerprint so a newly appended response can be
    /// distinguished from an unchanged response with identical text.
    func responseFingerprint(selector: String) async throws -> String
    /// Whether an element matching `selector` currently exists/visible.
    func exists(selector: String) async throws -> Bool
    /// Full visible page text (for captcha/login inference).
    func pageText() async throws -> String
    /// Current tab URL.
    func currentURL() async throws -> String
    /// All cookies for the current origin (name, value, expiry epoch).
    func cookies() async throws -> [BrowserCookie]
    /// Restore cookies into the browser context.
    func setCookies(_ cookies: [BrowserCookie]) async throws
    /// Take a screenshot of a region (for showing captcha in-chat); returns PNG bytes.
    func screenshot(selector: String?) async throws -> Data
    /// Request the vendor UI to stop the current generation.
    /// Test doubles may keep the default no-op implementation.
    func stopGeneration() async throws
    /// Sleep for the given milliseconds (host-controlled so tests are instant).
    func wait(ms: Int) async
    /// Wait for a selector to appear in the DOM (up to timeoutMs).
    func waitForSelector(selector: String, timeout: Int) async throws
    /// Read model names from a custom dropdown using a vendor-specific selector.
    func readModelItems(modelItemSelector: String) async throws -> [String]
    /// Read visible, selectable leaf candidates with DOM metadata.
    func readModelCandidates(modelItemSelector: String) async throws -> [WebModelDOMItem]
    /// Click a visible element whose normalized text exactly matches the label.
    @discardableResult func clickVisibleTextExact(selector: String, text: String) async throws -> Bool
    /// Evaluate JavaScript in the web view and return the result.
    func evaluateJS(_ script: String) async throws -> Any?
}

extension BrowserAutomationBridge {
    /// Default: fall back to `click(selector:)` so test fakes don't break.
    @discardableResult func clickByText(selector: String, text: String) async throws -> Bool {
        try await click(selector: selector)
        return true
    }

    /// Default: poll exists() until timeout.
    func waitForSelector(selector: String, timeout: Int = 5000) async throws {
        let deadline = Date().addingTimeInterval(Double(timeout) / 1000.0)
        while Date() < deadline {
            if try await exists(selector: selector) { return }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    /// Default: derive a conservative fingerprint from visible text. Real
    /// bridges override this with DOM node count/markup so repeated text still
    /// counts as a new response after a successful submit.
    func responseFingerprint(selector: String) async throws -> String {
        try await readText(selector: selector)
    }

    /// Default: no-op for test doubles without a real browser.
    func stopGeneration() async throws {}

    /// Default: empty list (test fakes override).
    func readModelItems(modelItemSelector: String) async throws -> [String] { [] }

    func readModelCandidates(modelItemSelector: String) async throws -> [WebModelDOMItem] {
        let labels = try await readModelItems(modelItemSelector: modelItemSelector)
        return labels.enumerated().map { index, label in
            WebModelDOMItem(label: label,
                            identity: "fallback-\(index)-\(label)",
                            isVisible: true,
                            isSelectable: true,
                            isDisabled: false,
                            isLeaf: true,
                            sourceSelector: modelItemSelector)
        }
    }

    @discardableResult func clickVisibleTextExact(selector: String, text: String) async throws -> Bool {
        try await clickByText(selector: selector, text: text)
    }

    /// Default: nil (test fakes override).
    func evaluateJS(_ script: String) async throws -> Any? { nil }
}

struct WebModelDOMItem: Codable, Equatable, Hashable {
    let label: String
    let identity: String
    let isVisible: Bool
    let isSelectable: Bool
    let isDisabled: Bool
    let isLeaf: Bool
    let sourceSelector: String
}

struct BrowserCookie: Codable, Equatable {
    let name: String
    let value: String
    let domain: String
    let path: String
    let expiresEpoch: TimeInterval?
    let httpOnly: Bool
    let secure: Bool

    init(name: String, value: String, domain: String, path: String = "/",
         expiresEpoch: TimeInterval? = nil, httpOnly: Bool = false, secure: Bool = true) {
        self.name = name
        self.value = value
        self.domain = domain
        self.path = path
        self.expiresEpoch = expiresEpoch
        self.httpOnly = httpOnly
        self.secure = secure
    }
}

/// Executes an emulated tool call against the real project (plan Блок 2 п.16).
/// Injected so WebChatDriver can be tested with a fake executor and used in the
/// app with the same executors that back native ACP/serve tool calls.
protocol WebToolExecutor {
    func execute(_ call: WebToolCall) async -> String
}

/// Events surfaced to the UI during a web-chat turn (plan Блок 3 п.34).
enum WebChatEvent: Equatable {
    case streaming(String)              // partial response text
    case toolCall(WebToolCall)          // model requested a tool
    case toolResult(name: String, result: String)
    case captchaDetected(screenshotPNG: Data)
    case loggedOut
    case final(String)                  // final answer text
    case error(String)
    case iterationLimitReached
    case promptSplit(parts: Int)        // large prompt sent as N messages
    case sessionLimitReached            // model reported conversation too long
    case sessionRestarted               // fresh session seeded with carry-over
    case modelInjectionFailed(String)   // could not set the selected model in web UI
    case effortInjectionFailed(String)  // could not set the selected effort in web UI
}

/// Vendor selector set resolved from web_providers_catalog.json (plan Блок 1 п.10).
struct WebVendorSelectors: Equatable {
    let input: String
    let sendButton: String
    let responseContainer: String
    let stopButton: String
}
