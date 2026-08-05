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
    /// OpenAI-compatible (plan Блок 3 п.26). The whole sequence is bounded by
    /// `overallTimeout` (E24): each probe is raced against the deadline and
    /// cancelled in-flight once it passes, so a misbehaving endpoint cannot
    /// stretch detection beyond the budget (a start-gate alone would still
    /// allow a single hanging probe to eat a full step timeout, and the
    /// default 4 × stepTimeout would then exceed the overall timeout).
    static func detect(host: String, port: Int, probe: ProviderProbe) async -> DetectedProviderInfo? {
        await detect(host: host, port: port, probe: probe, overallTimeout: overallTimeout)
    }

    static func detect(host: String, port: Int, probe: ProviderProbe,
                       overallTimeout: TimeInterval) async -> DetectedProviderInfo? {
        let base = "http://\(host):\(port)"
        let deadline = Date().addingTimeInterval(overallTimeout)

        // (1) Ollama: GET /api/tags
        if let result = await probeOnce(probe, url: "\(base)/api/tags", headers: [:], deadline: deadline),
           let models = parseOllamaTags(result.1) {
            return DetectedProviderInfo(kind: .ollama, baseURL: base, models: models)
        }

        // (2) MiMo CLI/Serve: GET /global/health
        if let health = await probeOnce(probe, url: "\(base)/global/health", headers: [:], deadline: deadline),
           health.0 == 200 {
            let models = (await probeOnce(probe, url: "\(base)/global/models", headers: [:], deadline: deadline))
                .flatMap { parseOpenAIModels($0.1) } ?? []
            return DetectedProviderInfo(kind: .mimoCLI, baseURL: base, models: models)
        }

        // (3) ACP: GET /acp/v1/models
        if let result = await probeOnce(probe, url: "\(base)/acp/v1/models", headers: [:], deadline: deadline),
           let models = parseOpenAIModels(result.1) {
            return DetectedProviderInfo(kind: .acp, baseURL: base, models: models)
        }

        // (4) Generic OpenAI-compatible: GET /v1/models (fallback)
        if let result = await probeOnce(probe, url: "\(base)/v1/models", headers: [:], deadline: deadline),
           let models = parseOpenAIModels(result.1) {
            return DetectedProviderInfo(kind: .openAICompatible, baseURL: base, models: models)
        }

        return nil
    }

    /// Runs one probe but refuses to wait past `deadline`. The probe races a
    /// deadline timer; whichever finishes first wins, and the loser is
    /// cancelled so the group exits promptly (E24). This bounds probe
    /// DURATION, not just probe start — the cancellation contract is
    /// cooperative: probes must respond to task cancellation
    /// (`URLSessionProviderProbe` does; a probe that ignores cancellation
    /// still yields to its own step timeout).
    private static func probeOnce(_ probe: ProviderProbe, url: String,
                                  headers: [String: String],
                                  deadline: Date) async -> (Int, Data)? {
        if deadlinePassed(deadline) { return nil }
        let probeTask = Task { await probe.get(url: url, headers: headers) }
        let timeoutTask = Task { () -> (Int, Data)? in
            let remaining = deadline.timeIntervalSinceNow
            if remaining > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
            return nil
        }
        return await withTaskGroup(of: (Int, Data)?.self) { group -> (Int, Data)? in
            group.addTask { await probeTask.value }
            group.addTask { await timeoutTask.value }
            let first = await group.next() ?? nil
            // Cancel the loser so the group stops waiting on it immediately.
            probeTask.cancel()
            timeoutTask.cancel()
            return first
        }
    }

    /// True when the overall detection deadline has already passed.
    private static func deadlinePassed(_ deadline: Date) -> Bool {
        Date() >= deadline
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

/// Live probe backed by URLSession with a per-request timeout. Cancellation-
/// aware: cancelling the awaiting task cancels the in-flight URLSession task,
/// so the await returns promptly (the E24 deadline race relies on this to cut
/// a hanging probe short instead of waiting out its own step timeout).
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
        let session = self.session
        let box = URLSessionTaskBox()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<(Int, Data)?, Never>) in
                let task = session.dataTask(with: request) { data, response, _ in
                    if let http = response as? HTTPURLResponse, let data = data {
                        continuation.resume(returning: (http.statusCode, data))
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
                box.task = task
                if Task.isCancelled { task.cancel() } else { task.resume() }
            }
        } onCancel: {
            box.task?.cancel()
        }
    }
}

/// Thread-safe holder for the in-flight `URLSessionDataTask` so `onCancel` can
/// cancel it even though the handler may run on a different thread than the
/// one that created the task.
private final class URLSessionTaskBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _task: URLSessionDataTask?

    var task: URLSessionDataTask? {
        get { lock.lock(); defer { lock.unlock() }; return _task }
        set { lock.lock(); defer { lock.unlock() }; _task = newValue }
    }
}
