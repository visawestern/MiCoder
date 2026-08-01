import Foundation

/// Pure per-project storage administration (plan Раздел 8 п.25/п.28):
/// real per-project DB sizes and bulk archive operations, testable without
/// touching the global database.
enum ProjectStorageAdmin {

    /// Size in bytes of the project's `.micoder/project.db` (0 when missing).
    static func projectDatabaseSize(projectPath: String) -> Int64 {
        let url = ProjectDatabaseLocator.databaseURL(projectPath: projectPath)
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        return (attrs?[.size] as? Int64) ?? 0
    }

    /// Archive every non-archived project not opened in the last N days
    /// (plan Раздел 8 п.25 — user-driven bulk archive, never automatic).
    static func archiveAllInactive(days: Int, now: Date = Date(), in projects: [ProjectRegistryEntry]) -> [ProjectRegistryEntry] {
        let cutoff = now.addingTimeInterval(-Double(days) * 86400)
        return projects.map { entry in
            guard !entry.isArchived, entry.lastOpenedAt < cutoff else { return entry }
            var updated = entry
            updated.archivedAt = now
            return updated
        }
    }
}
