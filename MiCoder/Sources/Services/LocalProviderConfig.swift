import Foundation

/// Local provider kinds configurable in the unified Providers tab.
///
/// The app is fully decoupled from any local CLI: it NEVER spawns `ollama`,
/// `opencode`, or `mimo`, and it never launches a serve process. A local
/// provider is only ever reached over HTTP at a `host:port` the **user** has
/// already started themselves (e.g. `ollama serve`, an OpenCode server, or a
/// local agent on localhost). No executable paths, no auto-start, no CLI mode.
enum LocalProviderKind: String, Codable, CaseIterable, Identifiable {
    case ollama
    case openCode
    case localAgent
    /// ACP-protocol server (probe: GET /acp/v1/models). Kept as its own kind so
    /// an auto-detected ACP server is NOT stored as OpenCode: OpenCode routes
    /// to OpenAI /v1/chat/completions, which a real ACP server doesn't speak.
    case acp

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ollama: return "Ollama"
        case .openCode: return "OpenCode"
        case .localAgent: return "Local Agent"
        case .acp: return "ACP"
        }
    }

    var icon: String {
        switch self {
        case .ollama: return "desktopcomputer"
        case .openCode: return "terminal"
        case .localAgent: return "cpu"
        case .acp: return "terminal.fill"
        }
    }

    /// Health-check endpoint path used to verify the local HTTP server is up.
    var healthPath: String {
        switch self {
        case .ollama: return "/api/tags"
        case .openCode: return "/health"
        case .localAgent: return "/global/health"
        case .acp: return "/models" // relative to the /acp/v1 API base
        }
    }

    var defaultPort: Int {
        switch self {
        case .ollama: return 11434
        case .openCode: return 4096
        case .localAgent: return 4096
        case .acp: return 8080
        }
    }
}

/// Configuration of a local provider reached over HTTP. There is exactly one
/// way to reach it — connect to a server the user is already running on
/// `host:port`. No CLI mode, no executable path, no auto-start.
struct LocalProviderConfig: Identifiable, Codable, Equatable {
    let id: String
    var kind: LocalProviderKind
    var host: String
    var port: Int
    var isEnabled: Bool
    var models: [String]

    init(id: String = UUID().uuidString,
         kind: LocalProviderKind,
         host: String = "127.0.0.1",
         port: Int? = nil,
         isEnabled: Bool = true,
         models: [String] = []) {
        self.id = id
        self.kind = kind
        self.host = host
        self.port = port ?? kind.defaultPort
        self.isEnabled = isEnabled
        self.models = models
    }

    /// Base URL for the serve endpoint (used for health-check and model list).
    var serveBaseURL: String { "http://\(host):\(port)" }

    /// Endpoint the client actually talks to. ACP servers speak the ACP
    /// protocol under `/acp/v1` (the ACPClient appends `chat/completions` to
    /// this base); every other kind uses the plain origin.
    var apiBaseURL: String {
        kind == .acp ? serveBaseURL + "/acp/v1" : serveBaseURL
    }

    var healthURL: String { apiBaseURL + kind.healthPath }

    var displayName: String { kind.displayName }
}

/// Pure logic for the unified Providers tab (plan Раздел 1 Блок 3-5).
enum LocalProviderLogic {
    static let storageKey = "com.micoder.localProviders"

    /// Persist local providers to UserDefaults (plan Блок 4 п.38).
    static func save(_ providers: [LocalProviderConfig], defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(providers) {
            defaults.set(data, forKey: storageKey)
        }
    }

    static func load(defaults: UserDefaults = .standard) -> [LocalProviderConfig] {
        guard let data = defaults.data(forKey: storageKey),
              let providers = try? JSONDecoder().decode([LocalProviderConfig].self, from: data) else {
            return []
        }
        return providers
    }

    /// Merge local providers into the unified provider option list alongside
    /// server + custom providers (plan Блок 4 п.39).
    static func providerOptions(from locals: [LocalProviderConfig]) -> [ProviderOption] {
        locals.filter { $0.isEnabled }.map {
            ProviderOption(id: $0.id, name: $0.displayName, isCustom: true, isConnected: $0.isEnabled)
        }
    }

