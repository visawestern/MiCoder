import Foundation

/// Pure, testable session/captcha/anti-ban logic for web providers
/// (plan Раздел 12 Блок 3, testable parts). The actual browser I/O lives in
/// BrowserAutomationBridge (Playwright MCP); this file holds decisions.

/// State of a web-chat session as inferred from DOM/URL signals.
enum WebSessionState: Equatable {
    case connected
    case loggedOut          // redirected to login / chat field missing
    case captchaRequired    // captcha iframe/marker detected
    case unknown
}

enum WebSessionLogic {

    /// Infer session state from observable signals (plan Блок 3 п.32/п.33).
    static func inferState(currentURL: String,
                          hasChatInput: Bool,
                          pageText: String) -> WebSessionState {
        if detectCaptcha(pageText: pageText, url: currentURL) {
            return .captchaRequired
        }
        let lowerURL = currentURL.lowercased()
        if lowerURL.contains("/login") || lowerURL.contains("/signin") || lowerURL.contains("auth") {
            return .loggedOut
        }
        if !hasChatInput {
            return .loggedOut
        }
        return .connected
    }

    /// Detect a captcha challenge by well-known markers (plan Блок 3 п.33).
    static func detectCaptcha(pageText: String, url: String) -> Bool {
        let markers = [
            "recaptcha", "g-recaptcha", "hcaptcha", "h-captcha",
            "cf-turnstile", "cf-challenge", "challenges.cloudflare.com",
            "verify you are human", "verify you're human", "are you a robot",
            "i'm not a robot", "confirm you are human"
        ]
        let haystack = (pageText + " " + url).lowercased()
        return markers.contains { haystack.contains($0) }
    }

    /// Whether cookies indicate an expired/absent session (plan Блок 3 п.26).
    static func isSessionExpired(cookieExpiryEpochs: [TimeInterval], now: TimeInterval) -> Bool {
        guard !cookieExpiryEpochs.isEmpty else { return true }
        // Expired if every session cookie is already past its expiry.
        return cookieExpiryEpochs.allSatisfy { $0 <= now }
    }

    /// Whether a keep-alive ping is due (plan Блок 3 п.31).
    static func keepAliveDue(lastPing: TimeInterval, now: TimeInterval, intervalSec: Int) -> Bool {
        now - lastPing >= TimeInterval(intervalSec)
    }
}

/// Anti-ban / anti-captcha action delay with jitter (plan Раздел 12 Блок 2 п.22).
enum WebAntiBanTiming {
    /// Compute the delay (ms) for the next browser action, applying ±jitter%.
    /// `randomUnit` is an injectable [0,1) value for deterministic testing.
    static func delayMs(base: Int, jitterPercent: Double = 20, randomUnit: Double) -> Int {
        guard base > 0 else { return 0 }
        let clampedUnit = min(max(randomUnit, 0), 0.999999)
        let span = Double(base) * (jitterPercent / 100.0)
        // Map [0,1) to [-span, +span]
        let offset = (clampedUnit * 2 - 1) * span
        return max(0, Int((Double(base) + offset).rounded()))
    }

    /// Per-character human-typing delay (plan Блок 2 п.23).
    static func typingDelayMs(base: Int, randomUnit: Double) -> Int {
        delayMs(base: base, jitterPercent: 50, randomUnit: randomUnit)
    }
}
