import Foundation

/// Direct HTTP/SSE client for MiMo API (MiMo-Auto built-in provider).
/// Connects directly to MiMo servers without a local serve process.
final class MiMoAutoClient {
    static let shared = MiMoAutoClient()

    private let baseURL = "https://api.mimo.ai/v1"
    private let session = URLSession.shared

    /// Available MiMo models fetched from the API.
    struct MiMoModel: Identifiable, Codable, Hashable {
        let id: String
        var name: String { id }
        let isFree: Bool
        let contextLength: Int?
        let description: String?

        init(id: String, name: String? = nil, isFree: Bool = false, contextLength: Int? = nil, description: String? = nil) {
            self.id = id
            self.isFree = isFree
            self.contextLength = contextLength
            self.description = description
        }
    }

    /// Chat message for the completions endpoint.
    struct MiMoMessage: Codable {
        let role: String
        let content: String
    }

    /// Fetch available models from MiMo API.
    func listModels(apiKey: String? = nil) async throws -> [MiMoModel] {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw MiMoAutoError.invalidURL
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        if let key = apiKey, !key.isEmpty {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw MiMoAutoError.apiError("Failed to fetch models")
        }
        let decoded = try JSONDecoder().decode(ModelListResponse.self, from: data)
        return decoded.data.map { dto in
            MiMoModel(
                id: dto.id,
                isFree: dto.id.contains("free") || dto.id == "mimo-auto",
                contextLength: dto.contextLength,
                description: nil
            )
        }
    }

    /// Streaming chat completion. Yields delta chunks as they arrive.
    func chatCompletion(
        model: String,
        messages: [MiMoMessage],
        apiKey: String? = nil,
        stream: Bool = true
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(baseURL)/chat/completions") else {
                        throw MiMoAutoError.invalidURL
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    if let key = apiKey, !key.isEmpty {
                        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                    }
                    request.timeoutInterval = 120

                    let body = CompletionRequest(
                        model: model,
                        messages: messages,
                        stream: stream
                    )
                    request.httpBody = try JSONEncoder().encode(body)

                    if stream {
                        let (bytes, response) = try await session.bytes(for: request)
                        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                            throw MiMoAutoError.apiError("Request failed")
                        }
                        for try await line in bytes.lines {
                            if line.hasPrefix("data: ") {
                                let json = String(line.dropFirst(6))
                                if json == "[DONE]" { break }
                                if let data = json.data(using: .utf8),
                                   let chunk = try? JSONDecoder().decode(StreamChunk.self, from: data),
                                   let delta = chunk.choices.first?.delta.content {
                                    continuation.yield(delta)
                                }
                            }
                        }
                    } else {
                        let (data, response) = try await session.data(for: request)
                        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                            throw MiMoAutoError.apiError("Request failed")
                        }
                        let decoded = try JSONDecoder().decode(NonStreamResponse.self, from: data)
                        if let content = decoded.choices.first?.message.content {
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

    /// Verify API key is valid.
    func validateApiKey(_ key: String) async -> Bool {
        do {
            _ = try await listModels(apiKey: key)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Response Types

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
        case .invalidURL: return "Invalid MiMo API URL"
        case .apiError(let msg): return msg
        }
    }
}
