# MiMoMacOS -> ZCode Parity Implementation Plan

> **Historical document (snapshot of 2026-06-20).** The "Current Evidence" below is stale: as of 2026-07-17 the app compiles and all tests pass; `[weak self]` was removed from `ChatPanelView`; Open folder / remote connection, session filtering, Search/Skills wiring, and live progress from `appState.currentSteps` are implemented. Current source of truth: `docs/FEATURE_REGISTRY.md`.

## Current Evidence

This plan replaces the outdated root `PLAN.md`, which claims full parity and passing tests while the current app does not compile.

Verified on 2026-06-20:

1. `swift build` inside the sandbox fails because Swift cannot write to `/Users/apple/.cache/clang/ModuleCache`.
2. `swift build` outside the sandbox reaches source compilation and fails in `MiMoMacOS/Sources/Views/ChatPanelView.swift` because `[weak self]` is used inside a `struct View`.
3. Local ZCode reference screenshots exist in the repository root: `screenshot_1_1.png`, `screenshot_2.png` through `screenshot_20.png`, and related setting/task screenshots.
4. The current public ZCode page at `https://zcode.z.ai/` confirms the same product surface: task/workspace sidebar, central task/chat area, model/depth controls, goal/progress, git tools, terminal, and settings surfaces.
5. The current SwiftUI code already contains partial implementations of those surfaces, but several are incomplete, disconnected, or branded as MiMo instead of matching the ZCode interaction model.

## Non-Negotiable Constraints

1. Preserve the existing sci-fi visual direction and color palette. Do not rewrite the theme into a plain ZCode clone.
2. Fix real compilation first; no parity work counts until `swift build` succeeds.
3. Every visible ZCode-inspired control must either be functional, visibly disabled with a clear reason, or removed until it is implemented.
4. Tests must cover app behavior or pure model logic that the UI depends on. Do not keep tests that only prove local dummy arrays.
5. Keep implementation scoped to this Swift package and existing MiMo Serve APIs unless a missing API is explicitly documented.

## Reference Surfaces From Screenshots

1. Empty workspace screen: `screenshot_1_1.png`, `screenshot_16.png`.
   - Sidebar with macOS window controls, back/forward, sidebar toggle.
   - `New task`, `Search`, `Skills`.
   - Workspace list with row hover actions and task duration.
   - Large outline `Z` watermark.
   - Centered input card with workspace selector, multiline prompt, plus menu, access level, model, thinking level, and send button.
   - Workspace dropdown with search, selected checkmark, `Open folder`, and `Remote connection`.

2. Active task screen: `screenshot_11.png` to `screenshot_15.png`.
   - Header with task title, workspace chip, branch chip, overflow menu, terminal toggle, and panel toggle.
   - Scrollable transcript with execution blocks, worked-time separators, file-change summaries, edit/copy affordances, and follow-up input.
   - Right floating/side panel for Git tools and Progress.
   - Model, thinking, access, and plus dropdowns anchored to the input.

3. Settings screens: `screenshot_2.png` to `screenshot_10.png`.
   - Full settings mode with left settings navigation and `Back to workspace`.
   - General, Code preview, Model settings, Skills, MCP Servers, Plugins, Commands, Indexing, Usage, and Onboard sections.
   - Model settings centered on Z.ai provider state, connection mode, quota cards, and model list.

## Current Gaps

1. Compilation
   - `ChatPanelView` uses `[weak self]` where `self` is a value type.

2. Main layout
   - `TopBarView`, `BottomPanelView`, and `GoalPanelView` exist but are not wired into `ContentView` in a way that matches active ZCode screenshots.
   - `showTerminal` and `showFiles` state does not render corresponding panels.
   - Right panel is only shown through `showGoal`, while ZCode exposes panel toggles from the task header.

3. Empty state and input
   - Empty state uses MiMo `mi` branding instead of the outline ZCode-style `Z` watermark.
   - Placeholder says `Ask MiMo anything...` in the centered input.
   - Centered input has an extra branch chip (`main`) that is not present in the empty-state reference.
   - Input proportions and max width do not match the reference.
   - Workspace dropdown currently lacks functional `Remote connection`; `Open folder` does not add a workspace.

4. Sidebar
   - `workspaceSessions` returns all sessions because of `|| true`.
   - `ChatSession` does not retain session directory/time, so workspace filtering and duration cannot be accurate.
   - Workspace row hover actions are missing.
   - `Search` and `Skills` actions are empty.
   - `New task` creates a session title but does not fully reset/select the working chat surface.

5. Task/chat flow
   - New send flow always creates a new session, even when a selected session exists.
   - Attached files are captured only as names and are not sent to the API.
   - Streaming and final response reconciliation can duplicate/lose parts because `currentAssistantMessageID` is local UI-generated while server events may use server message ids.
   - Progress and git summaries in the right panel are partly hardcoded.

6. Controls and menus
   - Plus menu is missing `Insert / command`.
   - Access menu lacks icons/descriptions in the menu body.
   - Model menu is present but must keep `Manage models`.
   - Thinking menu exists but should visually match the compact ZCode menu.
   - Agent mode control (`Build/Plan/Compose`) is not in the ZCode screenshots and should not clutter the input unless backed by a real feature.

7. Settings
   - The broad settings structure exists, but Model settings is MiMo Serve-focused rather than Z.ai-like.
   - Several settings sections are static placeholders.
   - Settings should keep the existing app palette while matching ZCode layout density and hierarchy.

