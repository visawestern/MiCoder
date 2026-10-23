import Foundation

/// Guards the one-shot coder prompt: it may be sent only after the target chat
/// is selected, its history is fully applied, and no request is in flight.
enum SpecNodePromptFlushLogic {
    static func shouldFlush(pendingSessionID: String?,
                            selectedSessionID: String?,
                            currentSessionID: String?,
                            loadedSessionID: String?,
                            isLoadingMessages: Bool,
                            isBusy: Bool) -> Bool {
        guard let pendingSessionID else { return false }
        return pendingSessionID == selectedSessionID
            && pendingSessionID == currentSessionID
            && pendingSessionID == loadedSessionID
            && !isLoadingMessages
            && !isBusy
    }
}
