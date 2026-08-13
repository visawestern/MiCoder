import Foundation

enum SendReadinessLogic {
    /// Проверяет, требуется ли подключение к MiMo Serve для отправки.
    /// Если выбран кастомный провайдер с API-ключом — сервер не обязателен.
    static func connectionValidationError(
        serverConnected: Bool,
        selectedProviderID: String = "",
        mimoAutoReady: Bool = true,
        customProviders: [CustomProvider] = [],
        localProviderIDs: [String] = [],
        webProviderIDs: [String] = []
    ) -> String? {
        // MiMo Auto is a direct route and must be checked independently from
        // the local MiMo Serve connection.
        if selectedProviderID == MiMoAutoProvider.builtInID && !mimoAutoReady {
            return "MiMo Auto is unavailable. The free Xiaomi channel has ended; add a Xiaomi MiMo API key or choose another provider."
        }

        // For all other routes, a connected local server is sufficient.
        if serverConnected { return nil }

        if !selectedProviderID.isEmpty {
            if selectedProviderID == MiMoAutoProvider.builtInID {
                return nil
            }
            // Web provider (option id "web:<id>") — driven via the browser, no serve.
            if let webID = WebProviderConnectivity.configID(fromOptionID: selectedProviderID),
               webProviderIDs.contains(webID) { return nil }
            // Local provider (Ollama/OpenCode/MiMo CLI) — own HTTP endpoint, no serve.
            if localProviderIDs.contains(selectedProviderID) { return nil }
            // Custom provider — its own endpoint; serve not required, unless it
            // requires an API key that hasn't been provided.
            if let custom = customProviders.first(where: { $0.id == selectedProviderID && $0.isEnabled }) {
                if custom.requiresAPIKey && custom.apiKey.isEmpty {
                    return "This provider requires an API key. Add it in Settings."
                }
                return nil
            }
        }

        return "No provider is ready. Connect the local agent, add a custom provider, configure a local model, or connect a web provider."
    }

    static func sendValidationError(modelID: String, providerID: String?) -> String? {
        let trimmedModel = modelID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedModel.isEmpty else {
            return "Select a model before sending."
        }
        guard let providerID, !providerID.isEmpty else {
            return "Select a provider for this model."
        }
        return nil
    }

    static func canSendMessage(
        text: String,
        images: [ClipboardImage],
        files: [FileInfo],
        modelID: String,
        providerID: String?,
        serverConnected: Bool = false,
        mimoAutoReady: Bool = true,
        customProviders: [CustomProvider] = [],
        localProviderIDs: [String] = [],
        webProviderIDs: [String] = []
    ) -> Bool {
        MessageSendValidation.canSend(text: text, images: images, files: files)
            && sendValidationError(modelID: modelID, providerID: providerID) == nil
            && connectionValidationError(
                serverConnected: serverConnected,
                selectedProviderID: providerID ?? "",
                mimoAutoReady: mimoAutoReady,
                customProviders: customProviders,
                localProviderIDs: localProviderIDs,
                webProviderIDs: webProviderIDs
            ) == nil
    }
}

/// Human-readable reason a send is blocked, for showing the user WHY the send
/// button is disabled (Round 8 P1 — the old UI disabled the button silently).
enum SendReadinessReason {
    /// Returns the FIRST blocking condition as an actionable message, or nil
    /// when the send is ready. The UI surfaces this instead of a silent no-op.
    static func reason(
        text: String,
        images: [ClipboardImage],
        files: [FileInfo],
        modelID: String,
        providerID: String?,
        serverConnected: Bool,
        mimoAutoReady: Bool = true,
        customProviders: [CustomProvider],
        localProviderIDs: [String],
        webProviderIDs: [String]
    ) -> String? {
        // Empty input blocks send with an actionable message (Round 8 P1: the
        // disabled button must explain WHY). Visibility is gated by the UI
        // (InputViews.displayedReason), not by hiding the reason here.
        if !MessageSendValidation.canSend(text: text, images: images, files: files) {
            return "Type a message or attach a file to send."
        }
        if let error = SendReadinessLogic.sendValidationError(modelID: modelID, providerID: providerID) {
            return error
        }
        return SendReadinessLogic.connectionValidationError(
            serverConnected: serverConnected,
            selectedProviderID: providerID ?? "",
            mimoAutoReady: mimoAutoReady,
            customProviders: customProviders,
            localProviderIDs: localProviderIDs,
            webProviderIDs: webProviderIDs
        )
    }
}
