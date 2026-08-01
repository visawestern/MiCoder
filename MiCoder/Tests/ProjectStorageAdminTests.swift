import Testing
import Foundation
@testable import MiCoder

/// Pure per-project storage administration helpers (plan Раздел 8 п.25/п.28):
/// real per-project DB sizes and bulk operations, all unit-testable without
/// touching the global database.
@Suite("Per-project storage admin (plan Раздел 8 п.25/п.28)")
struct ProjectStorageAdminTests {

    @Test func databaseSizeIsZeroWhenMissing() {
        let missing = ProjectStorageAdmin.projectDatabaseSize(
            projectPath: "/definitely/does/not/exist/\(UUID().uuidString)"
        )
        #expect(missing == 0)
    }

    @Test func projectDatabaseSizeReflectsRealFile() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pdb-admin-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        // Create a real .micoder/project.db with actual content.
        let fileDB = try ProjectDatabaseManager.manager(forProjectPath: dir.path)
        try fileDB.insertSession(id: "s2", title: "T2", directory: dir.path)
        try fileDB.insertMessage(id: "m1", sessionId: "s2", role: "user", content: "data")

        let size = ProjectStorageAdmin.projectDatabaseSize(projectPath: dir.path)
        #expect(size > 0)
    }

    @Test func archiveAllInactiveUsesRegistryArchive() {
        let old = ProjectRegistryEntry(path: "/p/old", lastOpenedAt: Date().addingTimeInterval(-40 * 86400))
        let fresh = ProjectRegistryEntry(path: "/p/fresh", lastOpenedAt: Date())
        let result = ProjectStorageAdmin.archiveAllInactive(days: 30, in: [old, fresh])
        #expect(result.contains { $0.path == "/p/old" && $0.isArchived })
        #expect(result.contains { $0.path == "/p/fresh" && !$0.isArchived })
    }

    @Test func archiveAllInactiveKeepsAlreadyArchived() {
        var old = ProjectRegistryEntry(path: "/p/old", lastOpenedAt: Date().addingTimeInterval(-40 * 86400))
        old.archivedAt = Date()
        let result = ProjectStorageAdmin.archiveAllInactive(days: 30, in: [old])
        #expect(result.count == 1)
        #expect(result.first?.isArchived == true)
    }
}
