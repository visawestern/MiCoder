import Foundation

/// Web-chat vendor supported for browser/cookie-based free-model access
/// (plan Раздел 12 Блок 1). Selectors/URLs live in `web_providers_catalog.json`
/// so a site redesign is fixed by data, not code.
enum WebChatVendor: String, Codable, CaseIterable, Identifiable {
    case kimi
    case qwen
    case chatgpt
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kimi: return "Kimi"
        case .qwen: return "Qwen"
        case .chatgpt: return "ChatGPT"
        case .custom: return "Custom Web Chat"
        }
    }

    var defaultChatURL: String {
        switch self {
        case .kimi: return "https://www.kimi.com/"
        case .qwen: return "https://chat.qwen.ai/"
        case .chatgpt: return "https://chatgpt.com/"
        case .custom: return ""
        }
    }

    /// Default model ids offered by each vendor's web UI (data, refreshable).
    var defaultModels: [String] {
        switch self {
        case .kimi: return ["k2", "k2-thinking", "k1.5"]
        case .qwen: return ["qwen-max", "qwen-plus", "qwen2.5-coder"]
        case .chatgpt: return ["gpt-4o", "gpt-4.1", "o3", "o4-mini"]
        case .custom: return []
        }
    }
}

/// Effort/thinking level mapped to each vendor's toggle (plan Блок 1 п.6).
enum WebEffort: String, Codable, CaseIterable, Identifiable {
    case low, medium, high
    var id: String { rawValue }
}

/// How the browser session is driven (plan Блок 1 п.4).
enum WebTransport: String, Codable, CaseIterable, Identifiable {
    /// A dedicated managed browser under Playwright MCP control.
    case playwrightMCP
    /// Reuse the user's already-logged-in Chrome via CDP + its cookies.
    case cdpCookies
    var id: String { rawValue }
}

/// Full configuration of a web-chat provider (plan Раздел 12 Блок 1 п.4).
struct WebProviderConfig: Identifiable, Codable, Equatable {
    let id: String
    var vendor: WebChatVendor
    var displayName: String
    var transport: WebTransport
    var chatURL: String
    var cookieStorePath: String?
    var systemPrompt: String
    var selectedModel: String
    var effort: WebEffort
    /// Delay between browser actions (anti-captcha/anti-ban), milliseconds.
    var toolCallDelayMs: Int
    /// Keep-alive ping interval to prevent session drop, seconds.
    var sessionKeepAliveSec: Int
    var autoLogin: Bool
    var headless: Bool
    /// Max tool-loop iterations per user message (anti-runaway).
    var maxToolIterations: Int
    /// Explicit acknowledgement that automating a 3rd-party web service may
    /// violate its ToS (required before enabling; plan Блок 1 п.9).
    var acknowledgedToS: Bool
    /// Real models parsed from the vendor's web UI model dropdown (plan Раздел
    /// 13 п.4). Empty until the driver discovers them; never hardcoded guesses.
    var discoveredModels: [String]
    /// Discovered effort/thinking levels from the vendor's web UI (plan Раздел 13 п.4).
    /// Empty until the driver discovers them.
    var discoveredEffortLevels: [WebEffort]
    /// CSS/XPath selector for the effort/thinking/reasoning dropdown (plan Раздел 13 п.4).
    /// If present, the driver will use this to discover/change effort levels.
    var effortDropdown: String?

    init(id: String = UUID().uuidString,
         vendor: WebChatVendor,
         displayName: String? = nil,
         transport: WebTransport = .playwrightMCP,
         chatURL: String? = nil,
         cookieStorePath: String? = nil,
         systemPrompt: String = "",
         selectedModel: String? = nil,
         effort: WebEffort = .medium,
         toolCallDelayMs: Int = 800,
         sessionKeepAliveSec: Int = 120,
         autoLogin: Bool = false,
         headless: Bool = false,
         maxToolIterations: Int = 25,
         acknowledgedToS: Bool = false,
         discoveredModels: [String] = [],
         discoveredEffortLevels: [WebEffort] = [],
         effortDropdown: String? = nil) {
        self.id = id
        self.vendor = vendor
        self.displayName = displayName ?? vendor.displayName
        self.transport = transport
        self.chatURL = chatURL ?? vendor.defaultChatURL
        self.cookieStorePath = cookieStorePath
        self.systemPrompt = systemPrompt
        self.selectedModel = selectedModel ?? vendor.defaultModels.first ?? ""
        self.effort = effort
        self.toolCallDelayMs = toolCallDelayMs
        self.sessionKeepAliveSec = sessionKeepAliveSec
        self.autoLogin = autoLogin
        self.headless = headless
        self.maxToolIterations = maxToolIterations
        self.acknowledgedToS = acknowledgedToS
        self.discoveredModels = discoveredModels
        self.discoveredEffortLevels = discoveredEffortLevels
        self.effortDropdown = effortDropdown
    }

    /// A web provider is usable only when the user has acknowledged the ToS
    /// caveat (model is chosen later in the chat input, not in settings).
    var isReady: Bool { acknowledgedToS }
}

/// Persistence for web providers (plan Раздел 12 Блок 1 п.7).
enum WebProviderStore {
    static let storageKey = "com.micoder.webProviders"

    static func save(_ providers: [WebProviderConfig], defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(providers) {
            defaults.set(data, forKey: storageKey)
        }
    }

    static func load(defaults: UserDefaults = .standard) -> [WebProviderConfig] {
        guard let data = defaults.data(forKey: storageKey),
              let providers = try? JSONDecoder().decode([WebProviderConfig].self, from: data) else {
            return []
        }
        return providers
    }

    static func upsert(_ config: WebProviderConfig, in providers: [WebProviderConfig]) -> [WebProviderConfig] {
        var result = providers
        if let idx = result.firstIndex(where: { $0.id == config.id }) {
            result[idx] = config
        } else {
            result.append(config)
        }
        return result
    }
}
