import Foundation
import CryptoKit

/// Request context that mirrors the header contract of the official OpenCode
/// client for the `opencode` (Zen) provider.
///
/// Upstream reference: `packages/opencode/src/session/llm/request.ts`
/// (tag v1.19.4) — for OpenCode providers it sends `x-opencode-session-id`,
/// `x-opencode-session`, `x-opencode-request`, `x-opencode-client`,
/// `User-Agent`, and optionally `x-opencode-project` plus parent-session
/// headers. Session/message identifiers use the upstream `ses_`/`msg_` shape
/// (26 characters from the base62 alphabet); project identifiers are 40 hex
/// characters.
struct OpenCodeRequestContext: Equatable {
    static let clientName = "desktop"
    static let userAgent = "opencode/1.19.4 ai-sdk/provider-utils/4.0.23 runtime/bun/1.4.4"
    static let anonymousAuthorization = "Bearer public"

    static let identifierBodyLength = 26
    static let projectIdentifierLength = 40

    private static let identifierAlphabet = Array(
        "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    )

    var sessionID: String
    var parentSessionID: String?
    var projectID: String?
    var requestID: String?
    var additionalHeaders: [String: String]

    init(
        sessionID: String,
        parentSessionID: String? = nil,
        projectID: String? = nil,
        requestID: String? = nil,
        additionalHeaders: [String: String] = [:]
    ) {
        self.sessionID = sessionID
        self.parentSessionID = parentSessionID
        self.projectID = projectID
        self.requestID = requestID
        self.additionalHeaders = additionalHeaders
    }

    static func generated() -> OpenCodeRequestContext {
        OpenCodeRequestContext(sessionID: sessionID(from: UUID().uuidString))
    }

    /// Stable per chat: the same raw session id always maps to the same
    /// upstream-shaped identifier, so session affinity survives restarts.
    static func sessionID(from rawID: String) -> String {
        let normalized = rawID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return identifier(prefix: "ses", seed: UUID().uuidString)
        }
        if normalized.hasPrefix("ses_"), normalized.count == 4 + identifierBodyLength {
            return normalized
        }
        return identifier(prefix: "ses", seed: normalized)
    }

    /// Upstream sends the user message id in `x-opencode-request`.
    static func requestID() -> String {
        identifier(prefix: "msg", seed: UUID().uuidString)
    }

    /// Upstream sends an opaque 40 hex character project id, never a path.
    static func projectID(fromPath path: String) -> String? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let digest = Insecure.SHA1.hash(data: Data(trimmed.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func identifier(prefix: String, seed: String) -> String {
        let digest = Array(SHA256.hash(data: Data(seed.utf8)))
        var body = digest.prefix(6).map { String(format: "%02x", $0) }.joined()
        body += digest.dropFirst(6).prefix(14).map { String(identifierAlphabet[Int($0) % identifierAlphabet.count]) }.joined()
        return "\(prefix)_\(body)"
    }

    var affinity: String { sessionID }

    var headers: [String: String] {
        var headers: [String: String] = [
            "x-opencode-session-id": sessionID,
            "x-opencode-session": sessionID,
            "x-opencode-client": Self.clientName,
            "User-Agent": Self.userAgent,
            "Authorization": Self.anonymousAuthorization
        ]
        if let projectID, !projectID.isEmpty {
            headers["x-opencode-project"] = projectID
        }
        if let requestID, !requestID.isEmpty {
            headers["x-opencode-request"] = requestID
        }
        if let parentSessionID, !parentSessionID.isEmpty {
            headers["x-opencode-parent-session-id"] = parentSessionID
            headers["x-parent-session-id"] = parentSessionID
        }
        for (field, value) in additionalHeaders where !field.isEmpty {
            headers[field] = value
        }
        return headers
    }

    func applying(to request: inout URLRequest) {
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
    }

    func withRequestID(_ requestID: String?) -> OpenCodeRequestContext {
        var copy = self
        copy.requestID = requestID
        return copy
    }
}
