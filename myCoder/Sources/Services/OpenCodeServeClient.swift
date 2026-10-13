import Foundation

/// Errors from the local OpenCode headless server (verified live against
/// `opencode serve` 1.18.29: POST /session → POST /session/:id/message).
enum OpenCodeServeError: Error, Equatable, LocalizedError {
    case transport(String)
    case unauthorized
    case http(status: Int, body: String)
    case decode
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .transport(let msg):
            return "Could not reach the local OpenCode server: \(msg). Start it with `opencode serve --port 4096`."
        case .unauthorized:
            return "The local OpenCode server requires basic auth (HTTP 401). Set the username/password on the OpenCode local provider — the same password as OPENCODE_SERVER_PASSWORD."
        case .http(let status, let body):
            let detail = body.isEmpty ? "" : " — \(body.prefix(200))"
            return "Local OpenCode server returned HTTP \(status)\(detail)"
        case .decode:
            return "The local OpenCode server response could not be parsed (unexpected format)."
        case .emptyResponse:
            return "The local OpenCode server returned no text."
        }
    }
}

/// Thin client for a user-run `opencode serve` (their own OAuth identity —
/// the only path that passes the upstream free-tier gate; anonymous header
/// tricks are gated server-side, probed live 2026-10-13).
/// Transport-injected for tests; production passes URLSession-backed transport.
enum OpenCodeServeClient {
    struct SendResult: Equatable {
        let content: String
        let sessionID: String
    }

    static func sessionURL(baseURL: String) -> String {
        baseURL.hasSuffix("/") ? "\(baseURL)session" : "\(baseURL)/session"
    }

    static func messageURL(baseURL: String, sessionID: String) -> String {
        let base = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        return "\(base)/session/\(sessionID)/message"
    }

    static func messageBody(modelID: String, text: String) -> [String: Any] {
        [
            "model": ["providerID": "opencode", "modelID": modelID],
            "parts": [["type": "text", "text": text]],
        ]
    }

    static func extractSessionID(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = json["id"] as? String, !id.isEmpty else { return nil }
        return id
    }

    /// Join all text parts; tool/step parts are skipped (same contract as the
    /// chat UI: only vendor-produced content completes a turn).
    static func extractText(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let parts = json["parts"] as? [[String: Any]] else { return nil }
        let text = parts.compactMap { part -> String? in
            guard part["type"] as? String == "text" else { return nil }
            return part["text"] as? String
        }.joined()
        return text.isEmpty ? nil : text
    }

    /// Send one turn: create a session unless `sessionID` is given, post the
    /// message, return the model text + the session to reuse.
    static func send(baseURL: String,
                     headers: [String: String],
                     modelID: String,
                     text: String,
                     sessionID: String? = nil,
                     transport: DirectChatTransport = URLSessionDirectChatTransport()) async throws -> SendResult {
        let sid: String
        if let sessionID, !sessionID.isEmpty {
            sid = sessionID
        } else {
            let body = try JSONSerialization.data(withJSONObject: ["title": String(text.prefix(60))])
            guard let (status, data) = await transport.post(url: sessionURL(baseURL: baseURL), headers: headers, body: body) else {
                throw OpenCodeServeError.transport("No response from \(baseURL)")
            }
            guard status != 401 else { throw OpenCodeServeError.unauthorized }
            guard (200..<300).contains(status), let id = extractSessionID(from: data) else {
                throw OpenCodeServeError.http(status: status, body: String(data: data, encoding: .utf8) ?? "")
            }
            sid = id
        }
        let msgBody = try JSONSerialization.data(withJSONObject: messageBody(modelID: modelID, text: text))
        guard let (status, data) = await transport.post(url: messageURL(baseURL: baseURL, sessionID: sid), headers: headers, body: msgBody) else {
            throw OpenCodeServeError.transport("No response from \(baseURL)")
        }
        guard status != 401 else { throw OpenCodeServeError.unauthorized }
        guard (200..<300).contains(status) else {
            throw OpenCodeServeError.http(status: status, body: String(data: data, encoding: .utf8) ?? "")
        }
        guard let content = extractText(from: data),
              ProviderResponseValidationLogic.hasVisibleContent(content) else {
            throw OpenCodeServeError.emptyResponse
        }
        return SendResult(content: content, sessionID: sid)
    }
}
