import Foundation
import Testing
@testable import MiCoder

@Suite("WEB-CHAT-11: web tool access gate")
struct WebToolAccessGateTests {
    @Test("ask-before-changes requires approval for every file mutation")
    func askBeforeChangesGatesFileMutations() {
        let calls = [
            WebToolCall(name: "write_file", arguments: ["path": "a.txt", "content": "x"]),
            WebToolCall(name: "edit_file", arguments: ["path": "a.txt", "old": "x", "new": "y"]),
            WebToolCall(name: "todo_write", arguments: ["todos": "[]"])
        ]
        for call in calls {
            #expect(WebToolAccessGate.permission(for: call, accessLevel: .askBeforeChanges) == .requireApproval)
        }
    }

    @Test("edit-automatically allows file mutations but not shell execution")
    func editAutomaticallyKeepsShellGuarded() {
        let write = WebToolCall(name: "write_file", arguments: ["path": "a.txt", "content": "x"])
        let command = WebToolCall(name: "run_command", arguments: ["command": "echo x"])
        #expect(WebToolAccessGate.permission(for: write, accessLevel: .editAutomatically) == .allow)
        #expect(WebToolAccessGate.permission(for: command, accessLevel: .editAutomatically) == .requireApproval)
    }

    @Test("full access allows file and shell mutations")
    func fullAccessAllowsMutations() {
        let write = WebToolCall(name: "write_file", arguments: ["path": "a.txt", "content": "x"])
        let command = WebToolCall(name: "run_command", arguments: ["command": "echo x"])
        #expect(WebToolAccessGate.permission(for: write, accessLevel: .fullAccess) == .allow)
        #expect(WebToolAccessGate.permission(for: command, accessLevel: .fullAccess) == .allow)
    }
}
