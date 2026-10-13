import Testing
import Foundation
@testable import myCoder

@Suite("Harness profiles C2 (eval harness-tax)")
struct HarnessProfileTests {

    @Test func coreToolsAreFive() {
        let core = Set(WebEmulatedTool.allCases.filter(\.isCore).map(\.rawValue))
        #expect(core == ["read_file", "write_file", "edit_file", "list_dir", "run_command"])
    }

    @Test func profileToolSets() {
        #expect(HarnessProfile.minimal.tools.count == 5)
        #expect(HarnessProfile.standard.tools.count == 11)
        #expect(HarnessProfile.full.tools.count == WebEmulatedTool.allCases.count)
        #expect(HarnessProfile.unknown.tools.count == WebEmulatedTool.allCases.count)
        let standard = Set(HarnessProfile.standard.tools.map(\.rawValue))
        #expect(standard.isSuperset(of: ["grep", "glob", "git_status", "git_diff", "todo_read", "todo_write"]))
        #expect(!standard.contains("git_push"))
    }

    @Test func minimalPreambleIsShorter() {
        let full = WebToolProtocolEmulator.systemPreamble(profile: .full)
        let minimal = WebToolProtocolEmulator.systemPreamble(profile: .minimal)
        #expect(minimal.utf8.count < full.utf8.count)
        #expect(minimal.contains("- read_file args:"))
        #expect(!minimal.contains("- git_push args:"))
        #expect(minimal.contains("available on request"))
        #expect(minimal.contains("git_push"))
        #expect(minimal.contains("```tool"))
    }

    @Test func defaultPreambleIsFull() {
        let def = WebToolProtocolEmulator.systemPreamble()
        let full = WebToolProtocolEmulator.systemPreamble(profile: .full)
        #expect(def == full)
    }

    @Test func budgetTruncatesUserPromptNotProtocol() {
        let longPrompt = String(repeating: "x", count: 5000)
        let out = WebToolProtocolEmulator.systemPreamble(
            userSystemPrompt: longPrompt, profile: .minimal, budgetBytes: 2000)
        #expect(out.utf8.count <= 2000)
        #expect(out.contains("```tool"))
        #expect(out.contains("list_dir"))
        #expect(out.contains("[truncated]"))
    }

    @Test func noBudgetKeepsFullPrompt() {
        let prompt = "custom instructions here"
        let out = WebToolProtocolEmulator.systemPreamble(
            userSystemPrompt: prompt, profile: .minimal)
        #expect(out.contains(prompt))
        #expect(!out.contains("[truncated]"))
    }
}
