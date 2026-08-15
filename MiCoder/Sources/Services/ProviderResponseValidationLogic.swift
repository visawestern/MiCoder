import Foundation

enum ProviderResponseValidationLogic {
    static func hasVisibleContent(_ content: String?) -> Bool {
        guard let content else { return false }
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
