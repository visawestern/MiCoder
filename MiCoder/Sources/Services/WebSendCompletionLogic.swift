import Foundation

enum WebSendCompletionLogic {
    static func recordsCompletion(for event: WebChatEvent) -> Bool {
        guard case .final(let text) = event else { return false }
        return ProviderResponseValidationLogic.hasVisibleContent(text)
    }
}
