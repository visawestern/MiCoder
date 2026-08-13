# MiCoder — Feature Test Report (canonical)

Date: 2026-08-10 · Method: every user story from `FEATURE_SPREADSHEET.csv` verified against actual code, per-screen checklists, and the full test suite (1849 tests, 262 suites).

Canonical status source: `docs/FEATURE_SPREADSHEET.csv` (single spreadsheet — the /goal deliverable).
This report documents the **errors found** (Phase 2), which Phase 3 fixes.

---

## Baseline

- Full test suite: `swift test` → 1849 tests in 262 suites, **all passing** after the 2026-08-10 routing/schema fixes.
- Feature status rollup: 168 PASS · 13 PARTIAL · 10 MISSING · 5 FUTURE.
- PASS features with NO automated test coverage (25 — need manual/verification attention): APP-01..04, SID-02..10, SID-12..18, SID-21, CON-02/03/05, INP-07, SRCH-03. These are UI wiring claims verified by code reading in this report, not by unit tests.

---

## Confirmed errors (Phase 2 findings — each verified in code, file:line)

### Category A — Data loss (most severe)

| ID | Error | Evidence | Plan ref |
|----|-------|----------|----------|
| E01 | **Images silently dropped on OpenAI-compatible send path** (Ollama, OpenCode, Local Agent, custom OpenAI providers): `DirectChatMessage.content` is `String` only; ChatPanelView builds real image parts but only the serve branch uses them. **FIXED (Phase 3)** — `DirectChatMessage.parts`, `serializedContent()`, `imageParts(for:)`; `ChatHistoryBuilder.messages(parts:)`; wired into `ChatPanelView` openAICompatible branch. Tests: `E01MultimodalDirectChatTests` (5). | `DirectChatClient.swift`, `ChatHistoryBuilder.swift`, `ChatPanelView.swift` | Раздел 9 п.10(c) |
| E02 | **Two different UUIDs for one project folder**: `createNewProject` mints UUID, `addWorkspace` mints a second UUID → same folder appears as two projects. **FIXED in Round 14** (canonical path id). | `MiCoderApp.swift` (fixed) | Раздел 8 п.5/17/18 |
| E03 | **Legacy DB → per-project DB migration never runs in production** — `ProjectDatabaseMigrator.migrate` is only called from tests; existing users keep everything in the single global DB. **RESOLVED BY REMOVAL (user directive 2026-08-02)** — clean slate: `ProjectDatabaseMigrator` + `LegacyDataMigrator` deleted; the app is HTTP-only with no legacy single-file history to migrate. | deleted files | Раздел 7 п.6 (superseded) |
| E04 | **`integrityCheck()` never invoked on project open** — corruption is never detected at open time; no restore-from-backup offer. **FIXED (Phase 3)** — `ProjectOpenIntegrity.checkOnOpen` runs in `selectedWorkspace.didSet` on every project open; `.corrupt` raises `AppState.projectIntegrityAlert` → ContentView alert offers restore from the latest auto-backup (`restoreLatestBackup` evicts the pooled connection, removes stale `-journal`/`-wal`). Tests: `E04ProjectOpenIntegrityTests` (7). | `ProjectOpenIntegrity.swift`, `MiCoderApp.swift`, `ContentView.swift` | Раздел 8 п.48 |
| E05 | **`shouldAutoImportFromCLI` never consulted** — the reset-bug safety flag is dead; no import path checks it. **RESOLVED BY REMOVAL (user directive 2026-08-02)** — `autoImportFromCLI` deleted end-to-end (registry model, DB column, `setAutoImportFromCLI`/`shouldAutoImportFromCLI`, `StorageResetLogic` CLI scopes + flags, Settings reset buttons, AppLocalization keys); there is no CLI import in the HTTP-only clean-slate architecture. | ProjectRegistryLogic / DatabaseManager / StorageResetLogic / AppState+Database / SettingsView | Раздел 8 п.14/15 (superseded) |
| E06 | **Call parameters lost on serve path** — `MessageSendOptions.requestBody` has no temperature/max_tokens/top_p; **and on ACP path** — `ACPClient.sendChatCompletion` body has none either. **FIXED (Phase 3)** — `MessageSendOptions.requestBody(parts:parameters:)`; `MimoServeClient.sendMessage`; `ACPRequestBodyBuilder` (shared body builder with param merge); both ACP methods take `parameters:`; wired in `ChatPanelView` ACP + serve branches. Tests: `E06CallParametersTests` (5). | `MessageSendOptions.swift`, `ACPMessageTypes.swift`, `ACPClient.swift`, `MimoServeClient.swift`, `ChatPanelView.swift` | Раздел 9 п.49 |
| E07 | **`costUSD` hardcoded nil** for every usage point despite `sessions.cost_usd` column existing — per-model cost always N/A. | `DatabaseManager.swift:946` | Раздел 10 п.14 |

