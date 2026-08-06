import SwiftUI
import AppKit

/// Independent MiCoder code-and-spark mark.
struct MiCoderLogoMark: View {
    var size: CGFloat = 140

    var body: some View {
        Group {
            if let image = MiCoderLogoLoader.image {
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
        .accessibilityLabel(MiCoderLogoSpec.markText)
    }
}

enum MiCoderLogoLoader {
    static let resourceName = "MiCoderLogo"

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
        guard let url = resourceBundle.url(forResource: resourceName, withExtension: "svg") else {
            return NSImage(named: NSImage.Name(resourceName))
        }
        return NSImage(contentsOf: url)
    }
}
