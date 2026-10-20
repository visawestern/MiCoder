import Testing
import Foundation
@testable import myCoder

@Suite("DatabaseBridge — sidebar session actions", .serialized)
struct DatabaseBridgeSessionActionsTests {

    private func makeTempProjectDir() throws -> String {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimo-bridge-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.path
    }

    @Test("Rename/delete route to the owning project store and report real changes")
    func renameAndDeleteProjectSession() throws {
        let projectPath = try makeTempProjectDir()
        defer {
            ProjectDatabaseManager.evictProject(projectPath: projectPath)
            try? FileManager.default.removeItem(atPath: projectPath)
        }

        let bridge = DatabaseBridge()
        bridge.createSession(id: "s1", projectId: projectPath, title: "Old", directory: projectPath)

        #expect(bridge.renameSession(id: "s1", title: "New"))
        let store = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
        #expect(try store.getAllSessions().first?.title == "New")

        #expect(bridge.renameSession(id: "missing", title: "X") == false)
        #expect(bridge.deleteSession(id: "s1"))
        #expect(try store.getAllSessions(includeArchived: true).isEmpty)
        #expect(bridge.deleteSession(id: "s1") == false)
    }
}