### Category B — Stub / no-op behavior

| ID | Error | Evidence | Plan ref |
|----|-------|----------|----------|
| E08 | **5 slash commands are no-ops**: `/plan`, `/commit`, `/pr`, `/review`, `/context` fall through and just send the raw text to the model instead of opening CommitMessageComposer / GitPublishFlowLogic / plan mode / git review / context. **FIXED (Phase 3)** — `SlashCommandDispatcher` maps actions→real effects: `/plan` switches agent mode, `/commit` opens CommitDialogView, `/pr` opens a new PR dialog via `gh pr create` (publish wizard when no remote), `/review` opens ReviewPushDialogView, `/context` posts a context summary; `/test` names the detected test runner (TestRunnerDetector); single `AppState.pendingGitAction` sheet in ContentView. Tests: `E08SlashCommandDispatchTests` (14). | `ChatPanelView.swift:355-358`, `SlashCommandDispatcher.swift`, `GitHubCLIService.swift`, `GitPremiumDialogs.swift`, `ContentView.swift` | Раздел 5 п.12-16 |
| E09 | **`executeWithUndo` has zero production callers** — the per-project undo stack is always empty at runtime; snapshots never created during real tool operations. **FIXED (Phase 3)** — `ProjectWebToolExecutor` now takes an `undoManager` + `sessionId`; `write_file`/`edit_file` run through `executeWithUndo` (snapshot → execute → undo entry). Wired in `ChatPanelView.runWebChatTurn`. File-creation undo restores the "absent" state (`existed` flag in snapshot metadata) instead of failing on a missing `original`. Tests: `E09E10ToolUndoHistoryTests` (5). | `ProjectWebToolExecutor.swift`, `ProjectSnapshotManager.swift`, `ChatPanelView.swift` | Раздел 7 п.13/14 |
| E10 | **`request_history` never written in normal flow** — table + API exist, only `importBundle` writes it; applied edits/commands are never logged as requests. **FIXED (Phase 3)** — every successful `write_file`/`edit_file` tool operation appends a `file_edit` row (`payload` = `{"path":…,"operation":…}`) via `ProjectUndoManager.db.recordRequestHistory`; failed operations leave no trace. Tests: `E09E10ToolUndoHistoryTests` (5). | `ProjectWebToolExecutor.swift` | Раздел 7 п.12 |
| E11 | **MCP health check is a stub** — `MCPRegistryManager.updateHealthCheck` has zero callers; the green dot in the UI reflects `isEnabled`, not real health. **FIXED (Phase 3)** — `MCPHealthCheckLogic` (probe classification: http url vs stdio command+args; real PATH resolution like `which`; freshness/status mapping with 5 min max-age), `LiveMCPHTTPProber` (bounded real HTTP GET; 2xx/3xx = healthy, 4xx/5xx/transport failure = unhealthy), `MCPHealthChecker.check` persists `lastHealthCheck` + new `lastHealthStatus` into the registry; `InstalledMCPRow` runs the real probe on appear and colors the dot green/red/gray from actual liveness. `MCPServerEntry` now carries `url` + `args` from mcp.json. Tests: `E11MCPHealthCheckTests` (14). | `MCPHealthCheckLogic.swift` (new), `AgentResourceRegistryManager.swift`, `AgentResourcesLoader.swift`, `SettingsView.swift` | Раздел 4 п.5 |
| E12 | **`run_command` in web tool executor returns a message** instead of executing or gating by AccessLevel — approval exists but is never enforced. **FIXED (Phase 3)** — `WebToolAccessGate` maps AccessLevel → permission: read-only tools always allowed, `run_command` executes only at `.fullAccess`, approval message at lower levels (never silently executes). Real execution via `ProjectShellRunner` (bounded `/bin/zsh -c` process rooted at the project dir, stdout+stderr+exit code captured, 30s timeout, `(exit N)` marker). Wired `appState.accessLevel` in `ChatPanelView.runWebChatTurn`. Tests: `E12RunCommandGateTests` (9). | `WebToolAccessGate.swift` (new), `ProjectShellRunner.swift` (new), `ProjectWebToolExecutor.swift`, `ChatPanelView.swift` | Раздел 12 п.18 |

