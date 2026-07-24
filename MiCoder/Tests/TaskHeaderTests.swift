import Testing
@testable import MiCoder

@Suite("Task Header")
struct TaskHeaderTests {
    
    @Test("Task header should show when session is selected")
    func showsWhenSessionSelected() {
        let state = AppState(host: "127.0.0.1", port: 0)
        #expect(state.selectedSession == nil)
        state.selectedSession = ChatSession(id: "s1", title: "Fix bug")
        #expect(state.selectedSession != nil)
        #expect(TaskHeaderVisibility.shouldShow(selectedSession: state.selectedSession) == true)
    }
    
    @Test("Task header hidden without session")
    func hiddenWithoutSession() {
        #expect(TaskHeaderVisibility.shouldShow(selectedSession: nil) == false)
    }
    
    @Test("Branch chip uses workspace branch or main")
    func branchChip() {
        var ws = Workspace(id: "1", name: "tm3", path: "/test")
        ws.branch = "razum-v4"
        #expect(TaskHeaderVisibility.branchLabel(workspace: ws) == "razum-v4")
        #expect(TaskHeaderVisibility.branchLabel(workspace: nil) == "main")
    }

    @Test("Chat header sidebar toggle icons")
    func sidebarToggleIcons() {
        #expect(TaskHeaderLayout.leftSidebarIcon == "sidebar.left")
        #expect(TaskHeaderLayout.rightSidebarIcon == "sidebar.right")
    }
}
