import Testing
import Foundation
@testable import MiCoder

@Suite("E09/E10 — real tool operations record undo entries + request_history (Раздел 7 п.12-14)")
struct E09E10ToolUndoHistoryTests {

    private func makeTempProjectDir(_ name: String = UUID().uuidString) throws -> String {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("mimo-e09e10-\(name)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.path
    }

    @Test("write_file snapshots + records an undo entry and a request_history row")
    func writeFileRecordsUndoAndHistory() async throws {
        let root = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: root) }
        ProjectDatabaseManager.evictAll()
        let undo = try ProjectUndoManager(projectPath: root)
        try undo.db.insertSession(id: "s1", title: "Session", directory: root)
        let exec = ProjectWebToolExecutor(projectRoot: root, undoManager: undo, sessionId: "s1")

        let result = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "a.txt", "content": "hello"]))
        #expect(result.hasPrefix("ok"))

        let entries = try undo.history(sessionId: "s1")
        #expect(entries.count == 1)
        #expect(entries[0].actionType == "write_file")
        #expect(entries[0].targetPath == (root as NSString).appendingPathComponent("a.txt"))

        let history = try undo.db.getRequestHistory(sessionId: "s1")
        #expect(history.count == 1)
        #expect(history[0].type == "file_edit")
        #expect(history[0].payload.contains("a.txt"))
    }

    @Test("edit_file records history and undoMostRecent restores the pre-edit content")
    func editFileUndoRestoresContent() async throws {
        let root = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: root) }
        ProjectDatabaseManager.evictAll()
        let undo = try ProjectUndoManager(projectPath: root)
        try undo.db.insertSession(id: "s1", title: "Session", directory: root)
        let exec = ProjectWebToolExecutor(projectRoot: root, undoManager: undo, sessionId: "s1")

        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "b.txt", "content": "foo bar"]))
        let edited = await exec.execute(WebToolCall(name: "edit_file", arguments: ["path": "b.txt", "old": "foo", "new": "baz"]))
        #expect(edited.hasPrefix("ok"))
        #expect(try String(contentsOfFile: (root as NSString).appendingPathComponent("b.txt"), encoding: .utf8) == "baz bar")

        let undone = try undo.undoMostRecent(sessionId: "s1")
        #expect(undone)
        #expect(try String(contentsOfFile: (root as NSString).appendingPathComponent("b.txt"), encoding: .utf8) == "foo bar",
                "undoMostRecent must roll back the last applied edit")
    }

    @Test("undo of a write_file that created a new file removes the file")
    func undoFileCreationRemovesCreatedFile() async throws {
        let root = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: root) }
        ProjectDatabaseManager.evictAll()
        let undo = try ProjectUndoManager(projectPath: root)
        try undo.db.insertSession(id: "s1", title: "Session", directory: root)
        let exec = ProjectWebToolExecutor(projectRoot: root, undoManager: undo, sessionId: "s1")

        let filePath = (root as NSString).appendingPathComponent("new.txt")
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "new.txt", "content": "fresh"]))
        #expect(FileManager.default.fileExists(atPath: filePath))

        let undone = try undo.undoMostRecent(sessionId: "s1")
        #expect(undone)
        #expect(!FileManager.default.fileExists(atPath: filePath),
                "the file did not exist before the write, so undo must delete it")
    }

    @Test("failed operation records no undo entry and no request_history row")
    func failedOperationLeavesNoTraces() async throws {
        let root = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: root) }
        ProjectDatabaseManager.evictAll()
        let undo = try ProjectUndoManager(projectPath: root)
        try undo.db.insertSession(id: "s1", title: "Session", directory: root)
        let exec = ProjectWebToolExecutor(projectRoot: root, undoManager: undo, sessionId: "s1")

        // edit_file against a file that does not exist must fail without side effects.
        let result = await exec.execute(WebToolCall(name: "edit_file", arguments: ["path": "missing.txt", "old": "x", "new": "y"]))
        #expect(result.contains("error"))

        #expect(try undo.history(sessionId: "s1").isEmpty, "no undo entry for a failed edit")
        #expect(try undo.db.getRequestHistory(sessionId: "s1").isEmpty, "no request_history for a failed edit")
    }

    @Test("executor without undo manager keeps plain file behavior (no crash, no recording)")
    func plainExecutorUnchanged() async throws {
        let root = try makeTempProjectDir()
        defer { try? FileManager.default.removeItem(atPath: root) }
        let exec = ProjectWebToolExecutor(projectRoot: root)
        let w = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "c.txt", "content": "plain"]))
        #expect(w.hasPrefix("ok"))
        let r = await exec.execute(WebToolCall(name: "read_file", arguments: ["path": "c.txt"]))
        #expect(r == "plain")
    }
}
