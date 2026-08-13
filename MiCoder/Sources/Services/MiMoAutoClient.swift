import Foundation

/// Direct HTTP/SSE client for Xiaomi MiMo API and the separate MiMo Auto free channel.
/// The free channel is bootstrapped with a short-lived JWT before each request;
/// it is not the same protocol as the paid OpenAI-compatible `/v1` API.
final class MiMoAutoClient {
    static let shared = MiMoAutoClient()

    private let paidBaseURL = URL(string: "https://api.xiaomimimo.com/v1")!
    private let freeBaseURL = URL(string: "https://api.xiaomimimo.com/api/free-ai")!
    private let freeAPISunsetAt = Date(timeIntervalSince1970: 1_785_060_000) // 2026-07-26T10:00:00Z, official MiMo Code cutoff
    private let session = URLSession.shared

    /// Available MiMo models fetched from the paid API.
    struct MiMoModel: Identifiable, Codable, Hashable {
        let id: String
        var name: String { id }
        let isFree: Bool
        let contextLength: Int?
        let description: String?

        init(id: String, name: String? = nil, isFree: Bool = false, contextLength: Int? = nil, description: String? = nil) {
            self.id = id
            self.contextLength = contextLength
            self.description = description
            self.isFree = isFree
        }
    }

    /// Chat message for the OpenAI-compatible completion endpoints.
    struct MiMoMessage: Codable {
        let role: String
        let content: String
    }

    /// Fetch available models from the paid Xiaomi MiMo API.
    /// The free channel intentionally has no public `/models` endpoint; its
    /// availability is verified by `bootstrapFreeChannel()` instead.
    func listModels(apiKey: String? = nil) async throws -> [MiMoModel] {
        guard let apiKey, !apiKey.isEmpty else {
            return []
        }

        var request = URLRequest(url: paidBaseURL.appendingPathComponent("models"))
        request.timeoutInterval = 15
        applyPaidAuth(apiKey, to: &request)
        let (data, response) = try await session.data(for: request)
        try validate(response, data: data, operation: "model list")
        let decoded = try JSONDecoder().decode(ModelListResponse.self, from: data)
        return decoded.data.map { dto in
            MiMoModel(
                id: dto.id,
                isFree: false,
                contextLength: dto.contextLength,
                description: nil
            )
        }
    }

    /// Bootstrap the official MiMo Auto free channel and return its short-lived JWT.
    /// The client fingerprint is persisted locally so the service can associate
    /// subsequent bootstrap calls with the same app installation.
    func bootstrapFreeChannel() async throws -> String {
        guard Date() < freeAPISunsetAt else {
            throw MiMoAutoError.apiError("MiMo Auto free channel ended on 2026-07-26. Add a Xiaomi MiMo API key to continue.")
        }
        var request = URLRequest(url: freeBaseURL.appendingPathComponent("bootstrap"))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer anonymous", forHTTPHeaderField: "Authorization")
        let body = try JSONEncoder().encode(FreeBootstrapRequest(client: clientFingerprint()))
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try validate(response, data: data, operation: "MiMo Auto bootstrap")
        let decoded = try JSONDecoder().decode(FreeBootstrapResponse.self, from: data)
        guard !decoded.jwt.isEmpty else {
            throw MiMoAutoError.apiError("MiMo Auto bootstrap returned no token")
        }
        return decoded.jwt
    }

