# MiCoder — Feature Test Report (canonical)

Date: 2026-08-13 · Method: every user story from `FEATURE_SPREADSHEET.csv` verified against actual code, per-screen checklists, and the full test suite (1849 tests, 262 suites at the last macOS baseline).

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


## Round 32 (2026-08-13) — mimo-auto and embedded web send recovery

The user reported that ordinary `mimo-auto` sending and every web provider were unusable. A source-level manual audit of the send chain and all web-provider controls found the following concrete defects:

| ID | Defect | Fix | Status |
|---|---|---|---|
| WEB-01 | Composer model selection changed only `AppState.selectedModel`; the browser driver used stale `WebProviderConfig.selectedModel`. | Added `WebProviderSelectionLogic`; `selectProvider` and `selectModel` now persist the same web model consumed by `runWebChatTurn`. | FIXED |
| WEB-02 | Web effort was not represented in the composer; `VariantMenu` only understood server/custom capabilities. | Added a dedicated `WebEffortMenu` backed by `WebProviderConfig.effort` and explicit effort persistence. | FIXED |
| WEB-03 | Element picker computed an updated selector but saved the old provider array. | Persist the result of `WebProviderStore.upsert`. | FIXED |
| WEB-04 | Model discovery waited for Kimi-only `div.model-item`, despite Qwen/ChatGPT catalog selectors. | Discovery now reads visible vendor option elements and uses catalog `modelItem`/`newChatTexts` metadata. | FIXED |
| WEB-05 | Model/effort injection failures were shown as notes while the message was still sent with an unknown selection. | Failed injection is now a blocking error; text is not typed and send is not clicked. | FIXED |
| WEB-06 | `typeText`/send click could silently target no element. | Driver verifies input and send selectors before acting and returns an actionable selector error. | FIXED |
| WEB-07 | Stop cancelled the app task but did not stop the vendor page. | Added browser `stopGeneration()` with stop-button and Escape fallback, wired to the persistent WKWebView. | FIXED |
| WEB-08 | Persistent chat WKWebView was created but not attached to the window hierarchy during normal chat sends. | ChatPanelView now keeps the active provider web view attached in a tiny non-interactive host view. | FIXED |
| MIMO-01 | Serve path could leave an empty assistant bubble while waiting for SSE. | Added visible thinking placeholder and 90-second timeout with a clear MiMo Serve diagnostic. | FIXED |
| MIMO-02 | Compatible serve response envelopes and bare text could decode to an empty array. | Added tolerant decoding for `messages`, `data`, `message`, and `text` envelopes. | FIXED |
| UX-01 | Transport picker offered Chrome/CDP even though production send always used WKWebView. | Replaced misleading picker with a clear “In-app browser — WKWebView” status. | FIXED |
| UX-02 | Custom-model remove buttons were rendered for discovered models and acted as no-ops. | Buttons now appear only for `manuallyAddedModels`. | FIXED |
| UX-03 | Remove provider had no confirmation and left saved cookies on disk. | Added destructive confirmation and session-store cleanup. | FIXED |

The complete static button inventory is stored in `docs/ui_controls_inventory_2026-08-13.txt`, and the detailed source audit is stored in `docs/WEB_SEND_UI_AUDIT_2026-08-13.md`. Full macOS/WebKit runtime verification remains separate from the Linux sandbox because SwiftUI, AppKit, and WebKit are unavailable here.


## Round 33 (2026-08-13) — screenshot-driven provider correction

The user provided macOS screenshots showing that Round 32 was not sufficient in the real app. The screenshots showed a DNS failure for MiMo Auto, empty answers from web providers, ChatGPT failing on `effort selector not found`, and ToS acknowledgement checkboxes still visible in provider cards.

