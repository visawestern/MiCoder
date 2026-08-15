import Testing
@testable import MiCoder

@Suite("Project session routing")
struct ProjectSessionRoutingLogicTests {
    @Test("explicit project ID wins over the currently selected workspace")
    func explicitProjectWins() {
        let workspaces = [
            ProjectSessionRoutingLogic.WorkspacePath(id: "project-a", path: "/tmp/a"),
            ProjectSessionRoutingLogic.WorkspacePath(id: "project-b", path: "/tmp/b")
        ]
        #expect(ProjectSessionRoutingLogic.path(
            projectID: "project-b",
            selectedPath: "/tmp/a",
            workspaces: workspaces
        ) == "/tmp/b")
    }

    @Test("path project IDs remain usable when no workspace row is loaded")
    func directPathFallback() {
        #expect(ProjectSessionRoutingLogic.path(
            projectID: "/tmp/project",
            selectedPath: "/tmp/other",
            workspaces: []
        ) == "/tmp/project")
    }
}
