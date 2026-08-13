/// Canonical selection contract for browser-backed providers.
/// The composer and the WebChatDriver must consume the same persisted model and effort.
enum WebProviderSelectionLogic {
    static func selectedModel(for config: WebProviderConfig, availableModels: [String]? = nil) -> String {
        let models = availableModels ?? config.allModels
        if models.contains(config.selectedModel) {
            return config.selectedModel
        }
        return models.first ?? config.selectedModel
    }

    static func selectingModel(_ modelID: String,
                               in config: WebProviderConfig,
                               availableModels: [String]? = nil) -> WebProviderConfig {
        guard !modelID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return config }
        let models = availableModels ?? config.allModels
        guard models.contains(modelID) else { return config }
        var updated = config
        updated.selectedModel = modelID
        return updated
    }

    static func availableEfforts(for config: WebProviderConfig) -> [WebEffort] {
        if !config.discoveredEffortLevels.isEmpty {
            return config.discoveredEffortLevels
        }
        // The exact effort control is vendor-page state, not a universal
        // capability. Do not expose synthetic levels before live discovery.
        return []
    }

    static func selectingEffort(_ effort: WebEffort,
                                in config: WebProviderConfig) -> WebProviderConfig {
        guard availableEfforts(for: config).contains(effort) else { return config }
        var updated = config
        updated.effort = effort
        return updated
    }
}
