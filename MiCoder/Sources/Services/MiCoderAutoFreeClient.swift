import Foundation

/// Anonymous OpenCode Zen client for MiCoder Auto Free.
/// Eligible models are the trusted temporary free-model IDs plus any live
/// `-free`-suffixed route; paid catalog models are never selected automatically.
final class MiCoderAutoFreeClient {
    static let shared = MiCoderAutoFreeClient()

    static let providerBaseURL = URL(string: "https://opencode.ai/zen/v1")!
    static let defaultModelID = "big-pickle"
    static let maxConsecutiveFailures = 5

    /// Ordered by preference. The list is intersected with the live `/models`
    /// response so a retired free model can never be selected accidentally.
    /// Kept in sync with the live catalog (verified 2026-09-04: 8 `-free`
    /// routes live; `hy3-free` and `ling-3.0-tiny-free` retired by the server).
    static let freeModelIDs = [
        "big-pickle",
        "muse-spark-1.3-contributor-free",
        "deepseek-v4-flash-free",
        "mimo-v2.5-free",
        "muse-spark-1.2-contributor-free",
        "ling-3.0-flash-fin-free",
        "laguna-s-2.1-free",
        "nemotron-3-ultra-free",
        "nemotron-3.5-lightning-free"
    ]

    private let session = URLSession.shared

    struct ModelProfile: Identifiable, Hashable {
        let id: String
        let displayName: String
        let summary: String
        let capabilities: [String]

        var capabilityLine: String { capabilities.joined(separator: " · ") }
    }

    struct Model: Identifiable, Codable, Hashable {
        let id: String
        var name: String { MiCoderAutoFreeClient.profile(for: id).displayName }
        let isFree: Bool
        let contextLength: Int?
        let description: String?

        var profile: ModelProfile { MiCoderAutoFreeClient.profile(for: id) }
        var effectiveDescription: String { description ?? profile.summary }
        var contextDescription: String {
            if let contextLength { return "\(contextLength.formatted()) tokens" }
            return "Not reported by live catalog"
        }

        init(id: String, isFree: Bool = true, contextLength: Int? = nil, description: String? = nil) {
            self.id = id
            self.isFree = isFree
            self.contextLength = contextLength
            self.description = description
        }
    }

    static func profile(for modelID: String) -> ModelProfile {
        profiles[modelID] ?? ModelProfile(
            id: modelID,
            displayName: modelID,
            summary: "Temporary OpenCode free route.",
            capabilities: ["Free", "Anonymous", "SSE"]
        )
    }

    private static let profiles: [String: ModelProfile] = [
        "big-pickle": ModelProfile(
            id: "big-pickle",
            displayName: "Big Pickle",
            summary: "Preferred temporary OpenCode free route.",
            capabilities: ["Free", "Anonymous", "SSE"]
        ),
        "deepseek-v4-flash-free": ModelProfile(
            id: "deepseek-v4-flash-free",
            displayName: "DeepSeek V4 Flash Free",
            summary: "Temporary OpenCode free route.",
            capabilities: ["Free", "Anonymous", "SSE"]
        ),
        "mimo-v2.5-free": ModelProfile(
            id: "mimo-v2.5-free",
            displayName: "MiMo V2.5 Free",
            summary: "Temporary OpenCode free route.",
            capabilities: ["Free", "Anonymous", "SSE"]
        ),
        "muse-spark-1.3-contributor-free": ModelProfile(
            id: "muse-spark-1.3-contributor-free",
            displayName: "Muse Spark 1.3 Contributor Free",
            summary: "Temporary OpenCode free route.",
            capabilities: ["Free", "Anonymous", "SSE"]
        ),
        "muse-spark-1.2-contributor-free": ModelProfile(
            id: "muse-spark-1.2-contributor-free",
            displayName: "Muse Spark 1.2 Contributor Free",
            summary: "Temporary OpenCode free route.",
            capabilities: ["Free", "Anonymous", "SSE"]
        ),
        "ling-3.0-flash-fin-free": ModelProfile(
            id: "ling-3.0-flash-fin-free",
            displayName: "Ling 3.0 Flash Fin Free",
            summary: "Temporary OpenCode free route.",
            capabilities: ["Free", "Anonymous", "SSE"]
        ),
        "hy3-free": ModelProfile(
            id: "hy3-free",
            displayName: "Hy3 Free",
            summary: "Temporary OpenCode free route.",
            capabilities: ["Free", "Anonymous", "SSE"]
        ),
        "laguna-s-2.1-free": ModelProfile(
            id: "laguna-s-2.1-free",
            displayName: "Laguna S 2.1 Free",
            summary: "Temporary OpenCode free route.",
            capabilities: ["Free", "Anonymous", "SSE"]
        ),
        "ling-3.0-tiny-free": ModelProfile(
            id: "ling-3.0-tiny-free",
            displayName: "Ling 3.0 Tiny Free",
            summary: "Temporary OpenCode free route.",
            capabilities: ["Free", "Anonymous", "SSE"]
        ),
        "nemotron-3-ultra-free": ModelProfile(
            id: "nemotron-3-ultra-free",
            displayName: "Nemotron 3 Ultra Free",
            summary: "Temporary OpenCode free route.",
            capabilities: ["Free", "Anonymous", "SSE"]
        ),
        "nemotron-3.5-lightning-free": ModelProfile(
            id: "nemotron-3.5-lightning-free",
            displayName: "Nemotron 3.5 Lightning Free",
            summary: "Temporary OpenCode free route.",
            capabilities: ["Free", "Anonymous", "SSE"]
        )
    ]

