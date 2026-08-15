import Foundation

enum UndoActionResult: Equatable {
    case undone
    case nothingToUndo
    case failed(String)
}

enum UndoActionFeedbackLogic {
    static func message(for result: UndoActionResult) -> String {
        switch result {
        case .undone:
            return "Last file change undone."
        case .nothingToUndo:
            return "Nothing to undo."
        case .failed(let reason):
            return "Undo failed: \(reason)"
        }
    }
}