### Category C — Missing features (logged as MISSING in spreadsheet)

| ID | Feature | Plan ref |
|----|---------|----------|
| E13 | Read-only/system-path fallback (`~/.micoder/projects/<hash>/project.db`) | Раздел 8 п.51 |
| E14 | Whole-registry + settings export/import (machine migration) | Раздел 8 п.52 |
| E15 | Chunked/background delete of large projects with progress | Раздел 8 п.53 |
| E16 | `autoImportFromCLI` visible toggle in project row UI — **MOOT (user directive 2026-08-02)**: the flag and the CLI-import concept were removed entirely (clean slate). | Раздел 8 п.26 (superseded) |
| E17 | `updateSkill` / update-available detection | Раздел 3 п.5/7 |
| E18 | DependencyResolver + one-click install with dependencies | Раздел 3 Блок 2, Раздел 4 Блок 2 |
| E19 | Runtime dependency detection (dynamic "Requires Node 18+" instead of hardcoded) | Раздел 4 п.17 |
| E20 | FSEvents dynamic reindexing + persistent `file_index` + FTS over files | Раздел 7 п.22-27,33 |
| E21 | WAL journal mode on project.db | Раздел 7 п.46 |
| E22 | Per-model cost in usage statistics (aggregated across per-project DBs) | Раздел 10 п.13/14/28 |

### Category D — UX / correctness issues

| ID | Error | Evidence | Plan ref |
|----|-------|----------|----------|
| E23 | **Auto-detect adds a provider without user confirmation** — violates "без самодеятельности"; no "Подтвердить и добавить" step. **FIXED (Round 22)** — `LocalProviderConfirmLogic` + `PendingDetection` alert (Confirm/Cancel); cancel never adds; `AutoDetectStatusText` states detected/confirmed/cancelled; status line no longer lies after cancel; dedupe by host:port (`isDuplicate`). Tests: `E23E24AutoDetectConfirmationTests` (+14). | `SettingsView.swift:2459-2472` | Раздел 9 п.30 |
| E24 | `ProviderAutoDetector.overallTimeout` declared (10s) but **never enforced** — worst case is 4 sequential probes × 2s with no deadline. **FIXED (Round 22)** — hard deadline: each probe races the remaining budget and is cancelled in-flight (`probeOnce`); `URLSessionProviderProbe` cancellation-aware. Red test `hangingProbeCancelledAtDeadline` failed at 3.0s on old code → passes in 0.252s. | `ProviderAutoDetector.swift:30` | Раздел 9 п.33 |
| E25 | `SettingsIntegrationTests` asserts `.modelSettings` in `allCases` (count 11) — contradicts the plan's single-Providers-tab consolidation (case should be removed). **FIXED (Round 23)** — the case stays for back-compat, but the test now asserts the real UI contract: `SettingsTab.visibleCases` == 10 tabs without `.modelSettings` (the merged single Providers tab). | `SettingsIntegrationTests.swift:705-712` | Раздел 1 п.21 |
| E26 | User-facing "MiMo" strings remain: "Manage MiMo Agent .md command files", "…Ollama, OpenCode, or MiMo CLI/Serve", "Auto-commit from MiMo". **FIXED (Round 23)** — all three → "MiCoder"; stale comments cleaned. | `SettingsView.swift:1527,2384`, `BottomPanelView.swift:487` | Раздел 13 п.11 |
| E27 | Overview sheet still titled "Workspaces". **FIXED (Round 23)** — `Text("Overview")` (only `Text("Workspaces")` occurrence was the sheet title). | `SidebarView.swift:502` | Раздел 13 п.7 |
| E28 | `neutralizeServeBranding` is dead production code (defined + tested, never called). **FIXED (Round 23)** — removed the function + its test; red source-inspection test `noNeutralizeServeBrandingDeadCode`. | `LocalProviderConfig.swift:111-119` | Раздел 1 п.7 |
| E29 | Storage panel localization: entire panel is hardcoded English; only curated keys are translated. | `SettingsView.swift:1646-2120` | Раздел 8 п.34 |
| E30 | `DatabaseManager.getAllProjects(limit: 100)` — hardcoded 100-project cap on the sidebar list. | `DatabaseManager.swift:426` | Раздел 8 п.42 |
| E31 | Web provider captcha: rendered as image in chat but **no interactive solve bridge** (cannot click/type to resume). | `WebChatEventPresenter.swift` | Раздел 12 п.34 |

