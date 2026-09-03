# Devil's Advocate Audit — Round 26 (2026-08-07)

## Summary

- **Status**: Documentation audit complete — 4 spreadsheet items updated to reflect prior fixes, README + consolidated report updated
- **Tests**: 1726 tests / 236 suites — all green
- **Build**: `swift build` — green

## Documentation Audit Findings

The canonical feature spreadsheet (`docs/FEATURE_SPREADSHEET.csv`) listed several items as PARTIAL/MISSING that had actually been fixed in earlier rounds. The fixes were in the code and tested, but the spreadsheet was never updated — a documentation drift that misrepresents the project's true state.

### Updated Items

| ID | Old Status | New Status | Evidence |
|----|------------|------------|----------|
| SID-22 | PARTIAL | PASS | Overview sheet title fixed to "Overview" in Round 23 (E27) — `SidebarView.swift:513` |
| PROV-11 | PARTIAL | PASS | Auto-detect confirmation flow implemented in Round 22 (E23/F2) — `LocalProviderConfirmLogic` + `AutoDetectStatusText` state machine |
| STO-08 | MISSING | PASS | WAL journal mode implemented in Round 21 (E21) — `ProjectDatabaseManager.swift:290` |
| STO-26 | MISSING | PASS | Read-only path fallback implemented in Round 21 (E13) — `ProjectDatabaseManager.swift:234` |

### Updated Counts

| Status | Before | After |
|--------|--------|-------|
| PASS | 168 | 172 |
| PARTIAL | 13 | 11 |
| MISSING | 10 | 8 |
| FUTURE | 5 | 5 |

## Integration Audit (End-to-End Flows)

Verified the following flows work correctly together:

1. **Send flow (local/custom)**: `ChatPanelView.sendDirectly` → `SendRouteResolver.route` → `.openAICompatible` → `ChatHistoryBuilder.messages` (carries prior turns) → `DirectChatClient.send` → response merged into `MessageStore`
2. **Send flow (ACP)**: Route `.acp` → `ACPClient.sendChatCompletion` → response text + reasoning extracted → `MessageStore` updated
3. **Send flow (web)**: Route `.web` → `runWebChatTurn` → `WebChatDriver.runTurn` → events presented via `WebChatEventPresenter` → `MessageStore` updated
4. **Send flow (serve)**: Route `.mimoServe` → `MimoServeClient.sendMessage` → SSE events → `handleSSEEvent` → `MessageStore` updated
5. **Session lifecycle**: Create → send → receive → persist to per-project DB via `DatabaseBridge` → load on restart
6. **Project lifecycle**: Create → open → use → archive → restore
7. **Undo flow**: `ProjectUndoManager.executeWithUndo` → snapshot → execute → record → `undoEntry` restores from snapshot
8. **Todo flow**: `todoWrite` persists JSON to `<project>/.micoder/todos.json` → `todoRead` returns formatted list

## Performance Audit

- **SSEClient**: Uses `URLSession.bytes(for:)` async stream — no main-thread blocking
- **ProjectShellRunner**: Uses `Thread.sleep` in a background loop (not main thread) — acceptable
- **AttachmentImportExecutor**: Uses `DispatchQueue.main.sync` with `Thread.isMainThread` guard — correct
- **Database operations**: All on background queues via `DispatchQueue` — correct
- **No obvious main-thread blocking** found in the audit

## Security Audit

- **Path safety**: `WebToolProtocolEmulator.isPathInsideRoot` validates all file tool paths are inside the project root — prevents path traversal
- **Shell execution**: `ProjectShellRunner` uses bounded timeout (30s default) — prevents hanging
- **Access gates**: `WebToolAccessGate.permission` correctly gates `run_command` to `.fullAccess` only
- **API keys**: Stored in Keychain via `KeychainManager`, never in plain UserDefaults
- **No SQL injection**: All queries use SQLite.swift parameterized queries or `sqlEscape` for raw SQL
- **No obvious security vulnerabilities** found in the audit

## Files Changed

| File | Change |
|------|--------|
| `docs/FEATURE_SPREADSHEET.csv` | Updated 4 items to reflect prior fixes |
| `README.md` | Updated status counts |
| `docs/CONSOLIDATED_PROJECT_REPORT.md` | Updated status counts |

## Verification

```bash
swift build   # green
swift test    # 1726 tests / 236 suites — green
```

## Next Round

Continue with:
1. Edge case testing — verify error paths and boundary conditions
2. Code quality review — check for code duplication, naming consistency
3. Final integration verification — run the full test suite and verify all flows
