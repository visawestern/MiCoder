import Testing
import Foundation
@testable import MiCoder

// Serialized: every test exercises the shared static connection pool, so
// running them concurrently would let one test's evictAll()/evictIdle()
// calls race against another test's pool lookups.
@Suite("ProjectDatabaseManager — per-project SQLite storage", .serialized)
struct ProjectDatabaseManagerTests {

    /// Creates a real temporary directory to stand in for a project folder.
    /// `ProjectDatabaseManager` refuses to operate on paths that don't exist
    /// on disk, so every test needs a real directory (never a bare literal
    /// like "x") to avoid creating stray folders as a side effect.
    private func makeTempProjectDir() throws -> String {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimo-project-db-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.path
    }

    @Test("Rejects non-existent project paths without creating filesystem side effects")
    func rejectsMissingDirectory() {
        let bogus = "/tmp/mimo-does-not-exist-\(UUID().uuidString)"
        #expect(throws: ProjectDatabaseError.self) {
            _ = try ProjectDatabaseManager.manager(forProjectPath: bogus)
        }
        #expect(!FileManager.default.fileExists(atPath: bogus))
    }

    @Test("Creates <project>/.micoder/project.db for a valid project directory")
    func createsDatabaseFileInProject() throws {
        let projectPath = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: projectPath) }

        let manager = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
        let expectedDBPath = (projectPath as NSString)
            .appendingPathComponent(".micoder/project.db")
        #expect(manager.databaseFileURL.path == expectedDBPath)
        #expect(FileManager.default.fileExists(atPath: expectedDBPath))
    }

    @Test("Pool returns the same instance for the same normalized path")
    func poolReusesInstanceForSamePath() throws {
        let projectPath = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: projectPath) }
        ProjectDatabaseManager.evictAll()

        let first = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
        let second = try ProjectDatabaseManager.manager(forProjectPath: projectPath + "/")
        #expect(first === second)
    }

    @Test("Two different projects get isolated database files and data")
    func isolatesTwoProjects() throws {
        let projectA = try makeTempProjectDir()
        let projectB = try makeTempProjectDir()
        defer {
            try? FileManager.default.removeItem(atPath: projectA)
            try? FileManager.default.removeItem(atPath: projectB)
        }

        let dbA = try ProjectDatabaseManager.manager(forProjectPath: projectA)
        let dbB = try ProjectDatabaseManager.manager(forProjectPath: projectB)
        #expect(dbA !== dbB)

        try dbA.insertSession(id: "s1", title: "A session", directory: projectA)
        #expect(try dbA.getAllSessions().count == 1)
        #expect(try dbB.getAllSessions().isEmpty)
    }

    @Test("Sessions round-trip through insert/get/update/archive")
    func sessionCRUD() throws {
        let projectPath = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: projectPath) }
        let db = try ProjectDatabaseManager.manager(forProjectPath: projectPath)

        try db.insertSession(id: "s1", title: "First chat", directory: projectPath)
        let sessions = try db.getAllSessions()
        #expect(sessions.count == 1)
        #expect(sessions.first?.id == "s1")
        #expect(sessions.first?.isArchived == false)

        try db.archiveSession(id: "s1")
        let activeOnly = try db.getAllSessions(includeArchived: false)
        #expect(activeOnly.isEmpty)
        let withArchived = try db.getAllSessions(includeArchived: true)
        #expect(withArchived.count == 1)
    }

    @Test("Messages and message parts round-trip with sequence ordering preserved")
    func messagesAndPartsRoundTrip() throws {
        let projectPath = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: projectPath) }
        let db = try ProjectDatabaseManager.manager(forProjectPath: projectPath)

        try db.insertSession(id: "s1", title: "Chat", directory: projectPath)
        try db.insertMessage(id: "m1", sessionId: "s1", role: "user", content: "Hello")
        try db.insertMessagePart(id: "p1", messageId: "m1", type: "text", content: "Hello", sequenceOrder: 0)
        try db.insertMessagePart(id: "p2", messageId: "m1", type: "tool_call", toolName: "read_file", toolArgs: "{}", sequenceOrder: 1)

        let messages = try db.getMessages(sessionId: "s1")
        #expect(messages.count == 1)
        let parts = try db.getMessageParts(messageId: "m1")
        #expect(parts.map(\.sequenceOrder) == [0, 1])
        #expect(parts[1].toolName == "read_file")
    }

    @Test("request_history captures non-chat operations distinct from messages")
    func requestHistoryTracksOperations() throws {
        let projectPath = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: projectPath) }
        let db = try ProjectDatabaseManager.manager(forProjectPath: projectPath)

        try db.insertSession(id: "s1", title: "Chat", directory: projectPath)
        try db.recordRequestHistory(sessionId: "s1", type: "file_edit", payload: "{\"path\":\"a.swift\"}")
        try db.recordRequestHistory(sessionId: "s1", type: "command_executed", payload: "{\"cmd\":\"swift build\"}")

        let history = try db.getRequestHistory(sessionId: "s1")
        #expect(history.count == 2)
        #expect(history.map(\.type) == ["file_edit", "command_executed"])
    }

    @Test("Undo stack entries are scoped per project and support point-in-time listing")
    func undoStackScopedPerProject() throws {
        let projectPath = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: projectPath) }
        let db = try ProjectDatabaseManager.manager(forProjectPath: projectPath)

        try db.insertSession(id: "s1", title: "Chat", directory: projectPath)
        try db.insertUndoEntry(id: "u1", sessionId: "s1", actionType: "edit_file", targetPath: "a.swift", snapshotId: "snap1")
        try db.insertUndoEntry(id: "u2", sessionId: "s1", actionType: "edit_file", targetPath: "b.swift", snapshotId: "snap2")

        let entries = try db.getUndoStack(sessionId: "s1")
        #expect(entries.count == 2)
        #expect(entries.first?.id == "u2", "most recent entry should come first")

        try db.markUndoEntryUsed(id: "u2")
        let afterUndo = try db.getUndoStack(sessionId: "s1", onlyUsable: true)
        #expect(afterUndo.map(\.id) == ["u1"])
    }

    @Test("Full-text search finds messages via project-scoped FTS5 index")
    func fullTextSearch() throws {
        let projectPath = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: projectPath) }
        let db = try ProjectDatabaseManager.manager(forProjectPath: projectPath)

        try db.insertSession(id: "s1", title: "Chat", directory: projectPath)
        try db.insertMessage(id: "m1", sessionId: "s1", role: "user", content: "please refactor the DatabaseBridge module")
        try db.insertMessage(id: "m2", sessionId: "s1", role: "assistant", content: "sure, updating the file now")

        let results = try db.searchMessages(query: "DatabaseBridge")
        #expect(results == ["m1"])
    }

    @Test("Stable project identity is persisted on first creation and stable across reopen")
    func stableIdentityPersists() throws {
        let projectPath = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: projectPath) }
        ProjectDatabaseManager.evictAll()

        let first = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
        let stableId = try first.stableProjectId()
        #expect(!stableId.isEmpty)

        ProjectDatabaseManager.evictAll()
        let reopened = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
        #expect(try reopened.stableProjectId() == stableId)
    }

    @Test("Idle connections are evicted from the pool after the configured timeout")
    func idleConnectionsAreEvicted() throws {
        let projectPath = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: projectPath) }
        ProjectDatabaseManager.evictAll()

        let manager = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
        let normalized = ChatSession.normalizedPath(projectPath)
        #expect(ProjectDatabaseManager.isPooled(projectPath: normalized))

        ProjectDatabaseManager.evictIdle(olderThan: 1, now: manager.lastAccessedAt.addingTimeInterval(2))
        #expect(!ProjectDatabaseManager.isPooled(projectPath: normalized))
    }

    @Test("Reopening after eviction re-reads existing data from disk")
    func reopenAfterEvictionPreservesData() throws {
        let projectPath = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: projectPath) }
        ProjectDatabaseManager.evictAll()

        let first = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
        try first.insertSession(id: "s1", title: "Persisted chat", directory: projectPath)
        ProjectDatabaseManager.evictAll()

        let reopened = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
        let sessions = try reopened.getAllSessions()
        #expect(sessions.map(\.id) == ["s1"])
    }

    @Test("Database file size reflects real on-disk usage after writes")
    func databaseFileSizeReflectsWrites() throws {
        let projectPath = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: projectPath) }
        let db = try ProjectDatabaseManager.manager(forProjectPath: projectPath)

        let sizeBefore = db.databaseFileSizeBytes()
        try db.insertSession(id: "s1", title: "Chat", directory: projectPath)
        for i in 0..<50 {
            try db.insertMessage(id: "m\(i)", sessionId: "s1", role: "user", content: String(repeating: "x", count: 500))
        }
        let sizeAfter = db.databaseFileSizeBytes()
        #expect(sizeAfter > sizeBefore)
    }
}
