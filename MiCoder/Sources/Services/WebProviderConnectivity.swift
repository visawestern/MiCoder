import Foundation

/// Connectivity + selection logic for web providers in the chat input
/// (plan Раздел 13 п.4). A web provider counts as "connected" ONLY after a
/// session (cookies) has been captured — not merely added — and ToS accepted.
enum WebProviderConnectivity {
    /// Whether a web provider is connected: cookies persisted (non-empty,
    /// non-expired) AND ToS acknowledged.
    static func isConnected(_ config: WebProviderConfig,
                           homeDirectory: URL,
                           now: Date = Date()) -> Bool {
        guard config.acknowledgedToS else { return false }
        guard let store = WebSessionManager.restore(providerId: config.id, homeDirectory: homeDirectory) else {
            return false
        }
        guard !store.cookies.isEmpty else { return false }
        return !WebSessionManager.isExpired(store, now: now)
    }

    /// Chat-input provider options for connected web providers, so they appear
    /// alongside local/custom providers in the send-message provider selector.
    static func providerOptions(_ configs: [WebProviderConfig],
                               homeDirectory: URL,
                               now: Date = Date()) -> [ProviderOption] {
        configs
            .filter { isConnected($0, homeDirectory: homeDirectory, now: now) }
            .map { ProviderOption(id: "web:\($0.id)", name: "🌐 \($0.displayName)",
                                  isCustom: true, isConnected: true) }
    }

    /// The models offered by a web provider — REAL models parsed from the web
    /// UI when available (`WebProviderConfig.models` populated by the driver),
    /// never hardcoded guesses (plan Раздел 13 п.4). Falls back to the vendor's
    /// known default list only until real models are loaded.
    static func models(for config: WebProviderConfig) -> [String] {
        config.discoveredModels.isEmpty ? config.vendor.defaultModels : config.discoveredModels
    }

    /// Whether the given provider option id refers to a web provider.
    static func isWebProviderID(_ id: String) -> Bool { id.hasPrefix("web:") }

    /// Extract the WebProviderConfig id from an option id.
    static func configID(fromOptionID id: String) -> String? {
        guard id.hasPrefix("web:") else { return nil }
        return String(id.dropFirst("web:".count))
    }

    /// Connection summary shown once connected (plan Раздел 13 п.4).
    static func connectionSummary(_ config: WebProviderConfig, connected: Bool) -> String {
        guard connected else { return "Not connected — log in to capture a session." }
        let modelCount = models(for: config).count
        return "\(config.transport == .cdpCookies ? "Existing Chrome" : "Managed browser") · \(modelCount) models · delay \(config.toolCallDelayMs)ms"
    }
}
