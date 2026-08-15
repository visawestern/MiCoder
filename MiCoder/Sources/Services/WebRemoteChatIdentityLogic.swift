import Foundation

/// Pure validation for a remote browser conversation identity. A remote chat
/// binding may be persisted only after one of these values is observed from the
/// provider's current page; local UUIDs and page headings are never accepted.
enum WebRemoteChatIdentityLogic {
    static func firstValid(_ candidates: [String]) -> String? {
        var seen = Set<String>()
        for raw in candidates {
            let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty,
                  value.count >= 4,
                  value.count <= 200,
                  value.rangeOfCharacter(from: .letters) != nil,
                  !value.contains("/"),
                  !value.contains("?"),
                  !value.contains("#"),
                  !isPlaceholder(value),
                  seen.insert(value).inserted else { continue }
            return value
        }
        return nil
    }

    static func canonicalURL(baseURL: String, vendor: WebChatVendor, chatID: String) -> String? {
        guard firstValid([chatID]) != nil,
              var components = URLComponents(string: baseURL),
              components.scheme != nil,
              components.host != nil else { return nil }
        let escapedID = chatID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? chatID
        components.path = vendor == .chatgpt ? "/c/\(escapedID)" : "/chat/\(escapedID)"
        components.query = nil
        components.fragment = nil
        return components.url?.absoluteString
    }

    private static func isPlaceholder(_ value: String) -> Bool {
        let lower = value.lowercased()
        return ["chat", "conversation", "session", "undefined", "null", "none", "new-chat", "new conversation"].contains(lower)
    }
}
