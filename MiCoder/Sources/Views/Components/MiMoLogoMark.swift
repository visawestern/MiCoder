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
    /// SPM packages resources into `<Target>_<Product>.bundle`, which is NOT
    /// `Bundle.main` for an executable target. We locate it dynamically.
    static var resourceBundle: Bundle {
        // Prefer the SPM-generated resource bundle
        let candidates = [
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/MiCoder_MiCoder.bundle"),
            Bundle.main.bundleURL.appendingPathComponent("Resources/MiCoder_MiCoder.bundle"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Resources/MiCoder_MiCoder.bundle"),
        ]
        for url in candidates {
            let b = Bundle(url: url)
            if b?.url(forResource: resourceName, withExtension: "png") != nil {
                return b ?? .main
            }
        }
        // Fallback to main bundle
        return .main
    }

    static var image: NSImage? {
        let bundle = resourceBundle
        guard let url = bundle.url(forResource: resourceName, withExtension: "png") else {
            // Last resort: try NSImage(named:)
            return NSImage(named: NSImage.Name(resourceName))
        }
        return NSImage(contentsOf: url)
    }
}

enum MiMoLogoSpec {
    static let markText = "Mi logo"
}
