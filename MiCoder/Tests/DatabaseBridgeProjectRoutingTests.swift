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
        ProjectDatabaseManager.evictProject(projectPath: projectPath)

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
        ProjectDatabaseManager.evictProject(projectPath: projectPath)

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
        ProjectDatabaseManager.evictProject(projectPath: projectA)
        ProjectDatabaseManager.evictProject(projectPath: projectB)

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
        ProjectDatabaseManager.evictProject(projectPath: projectPath)

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

    // MARK: - saveMessagePart routing (audit: stepStart used to bypass the
    // injected inserter and write to the legacy global DB instead of the
    // active project DB).

    @Test("stepStart part is written to the active project database, not the legacy global one")
    func stepStartPartRoutesToProjectDB() throws {
        let unique = UUID().uuidString
        let projectPath = try makeTempProjectDir("step-\(unique)")
        defer {
            try? FileManager.default.removeItem(atPath: projectPath)
            DatabaseBridge.shared.setActiveProject(path: nil)
        }
        ProjectDatabaseManager.evictProject(projectPath: projectPath)

        DatabaseBridge.shared.setActiveProject(path: projectPath)
        DatabaseBridge.shared.createSession(id: "s-step-\(unique)", projectId: projectPath, title: "Chat", directory: projectPath)

        var msg = Message(id: "m-step-\(unique)", role: .assistant, content: "working...")
        msg.parts = [.stepStart, .text("done")]

        DatabaseBridge.shared.saveMessage(msg, sessionId: "s-step-\(unique)")

        let projectDB = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
        let parts = try projectDB.getMessageParts(messageId: "m-step-\(unique)")
        #expect(parts.count == 2, "both stepStart and text parts must be in the project DB")
        #expect(parts.first?.type == "step_start", "first part must be step_start, not routed to legacy DB")
    }

    @Test("all part types land in the active project database")
    func allPartTypesRouteToProjectDB() throws {
        let unique = UUID().uuidString
        let projectPath = try makeTempProjectDir("all-\(unique)")
        defer {
            try? FileManager.default.removeItem(atPath: projectPath)
            DatabaseBridge.shared.setActiveProject(path: nil)
        }
        ProjectDatabaseManager.evictProject(projectPath: projectPath)

        DatabaseBridge.shared.setActiveProject(path: projectPath)
        DatabaseBridge.shared.createSession(id: "s-all-\(unique)", projectId: projectPath, title: "Chat", directory: projectPath)

        var msg = Message(id: "m-all-\(unique)", role: .assistant, content: "")
        msg.parts = [
            .text("hello"),
            .reasoning("thinking"),
            .toolCall(name: "read", args: "{\"f\":\"/x\"}", result: "content", callID: "c1"),
            .stepStart,
            .stepFinish,
            .image(base64: "abc123", mimeType: "image/png")
        ]

        DatabaseBridge.shared.saveMessage(msg, sessionId: "s-all-\(unique)")

        let projectDB = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
        let parts = try projectDB.getMessageParts(messageId: "m-all-\(unique)")
        #expect(parts.count == 6, "all 6 parts must be in the project DB")

        let types = parts.map(\.type)
        #expect(types == ["text", "reasoning", "tool_call", "step_start", "step_finish", "image"])
    }
}
