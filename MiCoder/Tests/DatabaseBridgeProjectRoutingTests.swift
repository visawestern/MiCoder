import Testing
import Foundation
@testable import MiCoder

// Serialized: DatabaseBridge.shared and ProjectDatabaseManager's pool are
// both shared mutable singletons; concurrent tests here would race on
// `setActiveProject`.
@Suite("DatabaseBridge — routes session/message storage to per-project databases", .serialized)
struct DatabaseBridgeProjectRoutingTests {

    private func makeTempProjectDir(_ name: String = UUID().uuidString) throws -> String {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("mimo-bridge-routing-\(name)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.path
    }

    @Test("createSession/loadSessions land in the per-project database when projectId is a real project directory")
    func createAndLoadSessionsRouteToProjectDB() throws {
        let projectPath = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: projectPath) }
        ProjectDatabaseManager.evictAll()

        DatabaseBridge.shared.createSession(id: "s1", projectId: projectPath, title: "Chat", directory: projectPath)
        let sessions = DatabaseBridge.shared.loadSessions(projectId: projectPath)
        #expect(sessions.map(\.id) == ["s1"])

        let projectDB = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
        #expect(try projectDB.getAllSessions().map(\.id) == ["s1"], "session must be physically stored in the per-project database, not the legacy global one")
    }

    @Test("saveMessage/loadMessages route to whichever project is marked active via setActiveProject")
    func messagesRouteToActiveProject() throws {
        let projectPath = try makeTempProjectDir()
        defer {
            try? FileManager.default.removeItem(atPath: projectPath)
            DatabaseBridge.shared.setActiveProject(path: nil)
        }
        ProjectDatabaseManager.evictAll()

        DatabaseBridge.shared.setActiveProject(path: projectPath)
        DatabaseBridge.shared.createSession(id: "s1", projectId: projectPath, title: "Chat", directory: projectPath)

        let message = Message(id: "m1", role: .user, content: "hello from active project")
        DatabaseBridge.shared.saveMessage(message, sessionId: "s1")

        let loaded = DatabaseBridge.shared.loadMessages(sessionId: "s1")
        #expect(loaded.map(\.content) == ["hello from active project"])

        let projectDB = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
        #expect(try projectDB.getMessages(sessionId: "s1").map(\.content) == ["hello from active project"])
    }

    @Test("Switching the active project isolates message storage between two different projects")
    func switchingActiveProjectIsolatesMessages() throws {
        let projectA = try makeTempProjectDir("a")
        let projectB = try makeTempProjectDir("b")
        defer {
            try? FileManager.default.removeItem(atPath: projectA)
            try? FileManager.default.removeItem(atPath: projectB)
            DatabaseBridge.shared.setActiveProject(path: nil)
        }
        ProjectDatabaseManager.evictAll()

        DatabaseBridge.shared.setActiveProject(path: projectA)
        DatabaseBridge.shared.createSession(id: "sA", projectId: projectA, title: "A", directory: projectA)
        DatabaseBridge.shared.saveMessage(Message(id: "mA", role: .user, content: "in A"), sessionId: "sA")

        DatabaseBridge.shared.setActiveProject(path: projectB)
        DatabaseBridge.shared.createSession(id: "sB", projectId: projectB, title: "B", directory: projectB)
        DatabaseBridge.shared.saveMessage(Message(id: "mB", role: .user, content: "in B"), sessionId: "sB")

        let dbA = try ProjectDatabaseManager.manager(forProjectPath: projectA)
        let dbB = try ProjectDatabaseManager.manager(forProjectPath: projectB)
        #expect(try dbA.getMessages(sessionId: "sA").map(\.content) == ["in A"])
        #expect(try dbB.getMessages(sessionId: "sB").map(\.content) == ["in B"])
        #expect(try dbA.getMessages(sessionId: "sB").isEmpty)
    }

    @Test("archiveSession on the active project hides it from loadSessions without deleting its data")
    func archiveSessionRoutesToActiveProject() throws {
        let projectPath = try makeTempProjectDir()
        defer {
            try? FileManager.default.removeItem(atPath: projectPath)
            DatabaseBridge.shared.setActiveProject(path: nil)
        }
        ProjectDatabaseManager.evictAll()

        DatabaseBridge.shared.setActiveProject(path: projectPath)
        DatabaseBridge.shared.createSession(id: "s1", projectId: projectPath, title: "Chat", directory: projectPath)
        DatabaseBridge.shared.archiveSession(id: "s1")

        #expect(DatabaseBridge.shared.loadSessions(projectId: projectPath).isEmpty)

        let projectDB = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
        let archived = try projectDB.getAllSessions(includeArchived: true)
        #expect(archived.map(\.id) == ["s1"], "archived session must still exist on disk")
    }

    @Test("loadSessions falls back gracefully for a non-existent project path instead of crashing")
    func loadSessionsFallsBackForInvalidPath() {
        let bogus = "not-a-real-path-\(UUID().uuidString)"
        #expect(DatabaseBridge.shared.loadSessions(projectId: bogus).isEmpty)
    }
}