    /// Fetch live models from a local provider's HTTP endpoint. Returns nil on
    /// any failure so callers can keep the existing list rather than wiping it.
    static func fetchModels(for config: LocalProviderConfig) async -> [String]? {
        let endpoint: String
        switch config.kind {
        case .ollama:
            endpoint = config.serveBaseURL + "/api/tags"
        case .openCode, .localAgent:
            endpoint = config.serveBaseURL + "/global/models"
        case .acp:
            endpoint = config.serveBaseURL + "/acp/v1/models"
        }
        guard let url = URL(string: endpoint) else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return parseModels(from: data, kind: config.kind)
        } catch {
            return nil
        }
    }

    /// Parse model list from each vendor's JSON shape.
    private static func parseModels(from data: Data, kind: LocalProviderKind) -> [String]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return nil }
        var names: [String] = []
        switch kind {
        case .ollama:
            if let dict = json as? [String: Any], let models = dict["models"] as? [[String: Any]] {
                names = models.compactMap { $0["name"] as? String }
            }
        case .openCode, .localAgent:
            if let dict = json as? [String: Any], let models = dict["models"] as? [[String: Any]] {
                names = models.compactMap { $0["id"] as? String ?? $0["name"] as? String }
            } else if let models = json as? [[String: Any]] {
                names = models.compactMap { $0["id"] as? String ?? $0["name"] as? String }
            }
        case .acp:
            if let dict = json as? [String: Any], let models = dict["models"] as? [[String: Any]] {
                names = models.compactMap { $0["id"] as? String ?? $0["name"] as? String }
            } else if let models = json as? [[String: Any]] {
                names = models.compactMap { $0["id"] as? String ?? $0["name"] as? String }
            }
        }
        return names.isEmpty ? nil : names
    }
}

/// Confirmation step for auto-detection (E23 — Раздел 9 п.30): the detector
/// must never add a provider on its own; it presents the finding and the user
/// explicitly confirms ("Подтвердить и добавить") or cancels. This logic builds
/// the confirmation copy and the config that confirmation would add, keeping
/// the no-auto-add rule testable and out of the view.
enum LocalProviderConfirmLogic {

    /// Short title naming the detected provider kind.
    static func title(for info: DetectedProviderInfo) -> String {
        "Detected: \(displayName(for: info.kind))"
    }

    /// Full confirmation copy: endpoint + model count.
    static func message(for info: DetectedProviderInfo, host: String, port: Int) -> String {
        "Found a \(displayName(for: info.kind)) provider at \(host):\(port) with \(info.models.count) model(s). Add it?"
    }

    /// The config that confirming would add — maps the detected kind to the
    /// unified local-provider card set. ACP stays ACP (never folded into
    /// OpenCode, which would route to an endpoint the ACP server doesn't speak).
    static func config(from info: DetectedProviderInfo, host: String, port: Int) -> LocalProviderConfig {
        let kind: LocalProviderKind
        switch info.kind {
        case .ollama: kind = .ollama
        case .mimoCLI: kind = .localAgent
        case .acp: kind = .acp
        case .openAICompatible: kind = .openCode
        }
        return LocalProviderConfig(kind: kind, host: host, port: port, models: info.models)
    }

    /// True when a config for the same host:port is already configured —
    /// confirming a duplicate would add nothing (E23 dedupe, kept testable and
    /// out of the view).
    static func isDuplicate(_ locals: [LocalProviderConfig], of cfg: LocalProviderConfig) -> Bool {
        locals.contains { $0.host == cfg.host && $0.port == cfg.port }
    }

    static func displayName(for kind: DetectedProviderInfo.Kind) -> String {
        switch kind {
        case .ollama: return "Ollama"
        case .mimoCLI: return "Local Agent"
        case .acp: return "ACP"
        case .openAICompatible: return "OpenAI-compatible"
        }
    }
}

/// User-facing status lines for the auto-detect flow (E23). Detection must
/// never add a provider on its own, and the status line must not claim a
/// provider was added when it was only detected, cancelled, or confirmed —
/// the old single "Detected: …" line was still shown after a cancel.
enum AutoDetectStatusText {
    /// Heuristic warning for non-local addresses (plan Блок 3 п.34). Returns
    /// nil for local addresses so the caller can compose it ahead of the result.
    static func warningForNonLocal(_ host: String) -> String? {
        ProviderAutoDetector.isLikelyLocal(host) ? nil : "Warning: \(host) is not a local address."
    }

    /// Shown right after detection, BEFORE the user confirms.
    static func detected(_ info: DetectedProviderInfo, host: String, port: Int) -> String {
        "Detected: \(LocalProviderConfirmLogic.displayName(for: info.kind)), \(info.models.count) model(s). Confirm to add."
    }

    static func nothingDetected(host: String, port: Int) -> String {
        "Nothing detected at \(host):\(port). Add manually below."
    }

    static func confirmed(_ info: DetectedProviderInfo, host: String, port: Int) -> String {
        "Added: \(LocalProviderConfirmLogic.displayName(for: info.kind)) at \(host):\(port)."
    }

    static func cancelled() -> String {
        "Detection cancelled — nothing was added."
    }

    static func invalidAddress() -> String {
        "Enter an address as host:port."
    }
}
