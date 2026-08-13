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
    var models: [MiMoAutoClient.MiMoModel] = []

    enum CodingKeys: String, CodingKey {
        case id, isEnabled, apiKey, selectedModel, isKeyValid, models
    }

    init() {}

    /// Fetch models from the selected route. The free route is not represented
    /// as a model unless its channel is actually available.
    func refreshModels() async -> [MiMoAutoClient.MiMoModel] {
        if apiKey.isEmpty {
            let ready = await MiMoAutoClient.shared.validateFreeChannel()
            return ready ? [MiMoAutoClient.MiMoModel(id: "mimo-auto", isFree: true)] : []
        }
        do {
            return try await MiMoAutoClient.shared.listModels(apiKey: apiKey)
        } catch {
            return []
        }
    }

    /// Validate the current paid API key. An empty key is not a successful
    /// readiness result; it must pass the free-channel check instead.
    func validateKey() async -> Bool {
        guard !apiKey.isEmpty else { return false }
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

    /// Fetch models and verify the actual route used by the provider.
    @MainActor
    func refreshModels() async {
        let fetched = await provider.refreshModels()
        provider.isKeyValid = !fetched.isEmpty
        provider.models = fetched
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