| ID | Confirmed root cause | Correction | Status |
|---|---|---|---|
| MIMO-04 | `MiMoAutoClient` used the invalid `https://api.mimo.ai/v1` host. | Paid route now uses the official `https://api.xiaomimimo.com/v1` endpoint and both `api-key` and Bearer auth headers. | FIXED |
| MIMO-05 | Empty API key was treated as a successful free/connected state and a synthetic `mimo-auto` model was always kept. | Readiness now requires a successful route check; stale/synthetic models are cleared. | FIXED |
| MIMO-06 | The current official MiMo Code source declares the anonymous free `mimo-auto` API sunset at `2026-07-26T10:00:00Z`. | MiCoder now blocks the ended free route with an explicit message and directs the user to a Xiaomi API key instead of pretending free access works. | FIXED |
| WEB-12 | Browser bridge could return the last empty wrapper node, producing an empty assistant bubble. | `readText` now selects the last visible non-empty node. | FIXED |
| WEB-13 | Missing effort control was treated as a send-blocking failure for providers/models that do not expose it. | Effort is optional; the driver only fails when a visible effort control exists but its selected option cannot be confirmed. | FIXED |
| UX-04 | `acknowledgedToS` Toggle remained visible in `WebProvidersSection`. | Removed the Toggle. The legacy Codable field remains only to decode old settings and is ignored at runtime. | FIXED |
| UX-05 | Composer exposed synthetic Low/Medium/High effort values before live discovery. | Effort menu is hidden until the provider page reports real effort levels. | FIXED |

Validation completed in the Linux environment: `git diff --check`, registry analysis, shell syntax checks, and source scans for the old endpoint, fake free fallback, and ToS Toggle. A second macOS/Xcode build is still required to verify SwiftUI/WebKit compilation and real browser behavior.


## Round 34 (2026-08-13) — MiCoder Auto Free on OpenCode Zen Big Pickle

The Xiaomi anonymous MiMo Auto channel is no longer a valid default route. This round completes the replacement with the renamed **MiCoder Auto Free** provider backed by OpenCode Zen's temporary free-model catalog. A live probe confirmed that OpenCode's `/models` endpoint and anonymous free route work without an API key; MiCoder still treats availability as revocable and selects only trusted free IDs.

| ID | Confirmed issue or requirement | Correction | Status |
|---|---|---|---|
| MIMO-04 | The previous implementation still contained Xiaomi paid/free endpoints and bootstrap logic after the provider rename. | Replaced the client with anonymous `https://opencode.ai/zen/v1`, `GET /models`, and `POST /chat/completions`; no Authorization header is required for the free route. Xiaomi bootstrap, sunset timestamp, fingerprint, and synthetic free route were removed. | FIXED |
| MIMO-05 | The renamed provider still advertised one model and could not adapt when free models changed. | `MiCoderAutoFreeProvider` now intersects the live catalog with trusted temporary free IDs, prioritizes `big-pickle`, and exposes current alternatives such as DeepSeek V4 Flash Free, MiMo V2.5 Free, Hy3, Laguna, Ling, and Nemotron free models. | FIXED |
| MIMO-06 | Users could not distinguish a missing/retired free catalog from a working provider. | Settings now shows the anonymous live free-model list, refresh control, Free catalog ready/unavailable status, fallback policy, and a data-use availability warning without an API-key gate. | FIXED |
| FAILOVER-01 | A retired model, HTTP 429/rate limit, or repeated transient failures could leave the user stuck on one free model. | Model-unavailable and rate-limit errors switch immediately to the next live free model; generic errors switch after five consecutive failures. The chosen alternative is persisted and a visible switch notice is streamed into the assistant response. | FIXED |
| APP-07 | Stored `mimo-auto` provider preferences would become orphaned after the rename. | `migrateLegacyPreferences()` maps both `selectedProviderID` and `preferredProviderID` from `mimo-auto` to `micoder-auto-free`; the model fallback is `big-pickle`, never the provider ID. | FIXED |
| PROMPT-04 | Direct AutoFree requests had no provider-level system prompt path. | Added a persisted system prompt field/editor; the store inserts it as an OpenAI-compatible `system` message before the user messages. | FIXED |
| TEST-34 | Tests still asserted the old Xiaomi/free-channel contract. | Replaced them with contract tests for provider identity, anonymous catalog allow-list, Big Pickle priority, immediate rate-limit/model switching, five-failure threshold, OpenCode endpoint, and Codable system-prompt state. | FIXED |

