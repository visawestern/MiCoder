/// Atomic state transition for a completed web-model discovery refresh.
/// A refresh result is authoritative for auto-discovered models: stale entries
/// must not survive an empty or changed live snapshot. Explicit manual models
/// remain separate in `WebProviderConfig.manuallyAddedModels`.
enum WebModelRefreshLogic {
    static func replacing(config: WebProviderConfig,
                          with discoveredModels: [WebProviderModel]) -> WebProviderConfig {
        var updated = config
        var seen = Set<String>()
        let liveModels = discoveredModels.compactMap { original -> WebProviderModel? in
            guard let normalized = WebModelListParser.normalize(original.name, vendor: config.vendor),
                  seen.insert(normalized.lowercased()).inserted else { return nil }
            var model = original
            model.name = normalized
            model.discoveryStatus = .active
            model.isLiveDiscovered = true
            model.isSelectable = true
            return model
        }

        updated.discoveredModels = liveModels
        updated.discoveredEffortLevels = Array(Set(liveModels.flatMap(\.availableEfforts)))
            .sorted { $0.rawValue < $1.rawValue }
        updated.selectedModel = updated.allModels.first ?? ""
        return updated
    }
}