    struct Message: Codable, Equatable {
        let role: String
        let content: Content

        enum Content: Codable, Equatable {
            case text(String)
            case parts([MiCoderAutoFreeContentPart])

            init(from decoder: Decoder) throws {
                if let single = try? decoder.singleValueContainer(),
                   let text = try? single.decode(String.self) {
                    self = .text(text)
                    return
                }
                self = .parts(try [MiCoderAutoFreeContentPart](from: decoder))
            }

            func encode(to encoder: Encoder) throws {
                switch self {
                case .text(let text):
                    var single = encoder.singleValueContainer()
                    try single.encode(text)
                case .parts(let parts):
                    var container = encoder.unkeyedContainer()
                    for part in parts {
                        try container.encode(part)
                    }
                }
            }
        }

        init(role: String, content: String) {
            self.role = role
            self.content = .text(content)
        }

        init(role: String, parts: [MiCoderAutoFreeContentPart]) {
            self.role = role
            self.content = .parts(parts)
        }
    }

    /// Fetch the anonymous live catalog and return eligible free models:
    /// trusted IDs first (preference order), then any other live `-free` route.
    func listModels() async throws -> [Model] {
        var request = URLRequest(url: Self.providerBaseURL.appendingPathComponent("models"))
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        try validate(response, data: data, operation: "OpenCode free model list")
        let decoded = try JSONDecoder().decode(ModelListResponse.self, from: data)
        let byID = Dictionary(uniqueKeysWithValues: decoded.data.map { ($0.id, $0) })
        let liveFreeIDs = decoded.data.map(\.id).filter { Self.isEligibleFreeModel($0) }
        let orderedIDs = Self.freeModelIDs + liveFreeIDs.filter { !Self.freeModelIDs.contains($0) }.sorted()
        let models = orderedIDs.compactMap { id -> Model? in
            guard let dto = byID[id] else { return nil }
            return Model(id: dto.id, contextLength: dto.contextLength, description: dto.description)
        }
        guard !models.isEmpty else {
            throw MiCoderAutoFreeError.noFreeModels
        }
        return models
    }

    /// A model is eligible when it is a trusted temporary free route OR any
    /// live `-free`-suffixed route. The suffix is OpenCode Zen's own marker for
    /// free routes, so newly published free models (e.g. a future
    /// `*-contributor-free`) appear after refresh without an app update, while
    /// paid models (never `-free`-suffixed) stay unreachable anonymously.
    static func isEligibleFreeModel(_ modelID: String) -> Bool {
        freeModelIDs.contains(modelID) || modelID.hasSuffix("-free")
    }

    /// Stream a completion without an API key. The selected model must be in
    /// the live temporary free catalog; this prevents accidental paid usage.
    func chatCompletion(
        model: String = MiCoderAutoFreeClient.defaultModelID,
        messages: [Message],
        parameters: ModelCallParameters = ModelCallParameters(),
        stream: Bool = true
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let effectiveModel = model.isEmpty ? MiCoderAutoFreeClient.defaultModelID : model
                    guard MiCoderAutoFreeClient.isEligibleFreeModel(effectiveModel) else {
                        throw MiCoderAutoFreeError.modelUnavailable(effectiveModel, "Model is not in the OpenCode temporary free catalog")
                    }

                    var request = URLRequest(url: Self.providerBaseURL.appendingPathComponent("chat/completions"))
                    request.httpMethod = "POST"
                    request.timeoutInterval = 180
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    request.httpBody = try JSONEncoder().encode(
                        CompletionRequest(model: effectiveModel, messages: messages, parameters: parameters, stream: stream)
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
    let parameters: ModelCallParameters
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model, messages, stream, temperature, maxTokens = "max_tokens", topP = "top_p"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(messages, forKey: .messages)
        try container.encode(stream, forKey: .stream)
        try container.encodeIfPresent(parameters.temperature, forKey: .temperature)
        try container.encodeIfPresent(parameters.maxTokens, forKey: .maxTokens)
        try container.encodeIfPresent(parameters.topP, forKey: .topP)
    }
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
