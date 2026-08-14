import Foundation

enum WebDetectionStatusLogic {
    static func statusText(modelCount: Int) -> String {
        modelCount > 0
            ? "MiCoder detected \(modelCount) models"
            : "MiCoder will detect models after login"
    }
}
