import Foundation

/// OpenCode Zen free-model client used by MiCoder Auto Free.
/// The provider is OpenAI-compatible, but still requires an OpenCode Zen API key.
final class MiCoderAutoFreeClient {
    static let shared = MiCoderAutoFreeClient()

    static let providerBaseURL = URL(string: "https://opencode.ai/zen/v1")!
    static let defaultModelID = "big-pickle"

    private let session = URLSession.shared

    struct Model: Identifiable, Codable, Hashable {
        let id: String
        var name: String { id }
        let isFree: Bool
        let contextLength: Int?
        let description: String?

        init(id: String, isFree: Bool = false, contextLength: Int? = nil, description: String? = nil) {
            self.id = id
            self.isFree = isFree
            self.contextLength = contextLength
            self.description = description
        }
    }

    struct Message: Codable, Equatable {
        let role: String
        let content: String
    }

    /// Fetch the current OpenCode Zen model catalog and keep the configured free model.
    func listModels(apiKey: String) async throws -> [Model] {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MiCoderAutoFreeError.apiError("OpenCode Zen API key is required")
        }
        var request = URLRequest(url: Self.providerBaseURL.appendingPathComponent("models"))
        request.timeoutInterval = 20
        applyAuth(apiKey, to: &request)
        let (data, response) = try await session.data(for: request)
        try validate(response, data: data, operation: "OpenCode model list")
        let decoded = try JSONDecoder().decode(ModelListResponse.self, from: data)
        let bigPickle = decoded.data.first(where: { $0.id == Self.defaultModelID })
        guard let model = bigPickle else {
            throw MiCoderAutoFreeError.apiError("OpenCode Zen did not return the free model big-pickle")
        }
        return [Model(id: model.id, isFree: true, contextLength: model.contextLength, description: model.description)]
    }

    /// Stream a chat completion through OpenCode Zen's OpenAI-compatible endpoint.
    func chatCompletion(
        model: String = Self.defaultModelID,
        messages: [Message],
        apiKey: String,
        stream: Bool = true
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !key.isEmpty else {
                        throw MiCoderAutoFreeError.apiError("Add an OpenCode Zen API key in Settings before sending.")
                    }
                    var request = URLRequest(url: Self.providerBaseURL.appendingPathComponent("chat/completions"))
                    request.httpMethod = "POST"
                    request.timeoutInterval = 180
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    applyAuth(key, to: &request)
                    request.httpBody = try JSONEncoder().encode(
                        CompletionRequest(
                            model: model.isEmpty ? Self.defaultModelID : model,
                            messages: messages,
                            stream: stream
                        )
                    )

                    if stream {
                        let (bytes, response) = try await session.bytes(for: request)
                        try validate(response, data: Data(), operation: "OpenCode chat request")
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
                        try validate(response, data: data, operation: "OpenCode chat request")
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

    func validateApiKey(_ key: String) async -> Bool {
        do {
            _ = try await listModels(apiKey: key)
            return true
        } catch {
            return false
        }
    }

    private func applyAuth(_ apiKey: String, to request: inout URLRequest) {
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    }

    private func validate(_ response: URLResponse, data: Data, operation: String) throws {
        guard let http = response as? HTTPURLResponse else {
            throw MiCoderAutoFreeError.apiError("\(operation) returned an invalid response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let suffix = body.isEmpty ? "" : ": \(String(body.prefix(400)))"
            throw MiCoderAutoFreeError.apiError("\(operation) failed (HTTP \(http.statusCode))\(suffix)")
        }
    }
}

private struct ModelListResponse: Decodable {
    let data: [ModelDTO]

    struct ModelDTO: Decodable {
        let id: String
        let contextLength: Int?
        let description: String?

        enum CodingKeys: String, CodingKey {
            case id
            case contextLength = "context_length"
            case description
        }
    }
}

private struct CompletionRequest: Encodable {
    let model: String
    let messages: [MiCoderAutoFreeClient.Message]
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

enum MiCoderAutoFreeError: LocalizedError {
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .apiError(let message): return message
        }
    }
}
