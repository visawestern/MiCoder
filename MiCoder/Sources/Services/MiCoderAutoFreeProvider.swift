import Foundation

/// Built-in OpenCode Zen free-model provider for MiCoder.
/// The live anonymous catalog is intersected with a trusted list of temporary
/// free models; no paid model is selected automatically.
struct MiCoderAutoFreeProvider: Identifiable, Codable, Equatable {
    static let builtInID = "micoder-auto-free"
    static let defaultModelID = MiCoderAutoFreeClient.defaultModelID

    var id: String = MiCoderAutoFreeProvider.builtInID
    var isEnabled: Bool = true
    var selectedModel: String = MiCoderAutoFreeProvider.defaultModelID
    var systemPrompt: String = ""

    var isFreeTier: Bool { MiCoderAutoFreeClient.freeModelIDs.contains(selectedModel) }
    var displayName: String { "MiCoder Auto Free" }
    var icon: String = "sparkles"
    var isBuiltIn: Bool { true }

    /// True only when the anonymous free catalog contains at least one trusted model.
    var isCatalogReady: Bool = false
    var models: [MiCoderAutoFreeClient.Model] = []
    var consecutiveFailures: Int = 0
    var statusMessage: String = ""

    enum CodingKeys: String, CodingKey {
        case id, isEnabled, selectedModel, systemPrompt, models
    }

    init() {}

    func refreshModels() async -> [MiCoderAutoFreeClient.Model] {
        do {
            return try await MiCoderAutoFreeClient.shared.listModels()
        } catch {
            return []
        }
    }

    var isReady: Bool {
        isCatalogReady && !models.isEmpty
    }
}

/// Owns the anonymous OpenCode free provider state and performs model failover.
final class MiCoderAutoFreeStore: ObservableObject {
    static let shared = MiCoderAutoFreeStore()

    @Published var provider: MiCoderAutoFreeProvider
    private let defaults = UserDefaults.standard

    private init() {
        var restored = MiCoderAutoFreeProvider()
        restored.selectedModel = UserDefaults.standard.string(forKey: "com.micoder.autoFree.model")
            ?? MiCoderAutoFreeProvider.defaultModelID
        restored.systemPrompt = UserDefaults.standard.string(forKey: "com.micoder.autoFree.systemPrompt") ?? ""
        provider = restored
        Task { await refreshModels() }
    }

    @discardableResult
    func refreshModels() async -> Bool {
        do {
            let fetched = try await MiCoderAutoFreeClient.shared.listModels()
            applyCatalog(fetched)
            provider.statusMessage = "Anonymous OpenCode free catalog ready."
            return true
        } catch {
            // Keep the last known free catalog during a transient discovery
            // failure. It still gives the send path a chance to fail over.
            provider.isCatalogReady = !provider.models.isEmpty
            provider.statusMessage = error.localizedDescription
            return false
        }
    }

    func selectModel(_ modelID: String) {
        guard provider.models.contains(where: { $0.id == modelID }) else { return }
        provider.selectedModel = modelID
        provider.consecutiveFailures = 0
        provider.statusMessage = "Using \(modelID)."
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

        return AsyncThrowingStream { continuation in
            Task {
                var attemptedModels = Set<String>()
                var currentModel = provider.selectedModel
                while true {
                    do {
                        for try await chunk in MiCoderAutoFreeClient.shared.chatCompletion(
                            model: currentModel,
                            messages: effectiveMessages,
                            stream: true
                        ) {
                            continuation.yield(chunk)
                        }
                        provider.consecutiveFailures = 0
                        if provider.statusMessage.isEmpty || provider.statusMessage.hasPrefix("OpenCode model") {
                            provider.statusMessage = "Using \(currentModel)."
                        }
                        continuation.finish()
                        return
                    } catch {
                        provider.consecutiveFailures += 1
                        let failureCount = provider.consecutiveFailures
                        let switchNow = MiCoderAutoFreeClient.shouldSwitch(
                            for: error,
                            consecutiveFailures: failureCount
                        )

                        guard switchNow else {
                            provider.statusMessage = "\(currentModel) failed (\(failureCount)/\(MiCoderAutoFreeClient.maxConsecutiveFailures)). Retry to continue."
                            continuation.finish(throwing: error)
                            return
                        }

                        attemptedModels.insert(currentModel)
                        if provider.models.filter({ !attemptedModels.contains($0.id) }).isEmpty {
                            _ = await refreshModels()
                        }
                        guard let nextModel = provider.models.first(where: { !attemptedModels.contains($0.id) }) else {
                            provider.isCatalogReady = false
                            provider.statusMessage = "No free OpenCode models are currently available."
                            continuation.finish(throwing: error)
                            return
                        }

                        let reason = Self.switchReason(for: error, failureCount: failureCount)
                        provider.selectedModel = nextModel.id
                        provider.consecutiveFailures = 0
                        provider.statusMessage = "Switched from \(currentModel) to \(nextModel.id): \(reason)"
                        defaults.set(nextModel.id, forKey: "com.micoder.autoFree.model")
                        continuation.yield("\n\n[MiCoder Auto Free switched to \(nextModel.id): \(reason)]\n\n")
                        currentModel = nextModel.id
                    }
                }
            }
        }
    }

    private func applyCatalog(_ fetched: [MiCoderAutoFreeClient.Model]) {
        provider.models = fetched
        provider.isCatalogReady = !fetched.isEmpty
        if !fetched.contains(where: { $0.id == provider.selectedModel }) {
            provider.selectedModel = fetched.first?.id ?? MiCoderAutoFreeProvider.defaultModelID
            defaults.set(provider.selectedModel, forKey: "com.micoder.autoFree.model")
        }
    }

    private static func switchReason(for error: Error, failureCount: Int) -> String {
        if let autoFreeError = error as? MiCoderAutoFreeError {
            switch autoFreeError {
            case .rateLimited:
                return "rate limit"
            case .modelUnavailable:
                return "model unavailable"
            default:
                break
            }
        }
        return "\(failureCount) consecutive failures"
    }
}
