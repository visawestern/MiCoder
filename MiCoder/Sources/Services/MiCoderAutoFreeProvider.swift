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
    var isModelLocked: Bool = false
    var systemPrompt: String = ""

    var isFreeTier: Bool { MiCoderAutoFreeClient.isEligibleFreeModel(selectedModel) }
    var displayName: String { "MiCoder Auto Free" }
    var icon: String = "sparkles"
    var isBuiltIn: Bool { true }

    /// True only when the anonymous free catalog contains at least one trusted model.
    var isCatalogReady: Bool = false
    var models: [MiCoderAutoFreeClient.Model] = []
    var lastCatalogRefresh: Date?
    var modelStatuses: [String: String] = [:]
    var consecutiveFailures: Int = 0
    var statusMessage: String = ""

    enum CodingKeys: String, CodingKey {
        case id, isEnabled, selectedModel, isModelLocked, systemPrompt, models
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
        restored.isModelLocked = UserDefaults.standard.bool(forKey: "com.micoder.autoFree.locked")
        restored.systemPrompt = UserDefaults.standard.string(forKey: "com.micoder.autoFree.systemPrompt") ?? ""
        provider = restored
        Task { await refreshModels() }
    }

    @discardableResult
    func refreshModels() async -> Bool {
        do {
            let previousStatus = provider.statusMessage
            let previousSelectedModel = provider.selectedModel
            let fetched = try await MiCoderAutoFreeClient.shared.listModels()
            applyCatalog(fetched)
            provider.lastCatalogRefresh = Date()
            provider.statusMessage = MiCoderAutoFreeCatalogStatusLogic.statusAfterRefresh(
                previousStatus: previousStatus,
                previousSelectedModel: previousSelectedModel,
                currentSelectedModel: provider.selectedModel,
                fetchedModelIDs: fetched.map(\.id)
            )
            return true
        } catch {
            // Keep the last known free catalog during a transient discovery
            // failure. It still gives the send path a chance to fail over.
            provider.isCatalogReady = !provider.models.isEmpty
            provider.statusMessage = error.localizedDescription
            return false
        }
    }

    /// Manual model choice (settings list, API control, user tap). Pins the
    /// model so in-chat failover never overrides it — unlock explicitly via
    /// the lock toggle to re-enable automatic fallback.
    func selectModel(_ modelID: String) {
        guard provider.models.contains(where: { $0.id == modelID }) else { return }
        provider.selectedModel = modelID
        provider.modelStatuses[modelID] = "Healthy"
        provider.isModelLocked = true
        provider.consecutiveFailures = 0
        provider.statusMessage = "Pinned to \(modelID). Automatic fallback is off."
        defaults.set(modelID, forKey: "com.micoder.autoFree.model")
        defaults.set(true, forKey: "com.micoder.autoFree.locked")
    }

    /// Lock-preserving mirror of the app-level selection for the send path.
    /// Called on every chat send — must NOT touch isModelLocked, otherwise a
    /// manually pinned model would be silently unpinned mid-conversation and
    /// failover would override the user's choice.
    func syncModel(_ modelID: String) {
        guard !modelID.isEmpty,
              provider.models.contains(where: { $0.id == modelID }),
              provider.selectedModel != modelID else { return }
        provider.selectedModel = modelID
        provider.modelStatuses[modelID] = "Healthy"
        provider.statusMessage = "Using \(modelID)."
        defaults.set(modelID, forKey: "com.micoder.autoFree.model")
    }

    func modelStatus(for modelID: String) -> String {
        if provider.selectedModel == modelID {
            return provider.isModelLocked ? "Pinned" : "Active · fallback eligible"
        }
        return provider.modelStatuses[modelID] ?? "Live · available"
    }

    func setModelLocked(_ locked: Bool) {
        guard provider.models.contains(where: { $0.id == provider.selectedModel }) else { return }
        provider.isModelLocked = locked
        provider.statusMessage = locked
            ? "Locked to \(provider.selectedModel). Automatic fallback is off."
            : "Unlocked \(provider.selectedModel). Automatic fallback is on."
        defaults.set(locked, forKey: "com.micoder.autoFree.locked")
    }

    func setSystemPrompt(_ prompt: String) {
        provider.systemPrompt = prompt
        defaults.set(prompt, forKey: "com.micoder.autoFree.systemPrompt")
    }

    func streamChat(
        messages: [MiCoderAutoFreeClient.Message]
    ) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                if provider.models.isEmpty {
                    _ = await refreshModels()
                }
                var attemptedModels = Set<String>()
                var currentModel = provider.selectedModel
                if !provider.models.contains(where: { $0.id == currentModel }) {
                    guard !provider.isModelLocked,
                          let replacement = provider.models.first else {
                        continuation.finish(throwing: MiCoderAutoFreeError.noFreeModels)
                        return
                    }
                    let previous = currentModel
                    currentModel = replacement.id
                    provider.selectedModel = currentModel
                    provider.statusMessage = "Previously selected model \(previous) is unavailable; switched to \(currentModel)."
                    defaults.set(currentModel, forKey: "com.micoder.autoFree.model")
                    NotificationCenter.default.post(
                        name: .miCoderAutoFreeModelSwitched,
                        object: nil,
                        userInfo: ["fromModel": previous, "toModel": currentModel, "reason": "model unavailable"]
                    )
                }
                while true {
                    let modelParameters = ModelCallParametersStore.parameters(for: currentModel)
                    var effectiveMessages = messages
                    let toolPreamble = MiCoderAutoFreeClient.toolUsagePreamble()
                    let systemPrompts = [
                        toolPreamble,
                        provider.systemPrompt,
                        modelParameters.systemPrompt ?? ""
                    ].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    for prompt in systemPrompts.reversed() {
                        effectiveMessages.insert(
                            MiCoderAutoFreeClient.Message(role: "system", content: prompt),
                            at: 0
                        )
                    }
                    do {
                        for try await chunk in MiCoderAutoFreeClient.shared.chatCompletion(
                            model: currentModel,
                            messages: effectiveMessages,
                            parameters: modelParameters,
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
                        if provider.isModelLocked {
                            provider.modelStatuses[currentModel] = "Rate limited / failed while pinned"
                            if let autoFreeError = error as? MiCoderAutoFreeError,
                               case .rateLimited = autoFreeError {
                                provider.modelStatuses[currentModel] = "Rate limited"
                            }

                            provider.consecutiveFailures += 1
                            provider.statusMessage = "\(currentModel) failed while locked. Unlock the model to allow automatic fallback."
                            continuation.finish(throwing: error)
                            return
                        }
                        provider.consecutiveFailures += 1
                        let failureCount = provider.consecutiveFailures
                        provider.modelStatuses[currentModel] = Self.modelFailureStatus(for: error, failureCount: failureCount)
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
                        provider.modelStatuses[nextModel.id] = "Active · fallback eligible"
                        provider.consecutiveFailures = 0
                        provider.statusMessage = "Switched from \(currentModel) to \(nextModel.id): \(reason)"
                        NotificationCenter.default.post(
                            name: .miCoderAutoFreeModelSwitched,
                            object: nil,
                            userInfo: [
                                "fromModel": currentModel,
                                "toModel": nextModel.id,
                                "reason": reason
                            ]
                        )
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
        let liveIDs = Set(fetched.map(\.id))
        provider.modelStatuses = provider.modelStatuses.filter { liveIDs.contains($0.key) }
        provider.isCatalogReady = !fetched.isEmpty
        if !fetched.contains(where: { $0.id == provider.selectedModel }) {
            provider.isModelLocked = false
            provider.selectedModel = fetched.first?.id ?? MiCoderAutoFreeProvider.defaultModelID
            provider.statusMessage = fetched.isEmpty
                ? "No free OpenCode models are currently available."
                : "Previously selected model is unavailable; switched to \(provider.selectedModel)."
            defaults.set(provider.selectedModel, forKey: "com.micoder.autoFree.model")
            defaults.set(false, forKey: "com.micoder.autoFree.locked")
        }
    }

    private static func modelFailureStatus(for error: Error, failureCount: Int) -> String {
        if let autoFreeError = error as? MiCoderAutoFreeError,
           case .rateLimited = autoFreeError {
            return "Rate limited"
        }
        if let autoFreeError = error as? MiCoderAutoFreeError,
           case .modelUnavailable = autoFreeError {
            return "Unavailable"
        }
        return "Failed \(failureCount)/\(MiCoderAutoFreeClient.maxConsecutiveFailures)"
    }

    private static func switchReason(for error: Error, failureCount: Int) -> String {
        if let autoFreeError = error as? MiCoderAutoFreeError {
            switch autoFreeError {
            case .rateLimited:
                return "rate limit"
            case .modelUnavailable:
                return "model unavailable"
            case .apiError(let message):
                return MiCoderAutoFreeFailoverLogic.reason(
                    errorDescription: message,
                    failureCount: failureCount
                )
            default:
                break
            }
        }
        return MiCoderAutoFreeFailoverLogic.reason(
            errorDescription: error.localizedDescription,
            failureCount: failureCount
        )
    }
}
