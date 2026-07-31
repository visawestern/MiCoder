import XCTest
@testable import MiCoder

final class StorageResetCrashTests: XCTestCase {

    // Round 10 real claim: the crash happens when resetStorage() is called
    // while the navigation index is out of bounds (didSet during reset).
    // The current implementation does not reproduce the crash, but these
    // tests pin the invariant that nuclear-state clearing must keep the
    // navigation stack consistent.
    func testNavigationIndexBoundsAfterResetStorage() {
        let appState = AppState()
        let ws1 = Workspace(id: "w1", name: "One", path: "/tmp/one", tasks: [])
        let ws2 = Workspace(id: "w2", name: "Two", path: "/tmp/two", tasks: [])
        // Simulate browsing back/forward.
        appState.selectedWorkspace = ws1
        appState.selectedWorkspace = ws2
        appState.navigateBack()
        appState.navigateForward()
        // Now reset — the didSet will mutate navigationHistory.
        appState.resetStorage(scope: .appCacheOnly)
        XCTAssertNil(appState.selectedWorkspace)
        XCTAssertNil(appState.selectedSession)
        XCTAssertTrue(appState.navigationHistory.isEmpty)
        XCTAssertEqual(appState.navigationIndex, -1)
    }

    func testResetStorageMultipleTimes() {
        let appState = AppState()
        appState.selectedWorkspace = Workspace(id: "w1", name: "A", path: "/tmp/a", tasks: [])
        // Call twice — second call must not crash.
        appState.resetStorage(scope: .appCacheOnly)
        appState.resetStorage(scope: .appCacheOnly)
        XCTAssertTrue(appState.navigationHistory.isEmpty)
        XCTAssertEqual(appState.navigationIndex, -1)
    }

    func testResetStorageLeavesSettingsIntact() {
        let appState = AppState()
        let settings = appState.settings
        appState.resetStorage(scope: .appCacheOnly)
        XCTAssertEqual(appState.settings.httpProxy, settings.httpProxy)
        XCTAssertEqual(appState.settings.language, settings.language)
    }
}
