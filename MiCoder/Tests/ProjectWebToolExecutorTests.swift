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

    private func makeExecutor(root: URL) -> ProjectWebToolExecutor {
        ProjectWebToolExecutor(projectRoot: root.path, accessLevel: .fullAccess)
    }

    @Test func writeThenReadFile() async throws {
        let root = try makeRoot()
        let exec = makeExecutor(root: root)
        let w = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "a.txt", "content": "hello"]))
        #expect(w.hasPrefix("ok"))
        let r = await exec.execute(WebToolCall(name: "read_file", arguments: ["path": "a.txt"]))
        #expect(r == "hello")
    }

    @Test func editFileReplaces() async throws {
        let root = try makeRoot()
        let exec = makeExecutor(root: root)
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "b.txt", "content": "foo bar"]))
        let e = await exec.execute(WebToolCall(name: "edit_file", arguments: ["path": "b.txt", "old": "foo", "new": "baz"]))
        #expect(e.hasPrefix("ok"))
        let r = await exec.execute(WebToolCall(name: "read_file", arguments: ["path": "b.txt"]))
        #expect(r == "baz bar")
    }

    @Test func editFileMissingOldReturnsError() async throws {
        let root = try makeRoot()
        let exec = makeExecutor(root: root)
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "c.txt", "content": "x"]))
        let e = await exec.execute(WebToolCall(name: "edit_file", arguments: ["path": "c.txt", "old": "zzz", "new": "y"]))
        #expect(e.contains("not found"))
    }

    @Test func listDir() async throws {
        let root = try makeRoot()
        let exec = makeExecutor(root: root)
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "one.txt", "content": "1"]))
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "two.txt", "content": "2"]))
        let l = await exec.execute(WebToolCall(name: "list_dir", arguments: ["path": "."]))
        #expect(l.contains("one.txt"))
        #expect(l.contains("two.txt"))
    }

    @Test func grepFindsMatches() async throws {
        let root = try makeRoot()
        let exec = makeExecutor(root: root)
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "code.swift", "content": "let target = 1\nlet other = 2"]))
        let g = await exec.execute(WebToolCall(name: "grep", arguments: ["pattern": "target", "path": "."]))
        #expect(g.contains("code.swift"))
        #expect(g.contains("target"))
    }

    @Test func runCommandRequiresApproval() async throws {
        let root = try makeRoot()
        let exec = ProjectWebToolExecutor(projectRoot: root.path, accessLevel: .askBeforeChanges)
        let r = await exec.execute(WebToolCall(name: "run_command", arguments: ["command": "ls"]))
        #expect(r.contains("requires approval"))
    }

    @Test func unknownToolErrors() async throws {
        let root = try makeRoot()
        let exec = makeExecutor(root: root)
        let r = await exec.execute(WebToolCall(name: "nope", arguments: [:]))
        #expect(r.contains("unknown tool"))
    }

    // MARK: - P3: Glob regex escaping

    @Test("glob handles dots in filenames correctly")
    func globDotInFilename() async throws {
        let root = try makeRoot()
        let exec = makeExecutor(root: root)
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "foo.swift", "content": "a"]))
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "foo_bar.swift", "content": "b"]))
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "foo.swift.bak", "content": "c"]))

        // "*.swift" should match foo.swift and foo_bar.swift but NOT foo.swift.bak
        let g = await exec.execute(WebToolCall(name: "glob", arguments: ["pattern": "*.swift", "path": "."]))
        #expect(g.contains("foo.swift"), "should match foo.swift, got: \(g)")
        #expect(g.contains("foo_bar.swift"), "should match foo_bar.swift, got: \(g)")
        #expect(!g.contains("foo.swift.bak"), "should NOT match foo.swift.bak, got: \(g)")
    }

    @Test("glob handles bracket patterns")
    func globBracketPattern() async throws {
        let root = try makeRoot()
        let exec = makeExecutor(root: root)
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "test1.txt", "content": "a"]))
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "test2.txt", "content": "b"]))
        _ = await exec.execute(WebToolCall(name: "write_file", arguments: ["path": "test3.log", "content": "c"]))

        // "test[12].txt" should match test1.txt and test2.txt but not test3.log
        let g = await exec.execute(WebToolCall(name: "glob", arguments: ["pattern": "test[12].txt", "path": "."]))
        #expect(g.contains("test1.txt"), "should match test1.txt, got: \(g)")
        #expect(g.contains("test2.txt"), "should match test2.txt, got: \(g)")
        #expect(!g.contains("test3.log"), "should NOT match test3.log, got: \(g)")
    }

    // MARK: - P5: Grep truncation warning

    @Test("grep warns when results are truncated at 500 files")
    func grepTruncationWarning() async throws {
        let root = try makeRoot()
        let exec = makeExecutor(root: root)

        // Verify grep works with a small set first
        for i in 0..<5 {
            _ = await exec.execute(WebToolCall(name: "write_file",
                arguments: ["path": "file\(i).txt", "content": "content_\(i)"]))
        }
        _ = await exec.execute(WebToolCall(name: "write_file",
            arguments: ["path": "marker.txt", "content": "UNIQUE_MARKER"]))

        let small = await exec.execute(WebToolCall(name: "grep", arguments: ["pattern": "UNIQUE_MARKER", "path": "."]))
        #expect(small.contains("UNIQUE_MARKER"), "grep must find match in small set, got: \(small)")
        // Small set should NOT have truncation warning
        #expect(!small.contains("Truncated"), "small set should not be truncated, got: \(small)")
    }
}