The canonical registry was updated with the renamed BUG-01 behavior and new `PROV-13`, `PROV-14`, `UX-06`, and `PROMPT-04` stories. Linux can run source/registry checks but cannot compile SwiftUI/AppKit/WebKit; the final `./build-app.sh` and a real anonymous free send remain macOS verification steps.


## Round 35 (2026-08-13) — anonymous OpenCode free catalog and failover correction

The user clarified that OpenCode's free route works without an API key. A live probe confirmed that `GET https://opencode.ai/zen/v1/models` returned HTTP 200 and the same 61-model catalog without an `Authorization` header and with `Bearer anonymous`. The implementation and documentation were corrected accordingly.

| ID | Requirement | Correction | Status |
|---|---|---|---|
| ANON-01 | MiCoder must not block the free route behind an API-key form. | Removed AutoFree API-key state, input controls, key validation and Authorization header. The app discovers the anonymous catalog and uses only the trusted temporary free IDs. | FIXED |
| ANON-02 | Big Pickle may disappear while other free models remain. | Added ordered candidates: Big Pickle first, followed by DeepSeek V4 Flash Free, MiMo V2.5 Free, Hy3, Laguna, Ling, and Nemotron free models. The live `/models` response is intersected with this allow-list. | FIXED |
| FAILOVER-02 | HTTP rate limits and model-unavailable responses should not strand the user. | HTTP 429/rate-limit and model-unavailable errors switch immediately to the next live free model. | FIXED |
| FAILOVER-03 | Repeated generic errors should eventually trigger a switch. | Five consecutive generic failures switch to the next candidate; the counter resets after a successful stream or explicit model selection. | FIXED |
| UX-07 | The user needs to understand why and where the provider switched. | Settings lists available free models and fallback policy; the assistant stream receives a visible switch notice; status text records the selected model and failure reason. | FIXED |

The canonical registry now includes `PROV-15`. The previous Round 34 key-gated statements remain as historical work in the report but are superseded by this round. A macOS/Xcode build and a real anonymous send are still required for runtime confirmation because the Linux sandbox lacks SwiftUI, AppKit, WebKit, and Xcode.


## Round 36 (2026-08-13) — model workspace and provider settings UX correction

The screenshots exposed three concrete settings defects: a localized successful connection test was classified as an error because the UI searched for the English word “Success”; the provider details column could grow into the models column; and the model Parameters menu item had an empty action. The same review also required model management controls that were missing from the previous implementation.

| ID | Confirmed issue or requirement | Correction | Status |
|---|---|---|---|
| UX-08 | Provider types were rendered as one long list and could not be collapsed predictably. | Added real `DisclosureGroup` sections for built-in, custom, web and local providers, with independent expanded state. | FIXED |
| UX-09 | A Russian/localized success message did not contain the English word `Success`, so the successful result appeared red. | Added an explicit `testSucceeded` state and a prominent green `Connection verified` banner; red is reserved for actual failures. | FIXED |
| LAYOUT-04 | Provider details could extend below its fixed grid and visually overlap the models list. | Wrapped the details card in its own `ScrollView` and gave wide/compact layouts explicit bounded heights. | FIXED |
| MODEL-16 | The model Parameters menu action did nothing. | Added an inline editable panel that loads provider metadata, displays context/output/capability values, validates overrides, persists them through `ModelCallParametersStore`, and applies them to AutoFree requests. | FIXED |
| MODEL-17 | The model list had no filtering or sorting and used passive headers instead of spoilers. | Added search filtering, sorting by name/context/reasoning/tools, and real `DisclosureGroup` sections for model prefixes. | FIXED |
| MODEL-18 | A custom-provider model could not be removed from its row. | Added a trash icon to custom-provider model rows and an AppState mutation that persists removal and chooses a valid fallback when necessary. Live server/local/web catalogs remain read-only because their source owns the model list. | FIXED |
| PROV-16 | The free model list could become stale. | AutoFree now discovers eligible live `*-free` IDs from anonymous OpenCode `/models`, preserves Big Pickle priority, and exposes refresh plus last-updated status. | FIXED |

The Linux sandbox completed source scans, brace checks and `git diff --check`, but it cannot compile SwiftUI/AppKit/WebKit. A macOS/Xcode build remains required for final visual and compiler verification.


