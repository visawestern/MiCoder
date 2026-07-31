import Foundation

/// Maps WebChatDriver events to user-visible chat content (plan Раздел 12
/// Блок 3 п.34 — show captcha in the chat). Pure/testable; the view renders
/// the returned presentation (captcha screenshot inline, status lines, etc.).
enum WebChatEventPresenter {
    enum Presentation: Equatable {
        /// Inline captcha the user must solve; carries PNG bytes to render.
        case captcha(pngBase64: String, note: String)
        /// A transient status line (streaming/tool/session events).
        case status(String)
        /// The model's final answer text.
        case answer(String)
        /// An error line.
        case error(String)
        /// Nothing to show (e.g. intermediate streaming suppressed).
        case none
    }

    static func present(_ event: WebChatEvent) -> Presentation {
        switch event {
        case .captchaDetected(let png):
            return .captcha(pngBase64: png.base64EncodedString(),
                            note: "Solve the captcha below to continue, then the agent resumes automatically.")
        case .loggedOut:
            return .status("Session expired — log in again to continue.")
        case .sessionLimitReached:
            return .status("Conversation too long — starting a fresh session and carrying over context…")
        case .sessionRestarted:
            return .status("New session started; continuing.")
        case .promptSplit(let parts):
            return .status("Large prompt sent in \(parts) parts.")
        case .toolCall(let call):
            return .status("↪ \(call.name)(\(call.arguments.keys.sorted().joined(separator: ", ")))")
        case .toolResult(let name, _):
            return .status("✓ \(name)")
        case .iterationLimitReached:
            return .status("Reached the tool-iteration limit for this turn.")
        case .final(let text):
            return .answer(text)
        case .error(let msg):
            return .error(msg)
        case .streaming:
            return .none   // streaming handled by live text update, not a message
        }
    }

    /// Whether an event requires user interaction before the agent can proceed.
    static func blocksUntilUserAction(_ event: WebChatEvent) -> Bool {
        switch event {
        case .captchaDetected, .loggedOut: return true
        default: return false
        }
    }
}

/// How a presented web-chat event should mutate the assistant message bubble
/// (Round 8 P2 — statuses used to go to a transient `streamingText` that was
/// wiped by `finishWebTurn()`, so "Session expired"/"captcha"/"iteration limit"
/// were silently lost and the user saw an empty bubble).
enum WebChatTurnMutation: Equatable {
    /// Replace the whole bubble content (final answer / fatal error).
    case replaceText(String, isFinished: Bool, isStreaming: Bool)
    /// Append a status line to the current content; keep waiting (captcha,
    /// logout, iteration limit, tool progress).
    case appendStatus(String)
    /// No visible change.
    case none

    /// Mapping from a presented event to the assistant-bubble mutation, so
    /// every non-suppressed event is visible in the chat (Round 8 P2).
    static func mutation(for presentation: WebChatEventPresenter.Presentation) -> WebChatTurnMutation {
        switch presentation {
        case .answer(let text):
            // Round 8 R2: a blank model answer must be reported, not rendered
            // as an empty finished bubble.
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let content = trimmed.isEmpty ? "The model returned an empty response." : text
            return .replaceText(content, isFinished: true, isStreaming: false)
        case .error(let msg):
            return .replaceText("Web provider error: \(msg)", isFinished: true, isStreaming: false)
        case .captcha(let b64, let note):
            return .appendStatus("\(note)\n\n![captcha](data:image/png;base64,\(b64))")
        case .status(let line):
            return .appendStatus(line)
        case .none:
            return .none
        }
    }
}
