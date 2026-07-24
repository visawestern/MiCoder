import Testing
import Foundation
@testable import MiCoder

@Suite("ProjectDatabaseMigrator — legacy single-DB to per-project migration", .serialized)
struct ProjectDatabaseMigrationTests {

    private func makeTempDir(_ name: String = UUID().uuidString) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("mimo-migration-tests-\(name)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test("Migrates sessions and messages grouped by directory into isolated per-project databases without data loss")
    func migratesWithoutDataLoss() throws {
        let legacy = DatabaseManager.createInMemory()
        let projectA = try makeTempDir("project-a")
        let projectB = try makeTempDir("project-b")
        let unassignedBase = try makeTempDir("unassigned-base")
        defer {
            try? FileManager.default.removeItem(at: projectA)
            try? FileManager.default.removeItem(at: projectB)
            try? FileManager.default.removeItem(at: unassignedBase)
        }
        ProjectDatabaseManager.evictAll()

        try legacy.insertProject(id: "legacy-a", name: "A", path: projectA.path)
        try legacy.insertProject(id: "legacy-b", name: "B", path: projectB.path)

        try legacy.insertSession(id: "s1", projectId: "legacy-a", title: "First", directory: projectA.path)
        try legacy.insertMessage(id: "m1", sessionId: "s1", role: "user", content: "Hello from A")
        try legacy.insertMessagePart(id: "p1", messageId: "m1", type: "text", content: "Hello from A", sequenceOrder: 0)

        try legacy.insertSession(id: "s2", projectId: "legacy-b", title: "Second", directory: projectB.path)
        try legacy.insertMessage(id: "m2", sessionId: "s2", role: "assistant", content: "Hi from B")

        let summary = try ProjectDatabaseMigrator.migrate(from: legacy, unassignedBaseDirectory: unassignedBase)

        #expect(summary.totalSessionsMigrated == 2)
        #expect(summary.totalMessagesMigrated == 2)
        #expect(Set(summary.migratedProjectPaths) == Set([
            ChatSession.normalizedPath(projectA.path),
            ChatSession.normalizedPath(projectB.path)
        ]))

        let dbA = try ProjectDatabaseManager.manager(forProjectPath: projectA.path)
        let sessionsA = try dbA.getAllSessions()
        #expect(sessionsA.map(\.id) == ["s1"])
        let messagesA = try dbA.getMessages(sessionId: "s1")
        #expect(messagesA.map(\.content) == ["Hello from A"])
        let partsA = try dbA.getMessageParts(messageId: "m1")
        #expect(partsA.map(\.content) == ["Hello from A"])

        let dbB = try ProjectDatabaseManager.manager(forProjectPath: projectB.path)
        let sessionsB = try dbB.getAllSessions()
        #expect(sessionsB.map(\.id) == ["s2"])
    }

    @Test("Sessions with no directory are preserved in the unassigned store, never dropped")
    func preservesSessionsWithoutDirectory() throws {
        let legacy = DatabaseManager.createInMemory()
        let unassignedBase = try makeTempDir("unassigned-base-2")
        defer { try? FileManager.default.removeItem(at: unassignedBase) }
        ProjectDatabaseManager.evictAll()

        try legacy.insertProject(id: "legacy-default", name: "default", path: "/tmp/does-not-matter-\(UUID().uuidString)")
        try legacy.insertSession(id: "orphan1", projectId: "legacy-default", title: "No directory", directory: "")
        try legacy.insertMessage(id: "m-orphan", sessionId: "orphan1", role: "user", content: "orphaned message")

        let summary = try ProjectDatabaseMigrator.migrate(from: legacy, unassignedBaseDirectory: unassignedBase)

        #expect(summary.unassignedSessionCount == 1)
        #expect(summary.totalSessionsMigrated == 1)
        #expect(summary.migratedProjectPaths.isEmpty)

        let unassignedDB = try ProjectDatabaseManager.unassignedManager(baseDirectory: unassignedBase)
        let sessions = try unassignedDB.getAllSessions()
        #expect(sessions.map(\.id) == ["orphan1"])
        let messages = try unassignedDB.getMessages(sessionId: "orphan1")
        #expect(messages.map(\.content) == ["orphaned message"])
    }

    @Test("Sessions whose directory no longer exists on disk are routed to unassigned instead of being lost")
    func preservesSessionsWithMissingDirectory() throws {
        let legacy = DatabaseManager.createInMemory()
        let unassignedBase = try makeTempDir("unassigned-base-3")
        defer { try? FileManager.default.removeItem(at: unassignedBase) }
        ProjectDatabaseManager.evictAll()

        let vanishedPath = "/tmp/mimo-vanished-project-\(UUID().uuidString)"
        try legacy.insertProject(id: "legacy-vanished", name: "Vanished", path: vanishedPath)
        try legacy.insertSession(id: "s-vanished", projectId: "legacy-vanished", title: "Gone", directory: vanishedPath)

        let summary = try ProjectDatabaseMigrator.migrate(from: legacy, unassignedBaseDirectory: unassignedBase)

        #expect(summary.unassignedSessionCount == 1)
        #expect(summary.migratedProjectPaths.isEmpty)

        let unassignedDB = try ProjectDatabaseManager.unassignedManager(baseDirectory: unassignedBase)
        let sessions = try unassignedDB.getAllSessions()
        #expect(sessions.map(\.id) == ["s-vanished"])
    }

    @Test("Migration is idempotent: running it twice does not duplicate sessions or messages")
    func migrationIsIdempotent() throws {
        let legacy = DatabaseManager.createInMemory()
        let project = try makeTempDir("project-idempotent")
        let unassignedBase = try makeTempDir("unassigned-base-4")
        defer {
            try? FileManager.default.removeItem(at: project)
            try? FileManager.default.removeItem(at: unassignedBase)
        }
        ProjectDatabaseManager.evictAll()

        try legacy.insertProject(id: "legacy-p", name: "P", path: project.path)
        try legacy.insertSession(id: "s1", projectId: "legacy-p", title: "Chat", directory: project.path)
        try legacy.insertMessage(id: "m1", sessionId: "s1", role: "user", content: "hi")

        _ = try ProjectDatabaseMigrator.migrate(from: legacy, unassignedBaseDirectory: unassignedBase)
        _ = try ProjectDatabaseMigrator.migrate(from: legacy, unassignedBaseDirectory: unassignedBase)

        let db = try ProjectDatabaseManager.manager(forProjectPath: project.path)
        #expect(try db.getAllSessions().count == 1)
        #expect(try db.getMessages(sessionId: "s1").count == 1)
    }
}
