import Testing
import Foundation
@testable import myCoder

/// Clicking "+" on a project-less chat called
/// `startNewTask(in: standaloneWorkspace)` → `selectWorkspace` wiped
/// `sessions = []` → `loadSessionsFromDatabase(projectId: "standalone")`
/// hit the unknown-workspace guard and returned early — the list stayed
/// empty forever although every row was intact in the DB.
@Suite("Standalone chat list survives workspace switches (plus-button wipe)")
struct StandaloneListWipeTests {

    @MainActor
    private func makeState() -> AppState {
        AppState(host: "127.0.0.1", port: 0,
                 defaults: UserDefaults(suiteName: "wipe-\(UUID().uuidString)")!)
    }

    private func poll(
        _ check: @MainActor @Sendable () -> Bool,
        attempts: Int = 100
    ) async -> Bool {
        for _ in 0..<attempts {
            if await MainActor.run(resultType: Bool.self, body: check) { return true }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        return false
    }

    @Test func plusOnStandaloneChatKeepsChats() async {
        let sid = "wipe-\(UUID().uuidString)"
        DatabaseBridge.shared.createSession(
            id: sid, projectId: ChatSession.standaloneProjectKey,
            title: "keep me", directory: ChatSession.standaloneProjectKey)
        defer { _ = try? DatabaseManager.shared.deleteSession(id: sid) }

        let state = await MainActor.run { self.makeState() }
        // The exact UI path: "+" on a standalone row.
        await MainActor.run { state.startNewTask(in: state.standaloneWorkspace) }
        let kept = await poll({ state.sessions.contains(where: { $0.id == sid }) })
        #expect(kept, "standalone chat vanished after + on a project-less chat")
    }

    @Test func unknownWorkspaceLoadFallsBackToStandalone() async {
        let sid = "wipe-\(UUID().uuidString)"
        DatabaseBridge.shared.createSession(
            id: sid, projectId: ChatSession.standaloneProjectKey,
            title: "keep me", directory: ChatSession.standaloneProjectKey)
        defer { _ = try? DatabaseManager.shared.deleteSession(id: sid) }

        let state = await MainActor.run { self.makeState() }
        await state.loadSessionsFromDatabase(projectId: "no-such-workspace")
        let kept = await poll({ state.sessions.contains(where: { $0.id == sid }) })
        #expect(kept, "unknown workspace load must fall back to standalone instead of []")
    }
}
