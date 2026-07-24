import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Auto-detection of a local provider by probing host:port (plan Раздел 9 Блок 3).
/// The detector classifies an endpoint as Ollama / OpenAI-compatible / MiMo CLI /
/// ACP by hitting known probe paths in order from most-specific to most-generic,
/// then auto-loads the model list for the detected type.

struct DetectedProviderInfo: Equatable {
    enum Kind: Equatable { case ollama, openAICompatible, mimoCLI, acp }
    let kind: Kind
    let baseURL: String
    /// Model ids discovered during probing (may be empty if the probe
    /// classified the type but the model list call failed).
    let models: [String]
}

/// Injectable HTTP probe so the detector stays unit-testable without a real
/// server or URLSession (plan Блок 3 п.35). Returns (statusCode, body) or nil.
protocol ProviderProbe {
    func get(url: String, headers: [String: String]) async -> (Int, Data)?
}

enum ProviderAutoDetector {
    /// Per-probe timeout (seconds).
    static let stepTimeout: TimeInterval = 2
    /// Overall timeout for the whole detection sequence.
    static let overallTimeout: TimeInterval = 10

    /// Probe an endpoint and classify it. Probes run from most-specific to
    /// most-generic to avoid misclassifying a specific server as generic
    /// OpenAI-compatible (plan Блок 3 п.26).
    static func detect(host: String, port: Int, probe: ProviderProbe) async -> DetectedProviderInfo? {
        let base = "http://\(host):\(port)"

        // (1) Ollama: GET /api/tags
        if let result = await probe.get(url: "\(base)/api/tags", headers: [:]),
           let models = parseOllamaTags(result.1) {
            return DetectedProviderInfo(kind: .ollama, baseURL: base, models: models)
        }

        // (2) MiMo CLI/Serve: GET /global/health
        if let health = await probe.get(url: "\(base)/global/health", headers: [:]), health.0 == 200 {
            let models = (await probe.get(url: "\(base)/global/models", headers: [:]))
                .flatMap { parseOpenAIModels($0.1) } ?? []
            return DetectedProviderInfo(kind: .mimoCLI, baseURL: base, models: models)
        }

        // (3) ACP: GET /acp/v1/models
        if let result = await probe.get(url: "\(base)/acp/v1/models", headers: [:]),
           let models = parseOpenAIModels(result.1) {
            return DetectedProviderInfo(kind: .acp, baseURL: base, models: models)
        }

        // (4) Generic OpenAI-compatible: GET /v1/models (fallback)
        if let result = await probe.get(url: "\(base)/v1/models", headers: [:]),
           let models = parseOpenAIModels(result.1) {
            return DetectedProviderInfo(kind: .openAICompatible, baseURL: base, models: models)
        }

        return nil
    }

    /// Heuristic warning for non-local addresses (plan Блок 3 п.34).
    static func isLikelyLocal(_ host: String) -> Bool {
        let h = host.lowercased()
        if h == "localhost" || h == "127.0.0.1" || h == "::1" { return true }
        if h.hasPrefix("192.168.") || h.hasPrefix("10.") { return true }
        if h.hasPrefix("172.") {
            let parts = h.split(separator: ".")
            if parts.count == 4, let n = Int(parts[1]), (16...31).contains(n) { return true }
        }
        if h.hasSuffix(".local") { return true }
        return false
    }

    // MARK: - Parsing helpers

    static func parseOllamaTags(_ data: Data) -> [String]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["models"] as? [[String: Any]] else { return nil }
        let names = models.compactMap { $0["name"] as? String }
        return names.isEmpty ? nil : names
    }

    static func parseOpenAIModels(_ data: Data) -> [String]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let models = json["data"] as? [[String: Any]] else { return nil }
        let names = models.compactMap { $0["id"] as? String }
        return names.isEmpty ? nil : names
    }
}

/// Live probe backed by URLSession with a per-request timeout.
struct URLSessionProviderProbe: ProviderProbe {
    let session: URLSession

    init(timeout: TimeInterval = ProviderAutoDetector.stepTimeout) {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }

    func get(url: String, headers: [String: String]) async -> (Int, Data)? {
        guard let url = URL(string: url) else { return nil }
        var request = URLRequest(url: url)
        for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }
        return await withCheckedContinuation { continuation in
            let task = session.dataTask(with: request) { data, response, _ in
                guard let http = response as? HTTPURLResponse, let data = data else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: (http.statusCode, data))
            }
            task.resume()
        }
    }
}
