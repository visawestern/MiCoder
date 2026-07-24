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
    /// Read the text content of the element matching `selector` (latest response).
    func readText(selector: String) async throws -> String
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
    /// Sleep for the given milliseconds (host-controlled so tests are instant).
    func wait(ms: Int) async
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
}

/// Vendor selector set resolved from web_providers_catalog.json (plan Блок 1 п.10).
struct WebVendorSelectors: Equatable {
    let input: String
    let sendButton: String
    let responseContainer: String
    let stopButton: String
}
