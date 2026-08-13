import Foundation

/// Built-in MiMo-Auto provider — always present, never deletable.
/// Connects directly to MiMo API without a local serve process.
struct MiMoAutoProvider: Identifiable, Codable, Equatable {
    static let builtInID = "mimo-auto"

    var id: String = MiMoAutoProvider.builtInID
    var isEnabled: Bool = true
    var apiKey: String = ""
    var selectedModel: String = "mimo-auto"

    var isFreeTier: Bool { apiKey.isEmpty }
    var displayName: String { "MiMo Auto" }
    var icon: String = "sparkles"
    var isBuiltIn: Bool { true }
    var isKeyValid: Bool = false
    var models: [MiMoAutoClient.MiMoModel] = [MiMoAutoClient.MiMoModel(id: "mimo-auto", isFree: true)]

    enum CodingKeys: String, CodingKey {
        case id, isEnabled, apiKey, selectedModel, isKeyValid, models
    }

    init() {}

    /// Fetch available models from MiMo API.
    /// Always includes "mimo-auto" as fallback so the user can always send messages.
    func refreshModels() async -> [MiMoAutoClient.MiMoModel] {
        let fallback = [MiMoAutoClient.MiMoModel(id: "mimo-auto", isFree: true)]
        do {
            let fetched = try await MiMoAutoClient.shared.listModels(apiKey: apiKey.isEmpty ? nil : apiKey)
            // Always keep mimo-auto even if API doesn't list it
            if fetched.contains(where: { $0.id == "mimo-auto" }) {
                return fetched
            }
            return fallback + fetched
        } catch {
            return fallback  // Always have mimo-auto available
        }
    }

    /// Validate the current API key.
    func validateKey() async -> Bool {
        guard !apiKey.isEmpty else { return true }  // Free tier always valid
        return await MiMoAutoClient.shared.validateApiKey(apiKey)
    }
}

/// Manages the built-in MiMo-Auto provider state.
final class MiMoAutoProviderStore: ObservableObject {
    static let shared = MiMoAutoProviderStore()

    @Published var provider = MiMoAutoProvider()

    private init() {
        Task { await refreshModels() }
    }

    /// Fetch and store updated models.
    /// Always keeps at least "mimo-auto" so the user can always send messages.
    @MainActor
    func refreshModels() async {
        let fetched = await provider.refreshModels()
        // Never let models be empty — mimo-auto must always be available
        provider.models = fetched.isEmpty ? [MiMoAutoClient.MiMoModel(id: "mimo-auto", isFree: true)] : fetched
    }

    /// Update the API key and revalidate.
    @MainActor
    func setApiKey(_ key: String) {
        provider.apiKey = key
        Task {
            provider.isKeyValid = await provider.validateKey()
            await refreshModels()
        }
    }

    /// Select a model.
    @MainActor
    func selectModel(_ modelID: String) {
        guard provider.models.contains(where: { $0.id == modelID }) else { return }
        provider.selectedModel = modelID
    }

    /// Stream a chat completion.
    func streamChat(
        messages: [MiMoAutoClient.MiMoMessage]
    ) -> AsyncThrowingStream<String, Error> {
        MiMoAutoClient.shared.chatCompletion(
            model: provider.selectedModel,
            messages: messages,
            apiKey: provider.apiKey.isEmpty ? nil : provider.apiKey,
            stream: true
        )
    }
}
