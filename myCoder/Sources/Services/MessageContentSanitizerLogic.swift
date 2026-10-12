import Foundation

enum MessageContentSanitizerLogic {
    private static let systemReminderPattern = #"(?s)<system-reminder>.*?</system-reminder>"#

    static func sanitizedForDisplay(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let regex = try? NSRegularExpression(pattern: systemReminderPattern) else {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let stripped = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
        return stripped
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func sanitizedTextPart(_ text: String) -> String? {
        let cleaned = sanitizedForDisplay(text)
        return cleaned.isEmpty ? nil : cleaned
    }

    static func displayTexts(partTexts: [String], fallback: String) -> [String] {
        let visibleParts = partTexts.compactMap(sanitizedTextPart)
        if !visibleParts.isEmpty {
            return visibleParts
        }
        guard let fallbackText = sanitizedTextPart(fallback) else {
            return []
        }
        return [fallbackText]
    }
}

enum OpenCodeToolStatusLogic {
    static func isPending(status: String?, output: String?) -> Bool {
        let normalized = status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch normalized {
        case "running", "pending", "in_progress", "started":
            return true
        case "completed", "complete", "done", "success", "finished":
            return false
        case "error", "failed", "cancelled", "canceled":
            return false
        default:
            break
        }
        if let output, !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        return normalized.isEmpty || normalized == "running"
    }

    static func extractOutput(from state: [String: Any]?) -> String? {
        guard let state else { return nil }
        // Standard keys
        if let value = state["output"] as? String, !value.isEmpty { return value }
        if let value = state["result"] as? String, !value.isEmpty { return value }
        if let value = state["output"] { return jsonString(from: value) }
        if let value = state["result"] { return jsonString(from: value) }
        if let metadata = state["metadata"] as? [String: Any] { return jsonString(from: metadata) }
        
        // agentRouter/OmniRouter format: result может быть в content/message/data/text
        if let value = state["content"] as? String, !value.isEmpty { return value }
        if let value = state["message"] as? String, !value.isEmpty { return value }
        if let value = state["data"] as? String, !value.isEmpty { return value }
        if let value = state["text"] as? String, !value.isEmpty { return value }
        if let value = state["response"] as? String, !value.isEmpty { return value }
        
        // agentRouter format: вложенный объект result { content, ... }
        if let nestedResult = state["result"] as? [String: Any] {
            if let value = nestedResult["content"] as? String, !value.isEmpty { return value }
            if let value = nestedResult["message"] as? String, !value.isEmpty { return value }
            if let value = nestedResult["text"] as? String, !value.isEmpty { return value }
            if let value = nestedResult["output"] as? String, !value.isEmpty { return value }
            if !nestedResult.isEmpty { return jsonString(from: nestedResult) }
        }
        
        // OpenAI tool call format: function { arguments, name, output }
        if let function = state["function"] as? [String: Any] {
            if let value = function["output"] as? String, !value.isEmpty { return value }
            if let value = function["arguments"] as? String, !value.isEmpty {
                // arguments — это входные данные, но для agentRouter может быть ответом
                return value
            }
        }
        
        return nil
    }

    private static func jsonString(from value: Any) -> String? {
        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted]),
              let json = String(data: data, encoding: .utf8) else {
            if let string = value as? String, !string.isEmpty { return string }
            return nil
        }
        return json
    }
}
