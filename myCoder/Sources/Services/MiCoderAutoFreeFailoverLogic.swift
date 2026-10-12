import Foundation

enum MiCoderAutoFreeFailoverLogic {
    static func reason(errorDescription: String, failureCount: Int) -> String {
        let lower = errorDescription.lowercased()
        if lower.contains("429") || lower.contains("rate limit") || lower.contains("ratelimit") {
            return "rate limit"
        }
        if lower.contains("model") && (lower.contains("unavailable") || lower.contains("not found") || lower.contains("failed")) {
            return "model unavailable"
        }
        return "\(failureCount) consecutive failures"
    }
}
