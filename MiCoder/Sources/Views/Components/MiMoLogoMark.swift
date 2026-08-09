import SwiftUI
import AppKit

/// Official Mi logo from `mimo-coder/assets/images/logo.png`.
struct MiMoLogoMark: View {
    var size: CGFloat = 140

    var body: some View {
        Group {
            if let image = MiMoLogoLoader.image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
            } else {
                Color.clear
            }
        }
        .scaledToFit()
        .frame(width: size, height: size)
        .accessibilityLabel(MiMoLogoSpec.markText)
    }
}

enum MiMoLogoLoader {
    static let resourceName = "MiLogo"

    /// The bundle used to locate resource files.
    ///
    /// `Bundle.module` crashes on executable targets (assertion failure in the
    /// lazy initializer of `NSBundle.module`).  We therefore default to
    /// `Bundle.main`, which is correct for the production .app.
    ///
    /// Test suites set this to `Bundle.module` before exercising resource
    /// loading (see `ChatPanelLayoutTests`).
    static var resourceBundle: Bundle = .main

    static var image: NSImage? {
        guard let url = resourceBundle.url(forResource: resourceName, withExtension: "png") else {
            return NSImage(named: NSImage.Name(resourceName))
        }
        return NSImage(contentsOf: url)
    }
}

enum MiMoLogoSpec {
    static let markText = "Mi logo"
}
