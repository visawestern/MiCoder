import Foundation

enum WebCaptchaPresentationAction: Equatable {
    case showSolver
    case dismissSolver
    case none
}

enum WebCaptchaPresentationLogic {
    static func action(for event: WebChatEvent) -> WebCaptchaPresentationAction {
        switch event {
        case .captchaDetected:
            return .showSolver
        case .final, .error, .loggedOut:
            return .dismissSolver
        default:
            return .none
        }
    }
}
