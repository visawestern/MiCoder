import Foundation

/// Round 30 — submission verification for browser-automation sends.
///
/// A single `click()` on the send control is NOT proof that the vendor page
/// submitted: on a freshly hydrated page the click can land before React binds
/// the handler, and the old code reported success anyway. Submission is instead
/// VERIFIED by observing the page URL gain a remote chat id (`/chat/{id}` on
/// Kimi/Qwen, `/c/{id}` on ChatGPT) after the click; if it does not appear
/// within the retry budget, the click repeats and finally fails honestly.
enum SendSubmissionPolicy {
    static let maxClickAttempts = 3
    static let verifyDelayMs = 1200

    /// Round 30b: bounded retries for model/effort menu matching. Menus can
    /// render late (fresh page, post-submission navigation), so a failed match
    /// re-opens the menu and tries again instead of one-shot failing.
    static let maxMatchRetries = 3
    static let matchRetryDelayMs = 800

    /// True only when the URL CHANGED and now carries a chat id segment.
    static func submissionDetected(beforeURL: String, afterURL: String) -> Bool {
        guard afterURL != beforeURL else { return false }
        return urlHasChatID(afterURL)
    }

    /// Whether a URL contains a plausible remote chat id (`/chat/` or `/c/`
    /// followed by a segment of at least 8 characters — real ids are UUIDs or
    /// long tokens; short junk like "short" must not count).
    static func urlHasChatID(_ url: String) -> Bool {
        for pattern in ["/chat/", "/c/"] {
            guard let range = url.range(of: pattern) else { continue }
            let part = url[range.upperBound...]
                .split(whereSeparator: { $0 == "/" || $0 == "?" || $0 == "#" })
                .first.map(String.init) ?? ""
            if part.count >= 8 { return true }
        }
        return false
    }
}
