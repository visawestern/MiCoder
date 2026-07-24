import Foundation

/// Local provider kinds configurable in the unified Providers tab
/// (plan Раздел 1 Блок 1 п.3 / Блок 4). These run via a local CLI or a local
/// HTTP serve endpoint, distinct from cloud CustomProviders.
enum LocalProviderKind: String, Codable, CaseIterable, Identifiable {
    case ollama
    case openCode
    case mimoCLI

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ollama: return "Ollama"
        case .openCode: return "OpenCode"
        case .mimoCLI: return "MiMo CLI"
        }
    }

    var icon: String {
        switch self {
        case .ollama: return "desktopcomputer"
        case .openCode: return "terminal"
        case .mimoCLI: return "cpu"
        }
    }

    /// Health-check endpoint path used to verify the local provider is up
    /// (plan Блок 4 п.36).
    var healthPath: String {
        switch self {
        case .ollama: return "/api/tags"
        case .openCode: return "/health"
        case .mimoCLI: return "/global/health"
        }
    }

    var defaultPort: Int {
        switch self {
        case .ollama: return 11434
        case .openCode: return 4096
        case .mimoCLI: return 4096
        }
    }

    /// Default executable path for CLI mode (best-effort; user-overridable).
    var defaultExecutablePath: String {
        switch self {
        case .ollama: return "/usr/local/bin/ollama"
        case .openCode: return "/usr/local/bin/opencode"
        case .mimoCLI: return "~/.micoder/bin/mimo"
        }
    }

    /// Whether this kind supports a CLI mode in addition to serve/HTTP.
    var supportsCLIMode: Bool {
        switch self {
        case .ollama: return false      // Ollama is HTTP-only from our side
        case .openCode, .mimoCLI: return true
        }
    }
}

/// How a local provider is reached (plan Блок 1 п.4 / Блок 4 п.35).
enum LocalProviderMode: String, Codable, CaseIterable, Identifiable {
    case cli        // spawn the CLI binary
    case serve      // connect to a local HTTP server (host:port)
    var id: String { rawValue }
}

/// Configuration of a local provider (Ollama / OpenCode / MiMo CLI).
/// Replaces the branded "MiMo Serve" card: the old serve host/port becomes a
/// mimoCLI provider in `.serve` mode (plan Блок 1 п.5, Блок 2 п.14-15).
struct LocalProviderConfig: Identifiable, Codable, Equatable {
    let id: String
    var kind: LocalProviderKind
    var mode: LocalProviderMode
    var executablePath: String
    var host: String
    var port: Int
    var workingDirectory: String
    var autoStart: Bool
    var isEnabled: Bool
    var models: [String]

    init(id: String = UUID().uuidString,
         kind: LocalProviderKind,
         mode: LocalProviderMode? = nil,
         executablePath: String? = nil,
         host: String = "127.0.0.1",
         port: Int? = nil,
         workingDirectory: String = "",
         autoStart: Bool = false,
         isEnabled: Bool = true,
         models: [String] = []) {
        self.id = id
        self.kind = kind
        self.mode = mode ?? (kind.supportsCLIMode ? .cli : .serve)
        self.executablePath = executablePath ?? kind.defaultExecutablePath
        self.host = host
        self.port = port ?? kind.defaultPort
        self.workingDirectory = workingDirectory
        self.autoStart = autoStart
        self.isEnabled = isEnabled
        self.models = models
    }

    /// Base URL for the serve endpoint (used for health-check and model list).
    var serveBaseURL: String { "http://\(host):\(port)" }

    var healthURL: String { serveBaseURL + kind.healthPath }

    /// Neutral display name — no "MiMo Serve" branding (plan Блок 2 п.7/п.12).
    var displayName: String {
        switch kind {
        case .mimoCLI: return mode == .serve ? "MiMo (Local Serve)" : "MiMo (Local CLI)"
        default: return kind.displayName
        }
    }
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

    /// Rewrite any user-facing "MiMo Serve" branding to a neutral label
    /// (plan Блок 2 п.7/п.12/п.20). Applied to server-provided provider names.
    static func neutralizeServeBranding(_ name: String) -> String {
        var result = name
        for branded in ["MiMo Serve", "MiMoServe", "Mimo Serve"] {
            result = result.replacingOccurrences(of: branded, with: "Local Agent")
        }
        return result
    }
}
