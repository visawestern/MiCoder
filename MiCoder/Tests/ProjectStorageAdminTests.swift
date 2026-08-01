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

    private func makeProjectDir(_ name: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("pdb-admin-\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeDbWithBytes(at dir: URL, bytes: Int64) throws {
        // A real on-disk file of the requested size at the project DB path.
        // quotaStatus reads actual file attributes, so a real file is enough —
        // no need to insert hundreds of thousands of messages (way too slow).
        // Written in chunks so a multi-GB fixture never allocates GBs in RAM.
        let dbURL = ProjectDatabaseLocator.databaseURL(projectPath: dir.path)
        try FileManager.default.createDirectory(
            at: dbURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try FileManager.default.createFile(atPath: dbURL.path, contents: nil)
        let handle = try FileHandle(forWritingTo: dbURL)
        defer { try? handle.close() }
        let chunk = Data(repeating: 0, count: 1 << 20) // 1 MB
        var remaining = bytes
        while remaining > 0 {
            let amount = min(Int64(chunk.count), remaining)
            try handle.write(contentsOf: chunk.prefix(Int(amount)))
            remaining -= amount
        }
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

    // MARK: - Plan Раздел 8 п.50: storage quota warning

    @Test func quotaStatusReportsTotalAndOverThreshold() throws {
        let dirA = try makeProjectDir("quota-a")
        defer { try? FileManager.default.removeItem(at: dirA.deletingLastPathComponent()) }
        try makeDbWithBytes(at: dirA, bytes: 3_000_000_000) // 3GB > 2GB threshold

        let entry = ProjectRegistryEntry(path: dirA.path, lastOpenedAt: Date())
        let status = ProjectStorageAdmin.quotaStatus(
            projects: [entry], thresholdBytes: 2_000_000_000
        )
        #expect(status.totalBytes >= 3_000_000_000)
        #expect(status.isOverQuota == true)
        #expect(status.overByBytes > 0)
    }

    @Test func quotaStatusIsCalmUnderThreshold() throws {
        let dirA = try makeProjectDir("quota-b")
        defer { try? FileManager.default.removeItem(at: dirA.deletingLastPathComponent()) }
        try makeDbWithBytes(at: dirA, bytes: 100_000)

        let entry = ProjectRegistryEntry(path: dirA.path, lastOpenedAt: Date())
        let status = ProjectStorageAdmin.quotaStatus(
            projects: [entry], thresholdBytes: 2_000_000_000
        )
        #expect(status.isOverQuota == false)
        #expect(status.overByBytes == 0)
    }

    @Test func quotaStatusSplitsActiveArchivedAndInactive() throws {
        // Two active-but-stale projects (archivable), one archived, one fresh.
        let staleA = try makeProjectDir("quota-stale-a")
        defer { try? FileManager.default.removeItem(at: staleA.deletingLastPathComponent()) }
        try makeDbWithBytes(at: staleA, bytes: 1_200_000_000)
        let staleB = try makeProjectDir("quota-stale-b")
        defer { try? FileManager.default.removeItem(at: staleB.deletingLastPathComponent()) }
        try makeDbWithBytes(at: staleB, bytes: 1_200_000_000)

        let freshDir = try makeProjectDir("quota-fresh")
        defer { try? FileManager.default.removeItem(at: freshDir.deletingLastPathComponent()) }
        try makeDbWithBytes(at: freshDir, bytes: 500_000_000)

        var archived = ProjectRegistryEntry(path: freshDir.path, lastOpenedAt: Date(timeIntervalSince1970: 1000))
        archived.archivedAt = Date()

        let staleEntryA = ProjectRegistryEntry(path: staleA.path, lastOpenedAt: Date().addingTimeInterval(-60 * 86400))
        let staleEntryB = ProjectRegistryEntry(path: staleB.path, lastOpenedAt: Date().addingTimeInterval(-90 * 86400))
        let freshEntry = ProjectRegistryEntry(path: freshDir.path, lastOpenedAt: Date())

        let status = ProjectStorageAdmin.quotaStatus(
            projects: [staleEntryA, staleEntryB, freshEntry, archived],
            thresholdBytes: 2_000_000_000,
            inactiveDays: 30
        )
        #expect(status.isOverQuota == true)
        // Archived entries are NOT counted as "archivable" (already archived).
        #expect(status.archivableBytes >= 2_400_000_000)
        // Fresh + archived DB bytes are not part of the archivable sum.
        #expect(status.archivedBytes >= 500_000_000)
    }
}