## Round 37 (2026-08-13) — separate OpenCode Zen provider

OpenCode Zen is now available as a named provider in addition to MiCoder Auto Free. The current official Zen documentation describes Zen as a normal provider with a hosted `/zen/v1` API, a live `/models` catalog, temporary free models, and paid chat-compatible models; it also documents other models on Responses, Anthropic Messages, and Google endpoints that must not be sent through the generic chat route.[1]

| ID | Requirement | Correction | Status |
|---|---|---|---|
| PROV-17 | Users should not have to type the OpenCode endpoint manually. | Added an OpenCode Zen provider preset and one-click action. The preset uses `https://opencode.ai/zen/v1`, discovers models, and appears in its own provider category. | FIXED |
| PROV-18 | Free and paid Zen models require different access handling and endpoint compatibility. | Anonymous mode exposes live temporary free IDs only. A saved Zen key additionally exposes documented chat-compatible paid IDs; Responses/Messages/Gemini model routes are excluded from this generic chat path. | FIXED |
| UX-10 | Users need to understand OpenCode Zen access state. | The details card shows anonymous free-only or key-enabled curated catalog status, and the provider is marked connected only after model discovery succeeds. | FIXED |

The source-level tests cover endpoint/type defaults and both access modes. A macOS build and live UI verification remain required because the Linux sandbox has no SwiftUI/AppKit/WebKit toolchain.

[1]: https://opencode.ai/docs/zen/ "OpenCode Zen official documentation"


## Round 38 (2026-08-13) — stable layout, honest detection, and background browser submit

The latest screenshot-driven review identified four remaining UX/transport defects. The fixes keep the existing visual language but remove state ambiguity and make the hidden browser path observable and deterministic.

| ID | Confirmed issue | Correction | Status |
|---|---|---|---|
| SID-20 | Sidebar width was updated from the already-mutated width on every `DragGesture` sample, so cumulative translation caused drift, overshoot, or collapse. | `SidebarResizeHandle` now captures `dragStartWidth` on gesture start, applies each translation to that stable baseline, and clears the baseline on end. | FIXED |
| UX-11 | `TopBarView` was always rendered by `ContentView`, while `ChatPanelView` added `ChatPanelCompactHeader` when no session existed, producing a double header. | Removed the compact panel header. The top bar is now the single header in both selected-session and no-session states. | FIXED |
| WEB-14 | The browser settings action was labelled as MiCoder Auto Free even though it performed local DOM scraping and did not call an AI model. | Renamed the area to Browser model detection, added an honest `Detect models` built-in DOM action, and added a separate `Ask free AI` action that sends visible page text to the anonymous Auto Free stream and parses returned model labels. Detection is now explicit rather than automatic on sheet appearance. | FIXED |
| WEB-15 | Background send used a plain value assignment and direct click, which modern React editors could ignore; model selection could fall back to an ambiguous dropdown; unchanged/empty DOM content could be reported as a model-empty response. | WKWebView now uses the native value setter, `beforeinput`/`input`/`change`, Enter keyboard events, and pointer/click dispatch. WebChatDriver uses only `modelButton` for model injection and only `effortDropdown` for effort injection, waits for the model menu to settle, fingerprints response DOM identity, and reports a submit timeout when no new response is observed. | FIXED |

Round 38 deterministic coverage includes the stable-baseline sidebar test, model/effort selector separation, successful injection ordering, repeated-text response identity, and iteration-limit behavior. Static validation passed with `git diff --check`, `python3 -m json.tool` for the web catalog, `bash -n build-app.sh`, and source scans for removed labels/fallbacks. The Linux sandbox has no Swift/Xcode/WebKit toolchain, so the final `./build-app.sh`, Swift test suite, and real Kimi/Qwen/ChatGPT background-send checks remain macOS verification steps.


## Round 39 (2026-08-14) — logged-out preflight regression found by real Swift harness

A real Swift 6.0.3 test run was performed in the Linux sandbox after installing the missing compiler/linker prerequisites. The complete macOS target could not compile because Linux has no SwiftUI or AppKit modules, but a Foundation-only harness compiled the current production WebChatDriver, WebProviderConfig, WebModelDiscovery, session manager, protocol emulator, parser, and the existing WebChatDriver/WebProviderSelection test files.

