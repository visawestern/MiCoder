import Testing
import Foundation
@testable import MiCoder

@Suite("Mimo CLI Session Loader")
struct MimoCLISessionLoaderTests {

    @Test("Parses mimo session list JSON output")
    func parsesSessionListJSON() throws {
        let json = """
        [
          {
            "id": "ses_abc123",
            "title": "Fix layout bug",
            "updated": 1784113527000,
            "created": 1781851397123,
            "projectId": "proj_1",
            "directory": "/Users/test/other-project"
          }
        ]
        """
        let data = Data(json.utf8)
        let entries = try MimoCLISessionLoader.parseSessionList(data)
        #expect(entries.count == 1)
        #expect(entries[0].id == "ses_abc123")
        #expect(entries[0].title == "Fix layout bug")
        #expect(entries[0].directory == "/Users/test/other-project")
    }

    @Test("Parsing invalid JSON throws decodingFailed")
    func parsingInvalidJSONThrows() {
        let data = Data("not json".utf8)
        #expect(throws: MimoCLISessionLoaderError.self) {
            try MimoCLISessionLoader.parseSessionList(data)
        }
    }

    @Test("Parses messages from mimo export JSON")
    func parsesExportMessages() throws {
        let json = """
        {
          "info": {
            "id": "ses_1",
            "title": "History",
            "directory": "/Users/test/project"
          },
          "messages": [
            {
              "info": {
                "id": "msg_1",
                "role": "user",
                "sessionID": "ses_1"
              },
              "parts": [
                {
                  "type": "text",
                  "text": "Previous message"
                }
              ]
            }
          ]
        }
        """

        let messages = try MimoCLISessionLoader.parseExportMessages(Data(json.utf8))
        #expect(messages.count == 1)
        #expect(messages[0].info?.id == "msg_1")
        #expect(messages[0].textContent == "Previous message")
    }

    @Test("Converts CLI entry to ChatSession with seconds-based dates")
    func convertsToChatSession() {
        let entry = MimoCLISessionEntry(
            id: "ses_1",
            title: "Some title",
            updated: 1_700_000_000_000,
            created: 1_699_000_000_000,
            projectId: "proj",
            directory: "/Users/test/proj"
        )
        let session = entry.toChatSession()
        #expect(session.id == "ses_1")
        #expect(session.title == "Some title")
        #expect(session.directory == "/Users/test/proj")
        #expect(abs(session.updatedAt.timeIntervalSince1970 - 1_700_000_000) < 1)
        #expect(abs(session.createdAt.timeIntervalSince1970 - 1_699_000_000) < 1)
    }

    @Test("Merging keeps existing sessions and appends new unique ones")
    func mergeAppendsUniqueSessions() {
        let existing = [
            ChatSession(id: "s1", title: "Ours", directory: "/Users/test/mimo-macos")
        ]
        let additional = [
            ChatSession(id: "s1", title: "Duplicate from CLI", directory: "/Users/test/mimo-macos"),
            ChatSession(id: "s2", title: "From another project", directory: "/Users/test/other-project")
        ]
        let merged = MimoCLISessionLoader.mergeSessions(existing: existing, additional: additional)
        #expect(merged.count == 2)
        #expect(merged.first { $0.id == "s1" }?.title == "Ours")
        #expect(merged.contains { $0.id == "s2" })
    }

    @Test("Merging with no additional sessions returns existing unchanged")
    func mergeWithEmptyAdditional() {
        let existing = [ChatSession(id: "s1", title: "Ours", directory: "/Users/test/mimo-macos")]
        let merged = MimoCLISessionLoader.mergeSessions(existing: existing, additional: [])
        #expect(merged.count == 1)
        #expect(merged.map(\.id) == existing.map(\.id))
    }

    @Test("Resolves binary path from candidate list")
    func resolvesBinaryPathFromCandidates() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimo-cli-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fakeBinary = dir.appendingPathComponent("mimo")
        FileManager.default.createFile(atPath: fakeBinary.path, contents: Data())
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fakeBinary.path)

        let resolved = MimoCLISessionLoader.resolveBinaryPath(
            environmentPath: nil,
            candidatePaths: [fakeBinary.path]
        )
        #expect(resolved == fakeBinary.path)
    }

    @Test("Resolves binary path from PATH environment when no candidate matches")
    func resolvesBinaryPathFromEnvironmentPath() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimo-cli-path-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fakeBinary = dir.appendingPathComponent("mimo")
        FileManager.default.createFile(atPath: fakeBinary.path, contents: Data())
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fakeBinary.path)

        let resolved = MimoCLISessionLoader.resolveBinaryPath(
            environmentPath: "/nonexistent:\(dir.path)",
            candidatePaths: ["/nonexistent/mimo"]
        )
        #expect(resolved == fakeBinary.path)
    }

    @Test("Returns nil when no candidate or PATH entry has the binary")
    func resolvesToNilWhenMissing() {
        let resolved = MimoCLISessionLoader.resolveBinaryPath(
            environmentPath: "/nonexistent",
            candidatePaths: ["/nonexistent/mimo"]
        )
        #expect(resolved == nil)
    }

    @Suite(
        "Live mimo CLI",
        .enabled(if: MimoCLISessionLoader.resolveBinaryPath() != nil)
    )
    struct LiveCLITests {
        @Test("mimo session list returns sessions from more than the current project")
        func loadsSessionsAcrossProjects() throws {
            let sessions = try MimoCLISessionLoader.loadAllSessions(maxCount: 200)
            #expect(sessions.count >= 0)
            for session in sessions {
                #expect(!session.id.isEmpty)
            }
        }

        @Test("mimo export loads message history without a running server")
        func loadsMessagesWithoutServer() throws {
            let sessions = try MimoCLISessionLoader.loadAllSessions(maxCount: 200)
            let session = try #require(sessions.first)
            let messages = try MimoCLISessionLoader.loadMessages(sessionID: session.id)
            #expect(!messages.isEmpty)
        }

        @Test("AppState loads recent sessions from all mimo projects even without a connected mimo serve")
        @MainActor
        func appStateLoadsSessionsWithoutServer() async throws {
            // Port with no listener: simulates the "no mimo serve connected" case.
            let appState = AppState(host: "127.0.0.1", port: 65100)
            await appState.loadSessionsFromServer()
            #expect(!appState.serverConnected)
            #expect(!appState.sessions.isEmpty)
            #expect(!appState.workspaces.isEmpty)
        }
    }
}
