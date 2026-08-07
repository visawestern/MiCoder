# Devil's Advocate Audit — Round 24 (2026-08-07)

## Summary

- **Status**: 4 issues found, 4 fixed, 0 remaining
- **Tests**: 1726 tests / 236 suites — all green (was 1716/234)
- **Build**: `swift build` — green

## Problems Found & Fixed

### P1 — DatabaseBridge.saveMessagePart: stepStart bypassed the injected inserter (HIGH)

**File**: `MiCoder/Sources/Services/DatabaseBridge.swift:328-334`

**Problem**: In `saveMessagePart(_, messageId:, sequenceOrder:, insert:)`, the `.stepStart` case called `try db.insertMessagePart(...)` directly (the legacy global `DatabaseManager`) instead of the `insert` closure parameter. When an active project was set via `setActiveProject`, every other part type correctly routed to the project's own database — but `stepStart` parts silently landed in the legacy global DB. The project database was missing data, and the global DB accumulated orphaned rows.

**Why real**: The `insert` closure exists precisely to abstract over "which DB writes to" (project vs. legacy fallback). The `.stepStart` case was the only branch that ignored it.

**Fix**: Replaced the direct `db.insertMessagePart(...)` call with `try insert(partId, messageId, "step_start", ...)` — the same closure every other branch uses.

**Tests**: 2 new tests in `DatabaseBridgeProjectRoutingTests` — one verifies `stepStart` lands in the project DB, the other verifies ALL 6 part types route correctly. Both red before the fix, green after.

### P2 — Duplicate doc comment in DatabaseManager.getSessionGoal (LOW)

**File**: `MiCoder/Sources/Services/DatabaseManager.swift:546-547`

**Problem**: The doc comment `/// Read a session's persisted goal.` appeared twice above `getSessionGoal(sessionId:)`. Copy-paste artifact.

**Fix**: Removed the duplicate line.

### P3 — Message.reasoningDuration kept growing after reasoning completed (MED)

**File**: `MiCoder/Sources/Models/Message.swift:108-111`

**Problem**: `reasoningDuration` computed `Date().timeIntervalSince(startedAt)` — measuring from start to *now*, not to when reasoning actually finished. A message whose reasoning took 5s would correctly show ~5s at first, but 60s later it would show ~65s. The value was never frozen at completion.

**Fix**: Added an optional `reasoningEndedAt: Date?` field. `reasoningDuration` now uses `reasoningEndedAt ?? Date()` as the end timestamp — live while reasoning is in progress, frozen once the end is recorded. The field flows through the `init` with the same default-nil contract as `reasoningStartedAt`.

**Tests**: 4 new tests in `ReasoningDurationTests` — grows while in-progress, freezes at `reasoningEndedAt`, nil without start, approximates elapsed without end.

### P4 — ProjectWebToolExecutor.todoRead/todoWrite were stubs (HIGH)

**File**: `MiCoder/Sources/Services/ProjectWebToolExecutor.swift:141-146`

**Problem**: The `todo_read` and `todo_write` tools (part of the emulated web-tool protocol, `WebEmulatedTool.todoRead/todoWrite`) returned `"(todo list not yet implemented)"` / `"(todo write not yet implemented)"` — hardcoded stubs. A web model issuing `todo_write` to track its work plan got back a failure string and could not use the tool.

**Why real**: The tools are declared in the protocol enum, documented in the system preamble (`"Read the current todo list."`, `"Write/update the todo list."`), parsed from model output by `canonicalToolName`, and gated correctly by `WebToolAccessGate` — everything was wired except the actual execution.

**Fix**: Implemented real file-based persistence at `<project>/.micoder/todos.json`:
- `todoWrite(todosJson:)`: parses the JSON (accepts both a bare array and `{"todos": [...]}` wrapper), validates each todo has non-empty `id` + `content`, atomically writes pretty-printed JSON. Returns `"ok: saved N todos"` or a descriptive error.
- `todoRead()`: reads the file, returns a human-readable `[status] id: content` list, or `"[]"` when empty.

**Tests**: 4 new tests in `ProjectWebToolTodoTests` — write+read round-trip, empty read, replace semantics, invalid JSON error.

## Files Changed

| File | Change |
|------|--------|
| `MiCoder/Sources/Services/DatabaseBridge.swift` | P1 fix: stepStart uses `insert` closure |
| `MiCoder/Sources/Services/DatabaseManager.swift` | P2 fix: removed duplicate comment |
| `MiCoder/Sources/Models/Message.swift` | P3 fix: added `reasoningEndedAt`, froze duration |
| `MiCoder/Sources/Models/ChatSession.swift` | P3 fix: `durationLabel` shows real `0s` instead of `1s` |
| `MiCoder/Sources/Services/ProjectWebToolExecutor.swift` | P4 fix: real todoRead/todoWrite |
| `MiCoder/Tests/DatabaseBridgeProjectRoutingTests.swift` | P1 tests: 2 new routing tests |
| `MiCoder/Tests/ReasoningDurationTests.swift` | P3 tests: 4 new duration tests |
| `MiCoder/Tests/ProjectWebToolTodoTests.swift` | P4 tests: 4 new todo tests |

## Verification

```bash
swift build   # green
swift test    # 1726 tests / 236 suites — green
```

## Remaining Audit Scope

The following areas were reviewed and found clean this round:
- `AppState` / `AppState+Database` — navigation lock, provider cascade, session goal persistence
- `UndoRedoManager` / `ProjectUndoManager` — snapshot + undo stack
- `ProjectRegistryLogic` — dedup, relink, archive
- `LocalProviderConfig` / `LocalProviderLogic` — local provider model
- `SelectionRestoreLogic` — sticky provider/model preferences
- `SlashCommandExecutor` — slash command dispatch
- `AccessLevelPermissionLogic` — permission mapping
- `UsageStatisticsAggregator` — usage stats aggregation
- `ProjectDatabaseManager` — per-project SQLite storage
- `SQLiteSafeQuery` — safe row iteration

Next round: continue auditing the Views layer (SettingsView, ChatPanelView, SidebarView) and remaining Services for dead code, logic bugs, and UX inconsistencies.
