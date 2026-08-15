# Round 58 — Shell/Status chain audit findings

## Scope

Audited the macOS SwiftUI shell/status chain from source: `MiCoderApp.swift`, `ContentView.swift`, `TopBarView.swift`, `StatusBarView.swift`, `ChatPanelView.swift`, `SidebarView.swift`, `DatabaseBridge.swift`, `ProjectDatabaseManager.swift`, `ProjectUndoManager.swift`, and the related pure logic contracts.

## Confirmed defects and TDD fixes

| ID | Root cause | Regression coverage | Fix | Verification status |
|---|---|---|---|---|
| SHELL-01 | Branch badge depended only on legacy `selectedProject`, while active workspaces use `selectedWorkspace`. | `ProjectHeaderContextLogicTests`: workspace-only and no-context cases. | `ProjectHeaderContextLogic.shouldShowBranch` is wired into `TopBarView`. | Foundation green; macOS visual runtime UNVERIFIED. |
| SHELL-02 | `serverConnected` was treated as a universal provider connection signal, so Serve health could show web/Auto Free/local/custom routes as connected. | `ProviderConnectionStatusLogicTests`: expired web, unavailable Auto Free, direct provider readiness. | `ProviderConnectionStatusLogic.isConnected` routes by selected provider family. | Foundation green; live WebKit/provider runtime UNVERIFIED. |
| SHELL-03 | Status endpoint label used global Serve host/port for every provider. | `ProviderConnectionStatusLogicTests.endpointLabelFollowsRoute`. | Serve host:port is shown only for Serve provider IDs; other routes show selected provider ID. | Foundation green; macOS visual runtime UNVERIFIED. |
| SHELL-04 | Status bar rendered only `appState.selectedModel`; web/Auto Free can keep the actual model in `effectiveSelectedModel()` while legacy selection is empty. | `StatusBarModelLogicTests`: effective-model preference, selected-model fallback, empty state. | `StatusBarView` uses `StatusBarModelLogic.displayModel(selectedModel:effectiveModel:)`. | Foundation green; macOS visual runtime UNVERIFIED. |
| SHELL-05 | Project-scoped session records did not carry `session_goal`; AppState wrote through legacy global DB, so workspace goal badges could disappear after reload. | `SessionGoalPersistenceLogicTests`: project precedence and legacy compatibility fallback. | Added `session_goal` to per-project schema/upgrade, `ProjectSessionRecord`, CRUD, DatabaseBridge hydration/write routing, and AppState write path. | Pure contract green; real SQLite/macOS persistence runtime UNVERIFIED on Linux. |

## Chain results

| Chain | Result | Notes |
|---|---|---|
| Sidebar toggle → `sidebarVisible` → `ContentView` conditional | PASS | Source-traced; visual runtime UNVERIFIED. |
| Goal toggle → `showGoal.toggle()` → right panel | PASS | `ContentView` conditionally mounts `RightPanelView`; state is intentionally layout-level. |
| Terminal toggle → `showTerminal.toggle()` → bottom panel | PASS | `ContentView` conditionally mounts `BottomPanelView`; state is intentionally layout-level. |
| Copy Chat → notification → `ChatCopyLogic.transcript` → pasteboard | PASS with runtime limitation | Empty transcript is intentionally ignored; clipboard write requires macOS runtime. Feedback resets after 1.5s. |
| Cmd+N → `startNewTask` → clear selection/state → first-send bootstrap | PASS by source | First send uses `prepareSessionBeforeAppending`; local/Serve routes establish `messageStore.currentSessionID` before appending. |
| Cmd+K → `showSearch` → `.sheet` → `SearchPaletteView` → `selectSession` | PASS by source | Definition is in `SidebarView.swift`; query matching uses FTS with title fallback. |
| Cmd+Option+Z → project undo manager → undo entry | PARTIAL | Correct project-scoped manager/entry chain is present, but command closure intentionally ignores result/errors and no direct macOS menu runtime was available. |
| Cmd+X/C/V/A → `NSApp.sendAction` / paste coordinator | PARTIAL | Source route is present; native responder/focus behavior requires macOS runtime. |
| Session title/workspace/branch | PASS by source | Workspace badge uses selected workspace; branch badge now handles workspace-only context. |
| Connection/model/endpoint status | PASS by contract | Route-specific connection and effective model contracts are tested. |
| Loading priority | PASS by source | `isStreaming` branch precedes `isLoading`, then idle. |

## Honest verification boundary

The Linux Foundation harness verifies deterministic logic contracts only. Full SwiftUI/AppKit rendering, native menu shortcuts, NSPasteboard behavior, WKWebView cookies/DOM automation, and real per-project SQLite behavior in the macOS target remain **UNVERIFIED** here and must not be reported as runtime PASS without a macOS build/run.