---

## Phase 3 plan (fix order)

1. **E01** — OpenAI-compatible path attachments (images + files) — TDD. ✅ R15
2. **E06** — call parameters on serve + ACP paths — TDD. ✅ R15
3. **E08** — wire real flows for /plan, /commit, /pr, /review, /context — TDD. ✅ R16
4. **E04** — invoke integrityCheck on project open + restore offer. ✅ R17
5. **E05/E03** — CLI-import flag + migrators REMOVED (clean slate). ✅ R18
6. **E09/E10** — wire executeWithUndo + request_history into real tool operations.
7. **E11** — real MCP health check with callers.
8. **E12** — enforce AccessLevel gate on run_command.
9. **E23/E24** — auto-detect confirmation + overall timeout.
10. **E25** — remove `.modelSettings` case + update tests.
11. **E26/E27/E28** — rebrand strings + Workspaces title + wire/remove dead code.
12. **E13/E14/E15** — read-only fallback, registry export/import, chunked delete.
13. **E17/E18/E19** — skill update, dependency resolver, runtime detection.
14. **E07/E22** — per-model cost + cross-project usage aggregation.
15. **E20/E21** — persistent file index + WAL.
16. **E29/E30/E31** — storage localization, remove 100 cap, captcha interactive bridge.

Each fix: red test → green → update spreadsheet status → update this report.

---

## Phase 3 progress

| Round | Fixed | Evidence | Status |
|-------|-------|----------|--------|
| R15a | E01 — OpenAI-compatible path attachments (images) | `E01MultimodalDirectChatTests` (5 green) + `DirectChatMessage.parts/serializedContent/imageParts`, `ChatHistoryBuilder.messages(parts:)`, `ChatPanelView` wiring | ✅ DONE |
| R15b | E06 — call parameters on serve + ACP paths | `E06CallParametersTests` (5 green) + `MessageSendOptions.requestBody(parts:parameters:)`, `MimoServeClient.sendMessage(parameters:)`, `ACPRequestBodyBuilder`, `ACPClient` both methods | ✅ DONE |
| R16 | E08 — slash commands perform real actions | `E08SlashCommandDispatchTests` (14 green) + `SlashCommandDispatcher`/`TestRunnerDetector`/`GitUIAction`/`PullRequestDialogView`/`gh pr create`/`AppState.pendingGitAction` sheet | ✅ DONE |
| R17 | E04 — open-time integrity check + restore-from-backup | `E04ProjectOpenIntegrityTests` (7 green) + `ProjectOpenIntegrity` wired into `selectedWorkspace.didSet` + ContentView alert | ✅ DONE |
| R18 | E03/E05/E16 — legacy migration & CLI-import removed (user directive: clean slate) | `ProjectDatabaseMigrator`/`LegacyDataMigrator` deleted; `autoImportFromCLI` flag, CLI reset scopes (`clearNoAutoImport`/`fullIncludingCLI`), `cliStorageRoot`, localization keys removed; single honest reset scope `.appCacheOnly`; tests updated (1653 green) | ✅ DONE |
| R19 | E09/E10 — undo + request_history wired into real tool operations | `E09E10ToolUndoHistoryTests` (5 green): write/edit tools now snapshot + record undo entries + `file_edit` request_history rows via `ProjectWebToolExecutor(undoManager:sessionId:)`; file-creation undo deletes the created file (`existed` flag in snapshot metadata); wired in `ChatPanelView.runWebChatTurn` (1658 green) | ✅ DONE |
| R20 | E11 — real MCP health check | `E11MCPHealthCheckTests` (14 green): probe classification (http/stdio), real PATH resolution, `LiveMCPHTTPProber` (2xx/3xx healthy), registry persistence of `lastHealthCheck`+`lastHealthStatus`, freshness mapping; `InstalledMCPRow` dot = real liveness (green/red/gray) (1672 green) | ✅ DONE |
| R21 | E12 — AccessLevel gate on run_command | `E12RunCommandGateTests` (9 green): `WebToolAccessGate` (read-only allowed, run_command only at fullAccess), `ProjectShellRunner` real bounded shell execution with stdout/stderr/exit, cwd=projectRoot, gated commands never execute; wired in `ChatPanelView` (1681 green) | ✅ DONE |
| R22 | E23/E24 — auto-detect confirmation + hard overall deadline | `E23E24AutoDetectConfirmationTests` (21 green): hard deadline race (`probeOnce`) cancels in-flight probe — red 3.0s → green 0.252s; zero/negative timeout → no probes; ACP stays ACP (`LocalProviderKind.acp`, `apiBaseURL=/acp/v1`, resolver `SendRoute.acp`, ChatPanelView consumes it); `AutoDetectStatusText` (cancel/confirm/detected/nothing/invalid); `isDuplicate` dedupe; warning п.34 no longer wiped. Full suite: **1701 tests / 231 suites green** | ✅ DONE |
| R23 | E25/E26/E27/E28 — tab contract, rebrand leftovers, overview title, dead code | `E26E27E28RebrandAndCleanupTests` (5 green, red→green source-inspection): no "Manage MiMo Agent"/"MiMo CLI/Serve"/"Auto-commit from MiMo" strings; `Text("Workspaces")` gone → "Overview"; `neutralizeServeBranding` dead code removed + its test; E25: `SettingsTab.visibleCases == 10` (no `.modelSettings`). Full suite: **1706 tests / 232 suites green** | ✅ DONE |

