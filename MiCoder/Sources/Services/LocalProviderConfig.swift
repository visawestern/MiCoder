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

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ollama: return "Ollama"
        case .openCode: return "OpenCode"
        case .localAgent: return "Local Agent"
        }
    }

    var icon: String {
        switch self {
        case .ollama: return "desktopcomputer"
        case .openCode: return "terminal"
        case .localAgent: return "cpu"
        }
    }

    /// Health-check endpoint path used to verify the local HTTP server is up.
    var healthPath: String {
        switch self {
        case .ollama: return "/api/tags"
        case .openCode: return "/health"
        case .localAgent: return "/global/health"
        }
    }

    var defaultPort: Int {
        switch self {
        case .ollama: return 11434
        case .openCode: return 4096
        case .localAgent: return 4096
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

    var healthURL: String { serveBaseURL + kind.healthPath }

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
