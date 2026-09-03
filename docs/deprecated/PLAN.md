# Plan: Full Functional Parity with ZCode Interface — COMPLETED

> **Historical document.** Counts and details below reflect the state at completion time and are superseded by `docs/FEATURE_REGISTRY.md`.
> Corrections as of 2026-07-17: test suite has grown to ~489 `@Test` declarations in 107 suites; the Plus menu has **5** items (including `insertCommand`), matching `PlusMenuTests`; the empty state shows the **MiMo logo mark** ("mi"), not a "Z" watermark.

## Goal
Achieve complete functional parity between our MiMoMacOS app and the ZCode interface. Every button must work with real data from MiMo Serve API. No stubs, no placeholders.

## Status: ✅ ALL STEPS COMPLETED + AUDIT FIXES APPLIED

All 10 steps implemented. 152 tests passing across 34 suites.

---

## Completed Steps

### Step 1: Fix Model Selector — Real Models from API ✅
**Files**: `MiMoMacOSApp.swift`
- Default `selectedModel` changed from "GLM-5.2" to empty string
- `availableModels` starts empty, populated from API
- Models sorted alphabetically after load
- First model from API set as default

### Step 2: Fix Access Level Default ✅
**Files**: `MiMoMacOSApp.swift`
- Default changed from `.fullAccess` to `.askBeforeChanges`

### Step 3: Wire Send Message to API ✅
**Files**: `ChatPanelView.swift`, `MimoServeClient.swift`
- Added `syncStart(message:)` method with body
- Added generic `post(_:body:)` method
- `sendMessage()` now calls API and displays response
- Loading state indicator added

### Step 4: Center Input Bar in Empty State ✅
**Files**: `ChatPanelView.swift`
- Input bar centered vertically when no messages
- Z watermark and "Start a new task" text above input
- Input moves to bottom when messages exist

### Step 5: Add Workspace Selector Dropdown ✅
**Files**: `ChatPanelView.swift` (new `WorkspaceDropdown`)
- Search field at top with live filtering
- List of workspaces with checkmark on selected
- "Open folder" option with NSOpenPanel
- "Remote connection" option

### Step 6: Add Workspace/Agent Chips Above Input ✅
**Files**: `ChatPanelView.swift`
- Workspace chip: "📁 {name} ▾" with dropdown
- Agent chip: "🔗 {model} ▾"
- Chips positioned above text input

### Step 7: Fix Sidebar Workspace Sessions + Duration ✅
**Files**: `SidebarView.swift`, `ParityTests.swift`
- Sessions filtered correctly
- Duration calculated from timestamps
- Tests for filtering and duration

### Step 8: Persist Settings to UserDefaults ✅
**Files**: `Settings.swift`, `MiMoMacOSApp.swift`
- `AppSettings` has `load()` and `save()` methods
- Settings auto-save on `didSet`
- Access level persisted
- Thinking level persisted

### Step 9: Wire Navigation History Back/Forward ✅
**Files**: `MiMoMacOSApp.swift`, `SidebarView.swift`
- Navigation stack tracks workspace changes
- `navigateBack()` and `navigateForward()` methods
- `canNavigateBack` and `canNavigateForward` computed properties
- Back/forward buttons disabled when at history bounds

### Step 10: Wire Sidebar Toggle ✅
**Files**: `ContentView.swift`, `SidebarView.swift`, `MiMoMacOSApp.swift`
- `sidebarVisible` state in AppState
- Toggle button animates sidebar
- ContentView conditionally shows sidebar

---

## Test Coverage

152 tests across 34 suites:
- Model Selector Parity (4 tests)
- Access Level Parity (2 tests)
- Send Message Parity (2 tests)
- Workspace Dropdown Parity (3 tests)
- Workspace Chips Parity (4 tests — added chip label tests)
- Sidebar Session Parity (2 tests — fixed filter logic)
- Settings Persistence Parity (3 tests)
- Navigation History Parity (4 tests — rewritten to test AppState)
- Sidebar Toggle Parity (1 test — rewritten to test AppState)
- Input Bar Position Parity (2 tests)
- Plus Button Menu (4 tests)
- Plus menu count now matches ZCode (3 items)
- PlusMenuView component created (was missing, caused build failure)
- Agent chip added to input bar
- Remote connection option added to workspace dropdown
- Plus extra tests for API, models, git, SSE, message flow, etc.

---

## Verification

1. ✅ `swift build` — Clean build
2. ✅ `swift test` — 152 tests pass
3. Model selector shows real models from API
4. Default access level is "Ask before changes"
5. Send message calls API, response appears in chat
6. Empty state: input centered, Z watermark visible
7. Workspace dropdown: opens, search works, "Remote connection" option present
8. "Open folder" → file picker opens
9. Agent chip shows model name next to workspace chip
10. Sidebar: back/forward navigation works
11. Sidebar collapses/expands with animation
12. Settings persist after restart
13. PlusMenuView component renders correctly

## Audit Fixes Applied

- Fixed build-breaking missing `PlusMenuView` component
- Removed extra `.insertCommand` case from PlusMenuItem (ZCode has 3 items)
- Added agent chip ("🔗 {model} ▾") to CenteredInputCard
- Added "Remote connection" option to WorkspaceDropdown
- Fixed `sessionsFilteredByPath` test to use actual path matching
- Rewrote navigation tests to test AppState instead of plain arrays
- Rewrote sidebar toggle test to test AppState
