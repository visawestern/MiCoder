import Foundation

/// Resolves how an outgoing message should be delivered based on the currently
/// selected provider, so sending adapts to web / local / custom / ACP / serve
/// providers instead of only the MiMo Serve path (fixes the "message sends
/// nothing" bug). Pure/testable — the send code executes the resolved route.
enum SendRoute: Equatable {
    /// ACP-compatible provider (handled by ACPClient).
    case acp
    /// Built-in MiMo Serve transport.
    case mimoServe
    /// OpenAI-compatible HTTP endpoint (Ollama/OpenCode/custom OpenAI providers).
    case openAICompatible(baseURL: String, apiKey: String?, model: String)
    /// Web-chat provider driven through the browser (WebChatDriver).
    case web(configID: String)
    /// Nothing usable selected.
    case none
}

enum SendRouteResolver {
    /// Determine the route for the selected provider id.
    static func route(
        selectedProviderID: String,
        selectedModel: String,
        serverConnected: Bool,
        isACP: Bool,
        customProviders: [CustomProvider],
        localProviders: [LocalProviderConfig],
        webProviderIDs: [String]
    ) -> SendRoute {
        // 1) Web provider (option id "web:<id>").
        if let webID = WebProviderConnectivity.configID(fromOptionID: selectedProviderID),
           webProviderIDs.contains(webID) {
            return .web(configID: webID)
        }
        // 2) Local provider (Ollama/OpenCode/MiMo CLI) → OpenAI-compatible HTTP.
        //    Ollama and OpenCode (and generic OpenAI-compatible servers like
        //    LM Studio / vLLM detected as OpenCode) expose /v1/chat/completions;
        //    MiMo CLI serve uses its own base (audit P10).
        if let local = localProviders.first(where: { $0.id == selectedProviderID && $0.isEnabled }) {
            let base: String
            switch local.kind {
            case .ollama, .openCode: base = "\(local.serveBaseURL)/v1"
            case .localAgent: base = local.serveBaseURL
            }
            return .openAICompatible(baseURL: base, apiKey: nil, model: selectedModel)
        }
        // 3) ACP provider.
        if isACP { return .acp }
        // 4) Custom cloud provider (OpenAI-compatible) selected while serve is off
        //    or the provider has its own endpoint/key.
        if let custom = customProviders.first(where: { $0.id == selectedProviderID && $0.isEnabled }) {
            return .openAICompatible(baseURL: custom.baseURL,
                                     apiKey: custom.apiKey.isEmpty ? nil : custom.apiKey,
                                     model: selectedModel)
        }
        // 5) MiMo Serve when connected (server-provided providers).
        if serverConnected { return .mimoServe }
        return .none
    }

    /// Whether a route is ready to send without the MiMo Serve connection.
    static func requiresServer(_ route: SendRoute) -> Bool {
        if case .mimoServe = route { return true }
        return false
    }
}
