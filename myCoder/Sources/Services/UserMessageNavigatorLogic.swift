import Foundation

/// Pure helpers for the floating chat navigator that jumps between the
/// user's own messages. Kept out of the view so the filtering, whitespace
/// normalization and 100-character hover preview are covered by tests.
enum UserMessageNavigatorLogic {
    static let previewCharacterLimit = 100

    static func userMessages(_ messages: [Message]) -> [Message] {
        messages.filter { message in
            message.role == .user && !preview(for: message).isEmpty
        }
    }

    static func preview(for message: Message,
                        limit: Int = previewCharacterLimit) -> String {
        var text = normalized(message.content)
        if text.isEmpty, let files = message.files {
            text = normalized(files.map(\.name).joined(separator: ", "))
        }
        guard limit > 0, text.count > limit else { return text }
        let prefix = String(text.prefix(limit))
            .trimmingCharacters(in: .whitespaces)
        return prefix + "…"
    }

    static func buttonTitle(index: Int) -> String {
        "\(index + 1)"
    }

    private static func normalized(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }
}
