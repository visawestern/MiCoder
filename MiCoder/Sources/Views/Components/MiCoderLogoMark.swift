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
        // Try SVG via CoreVector / PDF representation for crisp rendering
        guard let url = resourceBundle.url(forResource: resourceName, withExtension: "svg") else {
            return NSImage(named: NSImage.Name(resourceName))
        }
        // NSImage(contentsOf:) for SVG may return nil on macOS without QuickLook —
        // render via Core Graphics for reliability.
        guard let data = try? Data(contentsOf: url),
              let provider = CGDataProvider(data: data as CFData),
              let cgImage = CGImage(pngDataProviderSource: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
            // Fallback: try NSImage anyway
            return NSImage(contentsOf: url)
        }
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }
}
