import SwiftUI

enum SpoilerExpandLogic {
    static let contentMaxHeight: CGFloat = 280

    static var animation: Animation {
        .spring(response: 0.28, dampingFraction: 0.9)
    }

    /// Height fits the measured content; caps at max, falls back to max until measured.
    static func contentHeight(isExpanded: Bool, measuredHeight: CGFloat) -> CGFloat {
        guard isExpanded else { return 0 }
        guard measuredHeight > 0 else { return contentMaxHeight }
        return min(measuredHeight, contentMaxHeight)
    }

    static func contentOpacity(isExpanded: Bool) -> Double {
        isExpanded ? 1 : 0
    }
}
