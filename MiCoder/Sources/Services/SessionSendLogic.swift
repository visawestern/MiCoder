import Foundation

enum SessionSendLogic {
    /// Returns true when a new server session must be created before sending.
    static func shouldCreateNewSession(selectedSessionID: String?) -> Bool {
        guard let id = selectedSessionID else { return true }
        return id.isEmpty
    }

    /// Resolves which session ID to use for the outgoing message.
    static func resolvedSessionID(selectedSessionID: String?, newlyCreatedID: String) -> String {
        if let id = selectedSessionID, !id.isEmpty {
            return id
        }
        return newlyCreatedID
    }

    /// Maps agent mode to MiMo Serve agent field.
    static func sendMode(for agentMode: AgentMode) -> String {
        switch agentMode {
        case .build: return "build"
        case .plan: return "plan"
        case .compose: return "compose"
        }
    }

    static func buildSendOptions(
        agentMode: AgentMode,
        selectedVariant: String?,
        modelID: String,
        selectedProviderID: String,
        providers: [MimoProviderResponse],
        customProviders: [CustomProvider],
        messageID: String? = nil,
        accessLevel: AccessLevel? = nil
    ) -> MessageSendOptions {
        let agent = sendMode(for: agentMode)
        let providerID = ProviderSettingsLogic.resolveProviderID(
            for: modelID,
            selectedProviderID: selectedProviderID,
            in: providers,
            customProviders: customProviders
        )
        let variant = ProviderSettingsLogic.normalizedVariant(
            selectedVariant,
            for: modelID,
            in: providers,
            providerID: providerID,
            customProviders: customProviders
        )

        return MessageSendOptions(
            agent: agent,
            modelID: modelID.isEmpty ? nil : modelID,
            providerID: providerID,
            variant: variant,
            messageID: messageID,
            permission: accessLevel.flatMap { AccessLevelPermissionLogic.permissionPatch(for: $0) as? [String: String] }
        )
    }

    static func restoreSelections(from messages: [MimoMessageResponse]) -> SessionSendSelections? {
        guard let lastUser = messages.reversed().first(where: { $0.info?.role == "user" }) else {
            return nil
        }
        let modelID = lastUser.info?.modelID ?? lastUser.info?.model?.modelID
        let providerID = lastUser.info?.providerID ?? lastUser.info?.model?.providerID
        return SessionSendSelections(
            agentMode: agentMode(from: lastUser.info?.agent),
            providerID: providerID,
            modelID: modelID,
            variant: lastUser.info?.variant ?? lastUser.info?.model?.variant
        )
    }

    static func agentMode(from agent: String?) -> AgentMode? {
        switch agent?.lowercased() {
        case "build": return .build
        case "plan": return .plan
        case "compose": return .compose
        default: return nil
        }
    }

    /// Reconciles local assistant message ID with server-assigned ID.
    static func reconcileAssistantMessageID(localID: String?, serverID: String) -> String {
        if let local = localID, !local.isEmpty, local != serverID {
            return serverID
        }
        return serverID
    }

    static func assistantResponse(from messages: [MimoMessageResponse]) -> MimoMessageResponse? {
        messages.last { $0.info?.role == "assistant" }
    }

    static func shouldAwaitSSE(
        responseMessages: [MimoMessageResponse],
        hasPendingQuestion: Bool
    ) -> Bool {
        !hasPendingQuestion && assistantResponse(from: responseMessages) == nil
    }

    static func workedDurationLabel(since start: Date, until end: Date = Date()) -> String {
        let seconds = max(1, Int(end.timeIntervalSince(start)))
        if seconds < 60 { return "Worked for \(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "Worked for \(minutes)m \(seconds % 60)s" }
        let hours = minutes / 60
        return "Worked for \(hours)h \(minutes % 60)m"
    }
}

struct SessionSendSelections: Equatable {
    let agentMode: AgentMode?
    let providerID: String?
    let modelID: String?
    let variant: String?
}