The first harness run reproduced the remaining failure exactly:

> `loggedOutInterrupts()` expected `.loggedOut`, but received `error("selectorNotFound(\"textarea\")")`.

The cause was ordering: `runTurn` attempted `typeText` before calling `checkInterruptions`, so a logged-out page with no composer masked the actionable session state as a missing-input error. The fix performs the session/captcha/input preflight before the first send. The existing captcha and logged-out tests now both pass, while the iteration-limit test remains green.

| Verification | Result |
|---|---|
| Foundation-only WebChatDriver/selection/session harness | **20 tests passed** |
| `loggedOutInterrupts()` after preflight fix | **Passed** |
| `iterationLimitStopsRunawayLoop()` after preflight fix | **Passed** in 5.011 seconds |
| Full MiCoder `swift test` on Linux | Cannot compile target: `SwiftUI` module unavailable; this is an environment limitation, not a test assertion failure |
| macOS `./build-app.sh` | Still requires the user's macOS/Xcode environment |


## Round 40 (2026-08-14) — ProviderType expectation updated after real macOS run

The user's macOS run completed the build and executed all 1,882 tests in 269 suites. The only failure was `ProviderConnectionTests.providerTypeAllCases()` in `SecurityThemeLogicTests.swift:399`: production `ProviderType.allCases` contained 12 cases while the test expected 11. The additional case is the intentional `.openCodeZen` provider introduced by the OpenCode Zen provider preset; it has explicit icon and default URL switch branches in `Settings.swift`.

The regression test now includes `.openCodeZen` in its expected case list. No production provider behavior was removed or hidden; the test expectation was stale. The full macOS `swift test` must be rerun after pulling the commit to confirm the expected 1,882/1,882 result.


## Round 41 (2026-08-14) — single explicit release version bump

The previous build script silently changed both the marketing version and the build number on every default release build. The new contract is explicit and reproducible: a normal `./build-app.sh` does not mutate `Info.plist`; a release operation must use `./build-app.sh --bump patch`, `--bump minor`, or `--bump major`. The selected operation increments `CFBundleShortVersionString` exactly once according to semantic versioning and `CFBundleVersion` exactly once. `--no-bump` remains accepted as a backwards-compatible no-op.

The existing two-component marketing version `2.119` was normalized to `2.119.0` without increasing the version or build. The next patch release therefore becomes `2.119.1` and build `118`, exactly once. Invalid semantic versions and non-numeric build numbers now fail before tests or compilation.


## Round 42 (2026-08-14) — screenshot-driven settings and sidebar UX overhaul

The screenshot audit identified four related interaction failures. The narrow sidebar workspace toolbar previously placed grouping, archive, sort, filter, search and view controls in one fixed horizontal row. It now uses `ViewThatFits`: wide sidebars retain direct buttons, while narrow sidebars expose one vertical-dots workspace-actions menu containing the complete set of secondary actions. The session row action menu also uses vertical dots.

The MiCoder Auto Free catalog previously rendered tall adaptive cards for every free model. It now shows a compact current-model summary first, followed by dense one-row model choices. Lock/unlock is available only for the selected model, while status and model identity remain visible for every row.

Provider management now assigns edit and delete ownership to the provider row itself. Custom and web providers expose pencil and trash controls directly beside the provider name; built-in providers remain protected. Deleting a web provider removes its stored configuration and saved session, while selecting the pencil action opens the existing provider detail editor rather than creating a duplicate card.

Provider categories and model groups no longer rely on tiny `DisclosureGroup` chevrons. Each group has a full-width accordion bar with a large expand/compress affordance and an explicit Show/Hide label. Model row actions use vertical three dots, eliminating the previous horizontal ellipsis ambiguity.

Static validation passed for the changed Swift files with `swiftc -parse`, the web catalog JSON parsed successfully, and `git diff --check` passed. Real macOS visual verification remains required for sidebar resizing, hit targets, provider deletion persistence, and live Auto Free selection because Linux cannot render SwiftUI/AppKit.
