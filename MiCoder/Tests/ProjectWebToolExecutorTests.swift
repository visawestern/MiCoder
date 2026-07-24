import Testing
import Foundation
@testable import MiCoder

@Suite("Project web tool executor — real file ops (plan Раздел 12 Блок 2 п.16)")
struct ProjectWebToolExecutorTests {

    private func makeRoot() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimo-webexec-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func writeThenReadFile() async throws {
        let root = try makeRoot()
        let exec = ProjectWebToolExecutor(projectRoot: root.path)
        let w = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "a.txt", "content": "hello"]))
        #expect(w.hasPrefix("ok"))
        let r = await exec.execute(WebToolCall(name: "read_file", arguments: ["path": "a.txt"]))
        #expect(r == "hello")
    }

    @Test func editFileReplaces() async throws {
        let root = try makeRoot()
        let exec = ProjectWebToolExecutor(projectRoot: root.path)
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "b.txt", "content": "foo bar"]))
        let e = await exec.execute(WebToolCall(name: "edit_file", arguments: ["path": "b.txt", "old": "foo", "new": "baz"]))
        #expect(e.hasPrefix("ok"))
        let r = await exec.execute(WebToolCall(name: "read_file", arguments: ["path": "b.txt"]))
        #expect(r == "baz bar")
    }

    @Test func editFileMissingOldReturnsError() async throws {
        let root = try makeRoot()
        let exec = ProjectWebToolExecutor(projectRoot: root.path)
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "c.txt", "content": "x"]))
        let e = await exec.execute(WebToolCall(name: "edit_file", arguments: ["path": "c.txt", "old": "zzz", "new": "y"]))
        #expect(e.contains("not found"))
    }

    @Test func listDir() async throws {
        let root = try makeRoot()
        let exec = ProjectWebToolExecutor(projectRoot: root.path)
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "one.txt", "content": "1"]))
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "two.txt", "content": "2"]))
        let l = await exec.execute(WebToolCall(name: "list_dir", arguments: ["path": "."]))
        #expect(l.contains("one.txt"))
        #expect(l.contains("two.txt"))
    }

    @Test func grepFindsMatches() async throws {
        let root = try makeRoot()
        let exec = ProjectWebToolExecutor(projectRoot: root.path)
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "code.swift", "content": "let target = 1\nlet other = 2"]))
        let g = await exec.execute(WebToolCall(name: "grep", arguments: ["pattern": "target", "path": "."]))
        #expect(g.contains("code.swift"))
        #expect(g.contains("target"))
    }

    @Test func runCommandRequiresApproval() async throws {
        let root = try makeRoot()
        let exec = ProjectWebToolExecutor(projectRoot: root.path)
        let r = await exec.execute(WebToolCall(name: "run_command", arguments: ["command": "ls"]))
        #expect(r.contains("requires approval"))
    }

    @Test func unknownToolErrors() async throws {
        let root = try makeRoot()
        let exec = ProjectWebToolExecutor(projectRoot: root.path)
        let r = await exec.execute(WebToolCall(name: "nope", arguments: [:]))
        #expect(r.contains("unknown tool"))
    }
}
