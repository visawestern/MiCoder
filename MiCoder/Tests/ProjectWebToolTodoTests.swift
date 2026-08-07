import Testing
import Foundation
@testable import MiCoder

@Suite("Project web tool executor — todo_read/todo_write (plan Раздел 12)")
struct ProjectWebToolTodoTests {

    private func makeRoot() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimo-webtodo-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("todo_write persists todos and todo_read returns them")
    func todoWriteThenRead() async throws {
        let root = try makeRoot()
        let exec = ProjectWebToolExecutor(projectRoot: root.path)

        let todos = "{\"todos\": [{\"id\": \"1\", \"content\": \"Fix bug\", \"status\": \"pending\"}, {\"id\": \"2\", \"content\": \"Write tests\", \"status\": \"completed\"}]}"
        let writeResult = await exec.execute(WebToolCall(name: "todo_write", arguments: ["todos": todos]))

        #expect(writeResult.hasPrefix("ok"), "todo_write should succeed, got: \(writeResult)")

        let readResult = await exec.execute(WebToolCall(name: "todo_read", arguments: [:]))
        #expect(readResult.contains("Fix bug"), "todo_read should contain first todo")
        #expect(readResult.contains("Write tests"), "todo_read should contain second todo")
        #expect(readResult.contains("pending"), "todo_read should show pending status")
        #expect(readResult.contains("completed"), "todo_read should show completed status")
    }

    @Test("todo_read returns empty message when no todos exist")
    func todoReadEmpty() async throws {
        let root = try makeRoot()
        let exec = ProjectWebToolExecutor(projectRoot: root.path)

        let readResult = await exec.execute(WebToolCall(name: "todo_read", arguments: [:]))
        #expect(readResult.contains("no todos") || readResult.contains("empty") || readResult == "[]",
                "todo_read should indicate no todos, got: \(readResult)")
    }

    @Test("todo_write replaces existing todos")
    func todoWriteReplaces() async throws {
        let root = try makeRoot()
        let exec = ProjectWebToolExecutor(projectRoot: root.path)

        let first = "{\"todos\": [{\"id\": \"1\", \"content\": \"First\", \"status\": \"pending\"}]}"
        _ = await exec.execute(WebToolCall(name: "todo_write", arguments: ["todos": first]))

        let second = "{\"todos\": [{\"id\": \"2\", \"content\": \"Second\", \"status\": \"in_progress\"}]}"
        _ = await exec.execute(WebToolCall(name: "todo_write", arguments: ["todos": second]))

        let readResult = await exec.execute(WebToolCall(name: "todo_read", arguments: [:]))
        #expect(readResult.contains("Second"), "should contain the new todo")
        #expect(!readResult.contains("First"), "should NOT contain the replaced todo")
    }

    @Test("todo_write with invalid JSON returns error")
    func todoWriteInvalidJSON() async throws {
        let root = try makeRoot()
        let exec = ProjectWebToolExecutor(projectRoot: root.path)

        let result = await exec.execute(WebToolCall(name: "todo_write", arguments: ["todos": "not valid json"]))
        #expect(result.contains("error") || result.contains("invalid"), "invalid JSON should error, got: \(result)")
    }
}
