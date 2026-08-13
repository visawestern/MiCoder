import Foundation

/// Anonymous OpenCode Zen client for MiCoder Auto Free.
/// Only the official temporary free-model IDs are eligible; paid catalog models
/// are never selected automatically.
final class MiCoderAutoFreeClient {
    static let shared = MiCoderAutoFreeClient()

    static let providerBaseURL = URL(string: "https://opencode.ai/zen/v1")!
    static let defaultModelID = "big-pickle"
    static let maxConsecutiveFailures = 5

    /// Ordered by preference. The list is intersected with the live `/models`
    /// response so a retired free model can never be selected accidentally.
    static let freeModelIDs = [
        "big-pickle",
        "deepseek-v4-flash-free",
        "mimo-v2.5-free",
        "hy3-free",
        "laguna-s-2.1-free",
        "ling-3.0-tiny-free",
        "nemotron-3-ultra-free",
        "nemotron-3.5-lightning-free"
    ]

    private let session = URLSession.shared

    struct Model: Identifiable, Codable, Hashable {
        let id: String
        var name: String { id }
        let isFree: Bool
        let contextLength: Int?
        let description: String?

        init(id: String, isFree: Bool = true, contextLength: Int? = nil, description: String? = nil) {
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

    /// Fetch the anonymous live catalog and return only known temporary free models.
    func listModels() async throws -> [Model] {
        var request = URLRequest(url: Self.providerBaseURL.appendingPathComponent("models"))
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        try validate(response, data: data, operation: "OpenCode free model list")
        let decoded = try JSONDecoder().decode(ModelListResponse.self, from: data)
        let byID = Dictionary(uniqueKeysWithValues: decoded.data.map { ($0.id, $0) })
        let models = Self.freeModelIDs.compactMap { id -> Model? in
            guard let dto = byID[id] else { return nil }
            return Model(id: dto.id, contextLength: dto.contextLength, description: dto.description)
        }
        guard !models.isEmpty else {
            throw MiCoderAutoFreeError.noFreeModels
        }
        return models
    }

    /// Stream a completion without an API key. The selected model must be in the
    /// trusted free-model allow-list; this prevents accidental paid usage.
    func chatCompletion(
        model: String = Self.defaultModelID,
        messages: [Message],
        stream: Bool = true
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let effectiveModel = model.isEmpty ? Self.defaultModelID : model
                    guard Self.freeModelIDs.contains(effectiveModel) else {
                        throw MiCoderAutoFreeError.modelUnavailable(effectiveModel, "Model is not in the OpenCode temporary free catalog")
                    }

                    var request = URLRequest(url: Self.providerBaseURL.appendingPathComponent("chat/completions"))
                    request.httpMethod = "POST"
                    request.timeoutInterval = 180
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.httpBody = try JSONEncoder().encode(
                        CompletionRequest(model: effectiveModel, messages: messages, stream: stream)
                    )

                    if stream {
                        let (bytes, response) = try await session.bytes(for: request)
                        try validate(response, data: Data(), operation: "OpenCode chat request")
                        var emitted = false
                        for try await line in bytes.lines {
                            guard line.hasPrefix("data: ") else { continue }
                            let json = String(line.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
                            if json == "[DONE]" { break }
                            guard let data = json.data(using: .utf8) else { continue }
                            if let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data) {
                                if let content = chunk.choices.first?.delta.content, !content.isEmpty {
                                    emitted = true
                                    continuation.yield(content)
                                }
                                if let reasoning = chunk.choices.first?.delta.reasoningContent, !reasoning.isEmpty {
                                    emitted = true
                                    continuation.yield(reasoning)
                                }
                            }
                        }
                        guard emitted else { throw MiCoderAutoFreeError.emptyResponse }
                    } else {
                        let (data, response) = try await session.data(for: request)
                        try validate(response, data: data, operation: "OpenCode chat request")
                        let decoded = try JSONDecoder().decode(NonStreamResponse.self, from: data)
                        guard let content = decoded.choices.first?.message.content,
                              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            throw MiCoderAutoFreeError.emptyResponse
                        }
                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    static func shouldSwitchImmediately(for error: Error) -> Bool {
        if let autoFreeError = error as? MiCoderAutoFreeError {
            switch autoFreeError {
            case .rateLimited, .modelUnavailable:
                return true
            case .apiError(let message):
                let lower = message.lowercased()
                return lower.contains("429") || lower.contains("rate limit") || lower.contains("ratelimit") || lower.contains("model")
            case .noFreeModels, .emptyResponse:
                return false
            }
        }
        return false
    }

    static func shouldSwitch(for error: Error, consecutiveFailures: Int) -> Bool {
        consecutiveFailures >= maxConsecutiveFailures || shouldSwitchImmediately(for: error)
    }

    private func validate(_ response: URLResponse, data: Data, operation: String) throws {
        guard let http = response as? HTTPURLResponse else {
            throw MiCoderAutoFreeError.apiError("\(operation) returned an invalid response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let suffix = body.isEmpty ? "" : ": \(String(body.prefix(400)))"
            if http.statusCode == 429 {
                throw MiCoderAutoFreeError.rateLimited("OpenCode rate limit reached")
            }
            if [400, 403, 404, 410].contains(http.statusCode) {
                throw MiCoderAutoFreeError.modelUnavailable("unknown", "\(operation) failed (HTTP \(http.statusCode))\(suffix)")
            }
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
            let content: String?
        }
    }
}

enum MiCoderAutoFreeError: LocalizedError {
    case noFreeModels
    case rateLimited(String)
    case modelUnavailable(String, String)
    case emptyResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noFreeModels:
            return "OpenCode currently reports no eligible free models."
        case .rateLimited(let message), .apiError(let message):
            return message
        case .modelUnavailable(let model, let message):
            return "OpenCode model \(model) is unavailable. \(message)"
        case .emptyResponse:
            return "OpenCode returned an empty response."
        }
    }
}
