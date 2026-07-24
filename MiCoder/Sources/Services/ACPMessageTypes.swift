import Foundation

/// ACP message types extracted to a Foundation-only file so they are unit-testable
/// without pulling in the full ACPClient (which uses URLSession async APIs not
/// available on Linux). See plan Раздел 9 Блок 2.

/// A single part of a multimodal ACP message content (OpenAI-compatible).
/// Plan Раздел 9 Блок 2 п.12 — ACP must send real image bytes, not a placeholder.
enum ACPContentPart: Equatable {
    case text(String)
    case imageURL(url: String)   // data URL or remote URL

    var dictionary: [String: Any] {
        switch self {
        case .text(let text):
            return ["type": "text", "text": text]
        case .imageURL(let url):
            return ["type": "image_url", "image_url": ["url": url]]
        }
    }
}

struct ACPRequestToolCallFunction {
    let name: String
    let arguments: String

    var dictionary: [String: Any] {
        ["name": name, "arguments": arguments]
    }
}

struct ACPRequestToolCall {
    let id: String
    let type: String
    let function: ACPRequestToolCallFunction

    var dictionary: [String: Any] {
        ["id": id, "type": type, "function": function.dictionary]
    }
}

struct ACPRequestMessage {
    let role: String
    let content: String
    let toolCallID: String?
    let toolCalls: [ACPRequestToolCall]?
    /// Multimodal content parts (text + images). When present, the serialized
    /// `content` is an array of parts instead of a plain string (plan Блок 2 п.12).
    let contentParts: [ACPContentPart]?

    init(role: String, content: String, toolCallID: String? = nil, toolCalls: [ACPRequestToolCall]? = nil, contentParts: [ACPContentPart]? = nil) {
        self.role = role
        self.content = content
        self.toolCallID = toolCallID
        self.toolCalls = toolCalls
        self.contentParts = contentParts
    }

    var dictionary: [String: Any] {
        var d: [String: Any] = ["role": role]
        if let parts = contentParts, !parts.isEmpty {
            d["content"] = parts.map { $0.dictionary }
        } else {
            d["content"] = content
        }
        if let toolCallID {
            d["tool_call_id"] = toolCallID
        }
        if let toolCalls {
            d["tool_calls"] = toolCalls.map { $0.dictionary }
        }
        return d
    }
}
