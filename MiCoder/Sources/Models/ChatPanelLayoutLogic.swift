import Foundation
import CoreGraphics
import SwiftUI

enum ChatPanelLayoutLogic {
    static let emptyStateStackSpacing: CGFloat = 24

    static func shouldUseCenteredInput(messageCount: Int) -> Bool {
        messageCount == 0
    }
}

enum MiMoLogoSpec {
    static let markText = "mi"
    static let accentHex = "FF6900"

    static var accentColor: Color {
        Color(red: 1, green: 0.412, blue: 0)
    }
}
