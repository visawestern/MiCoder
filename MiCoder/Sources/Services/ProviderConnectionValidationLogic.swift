import Foundation

enum ProviderConnectionValidationLogic {
    static func isValidModelsResponse(statusCode: Int, body: Data) -> Bool {
        guard (200..<300).contains(statusCode),
              let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            return false
        }

        let openAIIDs = (json["data"] as? [[String: Any]])?.compactMap { value -> String? in
            guard let id = value["id"] as? String else { return nil }
            let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        } ?? []
        let namedModels = (json["models"] as? [[String: Any]])?.compactMap { value -> String? in
            let raw = (value["id"] as? String) ?? (value["name"] as? String)
            guard let raw else { return nil }
            let trimmed = raw.replacingOccurrences(of: "models/", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        } ?? []
        return !(openAIIDs + namedModels).isEmpty
    }
}
