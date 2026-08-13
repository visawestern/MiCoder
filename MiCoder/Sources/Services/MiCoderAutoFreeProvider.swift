import Foundation

/// Built-in OpenCode Zen free-model provider for MiCoder.
/// It uses the temporary free `big-pickle` model when the user's OpenCode Zen
/// API key and current model catalog confirm that it is available.
struct MiCoderAutoFreeProvider: Identifiable, Codable, Equatable {
    static let builtInID = "micoder-auto-free"
    static let defaultModelID = MiCoderAutoFreeClient.defaultModelID

    var id: String = MiCoderAutoFreeProvider.builtInID
    var isEnabled: Bool = true
    var apiKey: String = ""
    var selectedModel: String = MiCoderAutoFreeProvider.defaultModelID
    var systemPrompt: String = ""

    var isFreeTier: Bool { selectedModel == Self.defaultModelID }
    var displayName: String { "MiCoder Auto Free" }
    var icon: String = "sparkles"
    var isBuiltIn: Bool { true }
    var isKeyValid: Bool = false
    var models: [MiCoderAutoFreeClient.Model] = []

    enum CodingKeys: String, CodingKey {
        case id, isEnabled, apiKey, selectedModel, systemPrompt, isKeyValid, models
    }

    init() {}

    func refreshModels() async -> [MiCoderAutoFreeClient.Model] {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        do {
            return try await MiCoderAutoFreeClient.shared.listModels(apiKey: apiKey)
        } catch {
            return []
        }
    }

    func validateKey() async -> Bool {
        await MiCoderAutoFreeClient.shared.validateApiKey(apiKey)
    }
}

/// Owns the built-in OpenCode Zen free provider state and persists its settings.
final class MiCoderAutoFreeStore: ObservableObject {
    static let shared = MiCoderAutoFreeStore()

    @Published var provider: MiCoderAutoFreeProvider
    private let defaults = UserDefaults.standard

    private init() {
        var restored = MiCoderAutoFreeProvider()
        restored.apiKey = UserDefaults.standard.string(forKey: "com.micoder.autoFree.apiKey")
            ?? UserDefaults.standard.string(forKey: "com.micoder.mimoAuto.apiKey")
            ?? ""
        restored.selectedModel = UserDefaults.standard.string(forKey: "com.micoder.autoFree.model")
            ?? MiCoderAutoFreeProvider.defaultModelID
        restored.systemPrompt = UserDefaults.standard.string(forKey: "com.micoder.autoFree.systemPrompt") ?? ""
        provider = restored
        Task { await refreshModels() }
    }

    func refreshModels() async {
        let fetched = await provider.refreshModels()
        provider.isKeyValid = !fetched.isEmpty
        provider.models = fetched
        if !fetched.contains(where: { $0.id == provider.selectedModel }) {
            provider.selectedModel = fetched.first?.id ?? MiCoderAutoFreeProvider.defaultModelID
        }
    }

    func setApiKey(_ key: String) {
        provider.apiKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(provider.apiKey, forKey: "com.micoder.autoFree.apiKey")
        Task { await refreshModels() }
    }

    func selectModel(_ modelID: String) {
        guard provider.models.contains(where: { $0.id == modelID }) else { return }
        provider.selectedModel = modelID
        defaults.set(modelID, forKey: "com.micoder.autoFree.model")
    }

    func setSystemPrompt(_ prompt: String) {
        provider.systemPrompt = prompt
        defaults.set(prompt, forKey: "com.micoder.autoFree.systemPrompt")
    }

    func streamChat(
        messages: [MiCoderAutoFreeClient.Message]
    ) -> AsyncThrowingStream<String, Error> {
        var effectiveMessages = messages
        if !provider.systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            effectiveMessages.insert(
                MiCoderAutoFreeClient.Message(role: "system", content: provider.systemPrompt),
                at: 0
            )
        }
        return MiCoderAutoFreeClient.shared.chatCompletion(
            model: provider.selectedModel,
            messages: effectiveMessages,
            apiKey: provider.apiKey,
            stream: true
        )
    }
}
