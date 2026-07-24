import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Real OpenAI-compatible chat client for local (Ollama/OpenCode) and custom
/// providers so messages actually reach the selected model (fixes the empty-
/// response bug for non-serve providers). Body building is pure/testable; the
/// HTTP send uses an injectable transport.
struct DirectChatMessage: Equatable {
    let role: String   // "user" | "assistant" | "system"
    let content: String
}

protocol DirectChatTransport {
    /// POST JSON to url, return (status, body) or nil on failure.
    func post(url: String, headers: [String: String], body: Data) async -> (Int, Data)?
}

enum DirectChatClient {
    /// Build an OpenAI /chat/completions request body. Includes per-model call
    /// parameters (temperature/max_tokens/...) when customized (Раздел 13 п.14).
    static func requestBody(model: String,
                           messages: [DirectChatMessage],
                           parameters: ModelCallParameters = ModelCallParameters(),
                           stream: Bool = false) -> [String: Any] {
        var body: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
            "stream": stream
        ]
        for (k, v) in ModelCallParametersStore.requestFragment(parameters) {
            // OpenAI uses "system" as a message, not a body key — skip here.
            if k == "system" { continue }
            body[k] = v
        }
        return body
    }

    /// Extract assistant text from an OpenAI-compatible response body.
    static func parseResponseText(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        // OpenAI: choices[0].message.content
        if let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        // Ollama /api/chat style: message.content
        if let message = json["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }
        return nil
    }

    /// Compose the full message list including an optional system prompt.
    static func messages(systemPrompt: String?, userText: String,
                        history: [DirectChatMessage] = []) -> [DirectChatMessage] {
        var msgs: [DirectChatMessage] = []
        if let sys = systemPrompt, !sys.isEmpty { msgs.append(DirectChatMessage(role: "system", content: sys)) }
        msgs.append(contentsOf: history)
        msgs.append(DirectChatMessage(role: "user", content: userText))
        return msgs
    }

    /// Send a chat completion and return the assistant text, or throws.
    static func send(baseURL: String,
                    apiKey: String?,
                    model: String,
                    messages: [DirectChatMessage],
                    parameters: ModelCallParameters = ModelCallParameters(),
                    transport: DirectChatTransport = URLSessionDirectChatTransport()) async throws -> String {
        let url = baseURL.hasSuffix("/") ? "\(baseURL)chat/completions" : "\(baseURL)/chat/completions"
        var headers = ["Content-Type": "application/json"]
        if let key = apiKey, !key.isEmpty { headers["Authorization"] = "Bearer \(key)" }
        let body = requestBody(model: model, messages: messages, parameters: parameters)
        let data = try JSONSerialization.data(withJSONObject: body)
        guard let (status, respData) = await transport.post(url: url, headers: headers, body: data) else {
            throw DirectChatError.transport("No response from \(url)")
        }
        guard (200..<300).contains(status) else {
            let text = String(data: respData, encoding: .utf8) ?? ""
            throw DirectChatError.http(status: status, body: text)
        }
        guard let content = parseResponseText(respData) else {
            throw DirectChatError.decode
        }
        return content
    }
}

enum DirectChatError: Error, Equatable, LocalizedError {
    case transport(String)
    case http(status: Int, body: String)
    case decode

    /// User-facing message shown in the chat when a direct send fails
    /// (audit P5 — generic localizedDescription was useless).
    var errorDescription: String? {
        switch self {
        case .transport(let msg):
            return "Could not reach the provider: \(msg). Check the address/port and that the server is running."
        case .http(let status, let body):
            let detail = body.isEmpty ? "" : " — \(body.prefix(200))"
            return "Provider returned HTTP \(status)\(detail)"
        case .decode:
            return "The provider's response could not be parsed (unexpected format)."
        }
    }
}

/// Live transport over URLSession (cross-platform continuation bridge).
struct URLSessionDirectChatTransport: DirectChatTransport {
    let session: URLSession
    init(timeout: TimeInterval = 120) {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = timeout
        self.session = URLSession(configuration: cfg)
    }
    func post(url: String, headers: [String: String], body: Data) async -> (Int, Data)? {
        guard let u = URL(string: url) else { return nil }
        var req = URLRequest(url: u)
        req.httpMethod = "POST"
        req.httpBody = body
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
        return await withCheckedContinuation { cont in
            session.dataTask(with: req) { data, response, _ in
                guard let http = response as? HTTPURLResponse, let data = data else {
                    cont.resume(returning: nil); return
                }
                cont.resume(returning: (http.statusCode, data))
            }.resume()
        }
    }
}
