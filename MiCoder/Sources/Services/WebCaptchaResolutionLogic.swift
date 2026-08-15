import Foundation

enum WebCaptchaResolutionAction: Equatable {
    case wait
    case resume
    case abort
}

enum WebCaptchaResolutionLogic {
    static func action(for state: WebSessionState) -> WebCaptchaResolutionAction {
        switch state {
        case .captchaRequired:
            return .wait
        case .connected:
            return .resume
        case .loggedOut:
            return .abort
        case .unknown:
            return .wait
        }
    }
}