8. Tests
   - Current parity tests are too shallow and in places encode the wrong behavior.
   - Tests must cover compile-sensitive model changes, workspace/session grouping, menu option completeness, settings persistence, and API request shape.

## Implementation Steps

### Step 1: Restore Compilation

1. Remove invalid `[weak self]` usage in `ChatPanelView`.
2. Rebuild with `swift build`.
3. Continue fixing compile errors until the executable target builds.

Acceptance:
- `swift build` succeeds outside sandbox.

### Step 2: Fix Data Models Needed For Parity

1. Extend `ChatSession` so sessions keep `directory`, `createdAt`, `updatedAt`, optional `branch`, and a duration label.
2. Map `MimoSessionResponse` into the richer session model.
3. Add helper logic for grouping sessions under the correct workspace by directory.
4. Update tests so workspace filtering proves real path grouping.

Acceptance:
- Sessions under `tm3` do not appear under unrelated workspaces.
- Duration labels such as `3d`, `2h`, `9m` are computed from timestamps.

### Step 3: Rebuild Main ZCode Layout Without Changing Theme

1. Make `ContentView` render the ZCode-like shell:
   - Sidebar.
   - Main chat/task area.
   - Optional right tools/progress panel.
   - Optional bottom terminal panel.
   - Status bar only if it does not conflict with the reference layout.
2. Add or reuse a task header for selected sessions:
   - task title.
   - workspace chip.
   - branch chip.
   - model/provider chip where appropriate.
   - terminal and side-panel toggles.
3. Keep current colors from `ZCodeColors.swift`; only adjust spacing, opacity, borders, typography, and layout.

Acceptance:
- Empty state, active session state, right panel, and terminal visibility are reachable from real controls.

### Step 4: Match Empty State And Input Bar

1. Replace the MiMo `mi` watermark with a large outline `Z` watermark.
2. Change centered placeholder to `Ask ZCode anything, @ to add files, / for commands, $ for skills, # related conversation`.
3. Remove empty-state branch chip unless a real branch selector is available in that state.
4. Normalize centered and bottom input controls:
   - plus menu.
   - access menu.
   - model menu with `Manage models`.
   - thinking menu.
   - send button state.
5. Add `/` to the plus menu.
6. Wire `Open folder` to a directory picker and append/select the workspace.
7. Wire `Remote connection` to the existing host/port connection flow.

Acceptance:
- The empty state visually matches the structure of `screenshot_1_1.png` and `screenshot_16.png` while preserving current theme colors.

### Step 5: Fix Sidebar Functionality

1. Correct session filtering by workspace path.
2. Add row state for selected workspace/session.
3. Add hover actions for workspace rows:
   - overflow.
   - task list/details.
   - new task.
4. Wire `Search` to a simple searchable command/task overlay or modal.
5. Wire `Skills` to the settings skills tab.
6. Make `New task` clear the selected session and focus the main input, or create/select a real server session if required by API flow.

Acceptance:
- Sidebar actions have observable behavior and no empty buttons remain in the main workflow.

### Step 6: Fix Chat/Session Send Flow

1. If a session is selected, send follow-up messages into that session instead of always creating a new one.
2. If no session exists, create a new session and select it.
3. Preserve queued sends after the first request becomes idle.
4. Reconcile streaming events and final response without duplicate assistant messages.
5. Surface API errors in a ZCode-like message row.

Acceptance:
- Sending a first prompt creates/selects a session.
- Sending follow-up text uses the selected session.
- Stop/cancel ends streaming and leaves the UI consistent.

### Step 7: Make Right Panel Data Real Enough

1. Keep `Git tools` panel layout close to screenshots.
2. Load additions/deletions from `/vcs/diff`.
3. Replace hardcoded progress steps with selected-session or local goal data when available.
4. If progress API is missing, show an empty/unknown progress state instead of fake project-specific Russian steps.

Acceptance:
- No unrelated hardcoded progress text appears.
- Git changes totals come from the API when connected.

### Step 8: Bring Settings Closer To ZCode

1. Preserve the current settings sections and dark/sci-fi palette.
2. Ensure settings sidebar matches screenshot ordering and selected-state density.
3. Rework Model settings toward the Z.ai provider layout:
   - provider list.
   - connection mode.
   - quota/model cards if data exists.
   - custom provider fallback if no Z.ai data exists.
4. Keep static placeholder sections visually honest: use empty states, not fake enabled data.

Acceptance:
- General, Code preview, Model settings, Indexing, and Usage match the screenshot structure closely enough to navigate and read without clipped text.

### Step 9: Strengthen Tests

1. Update compile-sensitive tests after model changes.
2. Add tests for workspace/session grouping and duration formatting.
3. Add tests for plus menu option completeness.
4. Add tests for access/thinking/model menu data.
5. Add tests for message request shape and selected-session follow-up behavior where possible without live server dependence.

Acceptance:
- `swift test` passes.
- Tests no longer claim parity by checking only dummy local arrays.

### Step 10: Visual And Runtime Verification

1. Build the app with `swift build`.
2. Run tests with `swift test`.
3. Launch or package the macOS app if the environment allows it.
4. Capture current UI screenshots and compare manually against:
   - `screenshot_1_1.png`.
   - `screenshot_11.png`.
   - `screenshot_14.png`.
   - `screenshot_2.png`.
5. Record any remaining non-blocking gaps in this document or a follow-up parity checklist.

Acceptance:
- Build passes.
- Tests pass.
- Main UI surfaces render without clipped or overlapping text at the default window size.
- Remaining gaps are explicit and not hidden behind a false "full parity" claim.
