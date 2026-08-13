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

    /// Models from catalog data (`web_providers_catalog.json`), never hardcoded
    /// in code. Empty when a vendor has no stable list (e.g. ChatGPT — models
    /// change frequently) until live discovery fills them in.
    var defaultModels: [String] {
        (try? WebProviderCatalog.loadBundled().models(for: id)) ?? []
    }
}

/// Effort/thinking level mapped to each vendor's toggle (plan Блок 1 п.6).
enum WebEffort: String, Codable, CaseIterable, Identifiable {
    case low, medium, high
    var id: String { rawValue }

    /// Display name for UI.
    var displayName: String {
        switch self {
        case .low: return L.t(AppLocalizationKey.locEffortLow)
        case .medium: return L.t(AppLocalizationKey.locEffortMedium)
        case .high: return L.t(AppLocalizationKey.locEffortHigh)
        }
    }

    /// Map a label string to a WebEffort.
    static func fromLabel(_ label: String) -> WebEffort? {
        let lower = label.lowercased()
        if lower.contains("low") || lower.contains("низк") || lower.contains("快") || lower == "fast" { return .low }
        if lower.contains("medium") || lower.contains("средн") || lower.contains("自动") || lower.contains("auto") { return .medium }
        if lower.contains("high") || lower.contains("высок") || lower.contains("深度") || lower.contains("thinking") || lower.contains("深思") { return .high }
        return nil
    }
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
/// A web provider model with its capabilities and available modes.
struct WebProviderModel: Codable, Equatable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let description: String?
    var availableModes: [String]      // ["auto", "think", "fast", "image"]
    var supportsImageGeneration: Bool
    var supportsDeepResearch: Bool
    var supportsWebDev: Bool

    init(name: String, description: String? = nil, availableModes: [String] = [],
         supportsImageGeneration: Bool = false, supportsDeepResearch: Bool = false,
         supportsWebDev: Bool = false) {
        self.name = name
        self.description = description
        self.availableModes = availableModes
        self.supportsImageGeneration = supportsImageGeneration
        self.supportsDeepResearch = supportsDeepResearch
        self.supportsWebDev = supportsWebDev
    }
}

/// A feature mode available for a web provider (e.g. Deep Research, Create Image).
struct FeatureMode: Codable, Equatable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let icon: String?
    let isEnabled: Bool

    init(name: String, icon: String? = nil, isEnabled: Bool = true) {
        self.name = name
        self.icon = icon
        self.isEnabled = isEnabled
    }
}

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
    var discoveredModels: [WebProviderModel]
    /// Manually added model names (not auto-detected).
    var manuallyAddedModels: [String]
    /// Discovered effort/thinking levels from the vendor's web UI (plan Раздел 13 п.4).
    /// Empty until the driver discovers them.
    var discoveredEffortLevels: [WebEffort]
    /// Discovered feature modes (Deep Research, Create Image, etc).
    var discoveredFeatureModes: [FeatureMode]
    /// CSS/XPath selector for the effort/thinking/reasoning dropdown (plan Раздел 13 п.4).
    /// If present, the driver will use this to discover/change effort levels.
    var effortDropdown: String?
    /// User-picked CSS selector for the model dropdown (element picker).
    /// Overrides catalog selector when set.
    var customModelSelector: String?

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
         discoveredModels: [WebProviderModel] = [],
         manuallyAddedModels: [String] = [],
         discoveredEffortLevels: [WebEffort] = [],
         discoveredFeatureModes: [FeatureMode] = [],
         effortDropdown: String? = nil,
         customModelSelector: String? = nil) {
        self.id = id
        self.vendor = vendor
        self.displayName = displayName ?? vendor.displayName
        self.transport = transport
        self.chatURL = chatURL ?? vendor.defaultChatURL
        self.cookieStorePath = cookieStorePath
        self.systemPrompt = systemPrompt
         self.selectedModel = selectedModel ?? ""
        self.effort = effort
        self.toolCallDelayMs = toolCallDelayMs
        self.sessionKeepAliveSec = sessionKeepAliveSec
        self.autoLogin = autoLogin
        self.headless = headless
        self.maxToolIterations = maxToolIterations
        self.acknowledgedToS = acknowledgedToS
        self.discoveredModels = discoveredModels
        self.manuallyAddedModels = manuallyAddedModels
        self.discoveredEffortLevels = discoveredEffortLevels
        self.discoveredFeatureModes = discoveredFeatureModes
        self.effortDropdown = effortDropdown
        self.customModelSelector = customModelSelector
    }

    /// A web provider is usable only when the user has acknowledged the ToS
    /// caveat (model is chosen later in the chat input, not in settings).
    var isReady: Bool { true }

    /// All models: auto-detected + explicitly configured. Vendor catalog data is
    /// intentionally not included because it goes stale independently of login.
    var allModels: [String] {
        var names = discoveredModels.map { $0.name }
        names.append(contentsOf: manuallyAddedModels)
        return Array(Set(names)).sorted()
    }

    /// Add a custom model name to the provider's model list.
    /// No-op if the name is empty or already present (dedup by exact match).
    mutating func addCustomModel(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !allModels.contains(trimmed) else { return }
        manuallyAddedModels.append(trimmed)
    }

    /// Remove a custom model from the provider's model list.
    mutating func removeCustomModel(_ name: String) {
        manuallyAddedModels.removeAll { $0 == name }
    }
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
