import Foundation

struct ProjectFileIndexSnapshot: Codable, Equatable {
    let projectPath: String
    let records: [FileIndexRecord]
}

enum ProjectFileIndexPersistenceLogic {
    static func encode(projectPath: String, records: [FileIndexRecord]) -> Data? {
        let snapshot = ProjectFileIndexSnapshot(projectPath: projectPath, records: records)
        return try? JSONEncoder().encode(snapshot)
    }

    static func decode(data: Data) -> ProjectFileIndexSnapshot? {
        try? JSONDecoder().decode(ProjectFileIndexSnapshot.self, from: data)
    }

    static func applyDelta(
        current: [FileIndexRecord],
        scanned: [FileIndexRecord]
    ) -> [FileIndexRecord] {
        var byPath: [String: FileIndexRecord] = Dictionary(uniqueKeysWithValues: current.map { ($0.path, $0) })
        let scannedPaths = Set(scanned.map(\.path))
        for record in scanned {
            if let existing = byPath[record.path],
               existing.hash == record.hash,
               existing.lastModified == record.lastModified {
                continue
            }
            byPath[record.path] = record
        }
        for path in current.map(\.path) where !scannedPaths.contains(path) {
            byPath.removeValue(forKey: path)
        }
        return byPath.values.sorted { $0.path < $1.path }
    }
}

enum IndexingSettingsLogic {
    static let automaticIndexingIsAvailable = false
    static let statusMessage = "Automatic indexing is not available yet; @ file suggestions refresh on demand."
}