    /// Streaming chat completion. Empty API key uses the official MiMo Auto free route.
    func chatCompletion(
        model: String,
        messages: [MiMoMessage],
        apiKey: String? = nil,
        stream: Bool = true
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let isFreeChannel = apiKey?.isEmpty != false
                    let token = isFreeChannel ? try await bootstrapFreeChannel() : nil
                    let endpoint = isFreeChannel
                        ? freeBaseURL.appendingPathComponent("openai/chat/completions")
                        : paidBaseURL.appendingPathComponent("chat/completions")
                    var request = URLRequest(url: endpoint)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = 120

                    let effectiveModel = isFreeChannel ? "mimo-auto" : model
                    if let token {
                        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                        request.setValue("mimocode", forHTTPHeaderField: "X-Mimo-Source")
                    } else if let apiKey, !apiKey.isEmpty {
                        applyPaidAuth(apiKey, to: &request)
                    }

                    request.httpBody = try JSONEncoder().encode(
                        CompletionRequest(model: effectiveModel, messages: messages, stream: stream)
                    )

                    if stream {
                        let (bytes, response) = try await session.bytes(for: request)
                        let statusData = Data()
                        try validate(response, data: statusData, operation: "MiMo chat request")
                        for try await line in bytes.lines {
                            guard line.hasPrefix("data: ") else { continue }
                            let json = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                            if json == "[DONE]" { break }
                            guard let data = json.data(using: .utf8) else { continue }
                            if let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data) {
                                if let content = chunk.choices.first?.delta.content, !content.isEmpty {
                                    continuation.yield(content)
                                }
                                if let reasoning = chunk.choices.first?.delta.reasoningContent, !reasoning.isEmpty {
                                    continuation.yield(reasoning)
                                }
                            }
                        }
                    } else {
                        let (data, response) = try await session.data(for: request)
                        try validate(response, data: data, operation: "MiMo chat request")
                        let decoded = try JSONDecoder().decode(NonStreamResponse.self, from: data)
                        if let content = decoded.choices.first?.message.content, !content.isEmpty {
                            continuation.yield(content)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Verify that the anonymous MiMo Auto free channel can bootstrap.
    func validateFreeChannel() async -> Bool {
        guard Date() < freeAPISunsetAt else { return false }
        do {
            _ = try await bootstrapFreeChannel()
            return true
        } catch {
            return false
        }
    }

    /// Verify a paid API key. The free channel must use `bootstrapFreeChannel()`.
    func validateApiKey(_ key: String) async -> Bool {
        guard !key.isEmpty else { return false }
        do {
            _ = try await listModels(apiKey: key)
            return true
        } catch {
            return false
        }
    }

    private func clientFingerprint() -> String {
        let key = "com.micoder.mimoAuto.clientFingerprint"
        if let saved = UserDefaults.standard.string(forKey: key), !saved.isEmpty {
            return saved
        }
        let value = "micoder-\(UUID().uuidString.lowercased())"
        UserDefaults.standard.set(value, forKey: key)
        return value
    }

    private func applyPaidAuth(_ apiKey: String, to request: inout URLRequest) {
        request.setValue(apiKey, forHTTPHeaderField: "api-key")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    }

    private func validate(_ response: URLResponse, data: Data, operation: String) throws {
        guard let http = response as? HTTPURLResponse else {
            throw MiMoAutoError.apiError("\(operation) returned an invalid response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let suffix = body.isEmpty ? "" : ": \(String(body.prefix(300)))"
            throw MiMoAutoError.apiError("\(operation) failed (HTTP \(http.statusCode))\(suffix)")
        }
    }
}

// MARK: - Response Types

private struct FreeBootstrapRequest: Encodable {
    let client: String
}

private struct FreeBootstrapResponse: Decodable {
    let jwt: String
}

private struct ModelListResponse: Decodable {
    let data: [ModelDTO]

    struct ModelDTO: Decodable {
        let id: String
        let contextLength: Int?
    }
}

private struct CompletionRequest: Encodable {
    let model: String
    let messages: [MiMoAutoClient.MiMoMessage]
    let stream: Bool
}

private struct StreamChunk: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let delta: Delta

        struct Delta: Decodable {
            let content: String?
            let reasoningContent: String?

            enum CodingKeys: String, CodingKey {
                case content
                case reasoningContent = "reasoning_content"
            }
        }
    }
}

private struct NonStreamResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message

        struct Message: Decodable {
            let content: String
        }
    }
}

enum MiMoAutoError: LocalizedError {
    case invalidURL
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid MiMo API URL"
        case .apiError(let message):
            return message
        }
    }
}