Remaining product work is limited to the explicitly tracked PARTIAL/MISSING/FUTURE rows in
`FEATURE_SPREADSHEET.csv`; no red test suite remains. Continue with E14/E15, E17/E18/E19,
E07/E22, E20/E21, and E29/E31 according to product priority.

## Round 25 final (2026-08-10) — canonical project routing

The post-fix loop found and fixed three storage defects: existing project
databases could lack `messages.cost_usd`, session storage depended on mutable
global active-project state, and invalid project ids could be redirected to
another store. Existing schemas now add the missing usage column on open;
session/message/archive operations resolve only through the owning project
database; invalid paths are rejected without legacy or unassigned storage.

Verification: `swift test` — **1849/1849 tests, 262/262 suites passed**.

---

## Round 24 final (2026-08-06) — DB/storage hardening and activity audit

Round 24 started with 4 failures across 3 suites. All were resolved and verified in the
full suite: **1713 tests / 234 suites — green**.

| Suite | Failing test | Isolated run | Cause |
|-------|--------------|--------------|-------|
| E13/E21 | Read-only fallback, stable hashed storage location, and WAL mode | **Passes** (5/5) | `open(projectPath:homeDirectory:)` now routes through `resolveDatabaseURL`; `databaseFileSizeBytes()` includes db/WAL/SHM sidecars; real read-only and WAL tests pass. |
| E30 | No silent 100-project cap | **Passes** (2/2) | `getAllProjects(limit: Int? = nil)` is unlimited by default while explicit limits remain honored. |
| E04 | Integrity detection and restore eviction | **Passes** (7/7) | Open-time check validates SQLite magic/header and probes read-only without schema mutation; scoped test eviction removes cross-suite pool races. |

Additional hardening:
- Test suites no longer call global `evictAll()` for their own temporary projects; they use
  scoped `evictProject(projectPath:)`, preventing parallel suites from deleting each other's
  pooled connections.
- The E23/E24 cancellation test now asserts the deterministic cancellation contract rather than
  an unsupported wall-clock number vulnerable to cooperative-thread-pool starvation.
- UI audit fixes: disabled Plan-agent action explains its unavailable capability; Git status now
  says “Commit failed — push was skipped.” instead of implying a push failure.
