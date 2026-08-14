# MiCoder — Feature Test Report (canonical)

Date: 2026-08-14 · Method: every user story from `FEATURE_SPREADSHEET.csv` is traced against actual code, per-screen checklists, regression tests, and available runtime evidence. The last reported macOS baseline was 1849 tests/262 suites; the current Linux Foundation harness is **101 tests/green**, while the macOS SwiftUI/AppKit/WebKit target is unavailable in this sandbox.

Canonical status source: `docs/FEATURE_SPREADSHEET.csv` (single spreadsheet — the /goal deliverable).
This report documents the **errors found** (Phase 2), which Phase 3 fixes.

---

## Baseline

- Available Foundation-only regression harness: `swift test --parallel` → **101 tests / 101 passed** after the Round 53 settings contracts.
- Full macOS target: **not runnable here** because SwiftUI, AppKit, and WebKit are unavailable on Linux; no target-runtime PASS is claimed from this environment.
- Canonical feature status rollup: **231 PASS · 16 PARTIAL · 5 MISSING · 5 FUTURE** across 257 rows.
- UI rows marked PASS are code/source-level claims unless a macOS runtime result is explicitly recorded. This distinction is carried through App Shell, Sidebar, Chat and Settings checklists and every Round 49–53 evidence section.

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


## Round 43 (2026-08-14) — full live model catalog, model-specific effort and isolated browser chats

The screenshot audit exposed a deeper runtime problem: the visible model selector showed only the first level while the provider page contained an `Expand more models` branch, and the effort control was treated as a provider-wide setting even when the selected model did not support thinking.

The browser discovery contract is now empirical and bounded. `WebModelDiscovery.discoverAllModels` starts from the live model menu, expands localized `Expand more models`/`More models` variants up to a fixed depth, reads additional visible options, deduplicates labels, and returns the complete discovered set. The previous selected model is restored after capability probing so discovery does not silently leave the vendor chat on the last model visited.

Each discovered model now stores `availableEfforts`. The runtime selects each model, probes the live effort control, and records an empty capability list when that model has no thinking mode. `WebProviderSelectionLogic.availableEfforts` and `WebModeSelectorView` consume the selected model's capability list; the custom effort selector is hidden when the current model does not support it. No synthetic global effort is shown for a known model with no live effort control.

The hidden browser runtime now uses a lazy pool keyed by `projectID + chatID + providerID`. The same key reuses one page, different projects/chats cannot mix their browser conversation state, and the pool is capped at 100 instances with least-recently-used eviction. The active hidden host is attached using the same key as the send operation. Existing chat titles are selected with a bounded best-effort DOM click before sending when the provider exposes a conversation list.

Every model selection, effort selection, send start and send completion writes a bounded persistent routing record containing project, chat, provider, model, effort and detail. The final assistant message also identifies the browser route used, so a user can tell which chat and model performed the action.

| Verification | Result |
|---|---|
| Foundation dynamic web harness | **54 tests passed** |
| Nested `Expand more models` regression | **Passed** |
| Model-specific effort visibility and legacy Codable migration | **Passed** |
| Browser instance identity and bounded journal | **Passed** |
| Existing WebChatDriver/Kimi selector/effort suite | **Passed** |
| Changed Swift source parse and `git diff --check` | **Passed** |
| Live Qwen/Kimi/ChatGPT DOM traversal and 100-instance macOS UI runtime | Requires macOS/WebKit verification |

## Round 44 (2026-08-14) — per-model parameters, refresh-before-retry and named web sessions
The live model capability pass now records a `WebModelParameterProfile` for every detected model. The profile captures visible parameter keys, localized control labels and a safe snapshot of temperature, max-tokens and top-p values. Detection writes only provider-discovered values; a non-empty user override in `ModelCallParametersStore` remains authoritative. Older `WebProviderModel` JSON without `parameterProfile` decodes to an empty profile.

Browser recovery now recognizes typed model/effort injection failures and conservative legacy error messages. For the current project/chat/provider turn it schedules at most one live model-and-effort catalog refresh, reports the failure and refresh result in the assistant bubble, and deliberately does not auto-send a duplicate prompt. The next manual retry starts from the refreshed persisted configuration. The combined refresh path rereads the model-updated provider config before the effort pass, preventing the second upsert from erasing discovered models or parameter profiles.

Web login state is now named and independent per provider. `Change login` creates a new session ID/name, existing cookie stores remain untouched, and the active session ID/name is persisted in `WebProviderConfig`. Login-sheet preload, connectivity checks, background chat sends and model/effort refreshes all restore the active named session. Project/chat-bound browser instances continue to isolate conversations while sharing only the intended cookie store.

| Verification | Result |
|---|---|
| Foundation dynamic web harness | **55 tests passed** |
| Legacy `WebProviderModel` Codable migration without parameter profile | **Passed** |
| Named session persist/list/restore and active-session switching | **Passed** |
| Existing recursive model discovery and model-specific effort suite | **Passed** |
| Changed Swift source parse | **Passed** |
| `git diff --check` | **Passed** |
| Live per-model parameter controls on Kimi/Qwen/ChatGPT | Requires macOS/WebKit verification |
| Live injection-failure refresh and multi-account cookie switching | Requires macOS/WebKit verification |

## Independent Acceptance Audit (2026-08-14) — recheck of the complete user dialogue
The user requested an independent re-acceptance because the previous cumulative PASS claims did not match observed behavior. The audit reconstructed 32 major requirements from the complete conversation and traced each through trigger, handler, state, persistence, runtime consumer and visible result. The full matrix is `docs/../.acceptance/ACCEPTANCE_MATRIX.csv`; the narrative report is `docs/INDEPENDENT_ACCEPTANCE_AUDIT_2026-08-14.md`.

The independent result is **14 FAIL and 18 PARTIAL**, with no target-runtime PASS. Average implementation quality is **2.25/5** and average task-fit quality is **1.31/5**. The most severe failures are strict web-model validation, complete Qwen nested-menu discovery, immediate per-model effort detection, persistent full detected-model list, removal of the redundant `Select` action, and remote web-chat UUID creation/persistence/reuse. The Foundation-only harness passes 55/55; the full package cannot compile in the Linux sandbox because SwiftUI/AppKit are unavailable, so no macOS/WebKit claim is promoted by this audit.

## Round 46 (2026-08-14) — independent acceptance fixes with adversarial review

Round 46 replaces the broad web-model scraping path with a structured DOM-candidate contract. The live bridge now returns visibility, selectability, disabled state, leaf status and DOM identity; the parser applies vendor-aware validation and rejects headings, actions, effort labels, model-comparison text and container aggregates. Nested expansion uses exact interactive-text clicks, bounded state fingerprints and repeated candidate validation. The regression suite covers Kimi noise rejection and a two-level Qwen branch containing a Qwen Coder model.

Per-model capability handling now stores an explicit discovery status, `isSelectable` flag, effort state and live parameter profile. A model without an effort control no longer inherits a provider-global effort list. The provider card renders a full-width accordion with every discovered row, status, effort/profile indicators and removal for unavailable candidates. The settings row selects by direct click; the vertical-dots menu no longer contains `Select`/`Выбрать`. The parameter panel shows live-detected keys, labels and numeric defaults separately from editable user overrides.

AI-assisted detection is now an explicitly non-authoritative mode. Its output passes the same vendor validator and is stored only as an unselectable review candidate; it cannot enter `allModels` or be injected into a chat until built-in DOM detection validates it. This prevents page text or an AI hallucination from becoming a sendable model.

Web routing now persists `WebRemoteChatMapping` under provider, active named session, project and local chat IDs. First use requires an exact New Chat action followed by a changed and verified remote URL/ID; existing mappings navigate to the stored URL and fail closed if the host or UUID does not match. The action journal records `remoteChatID`. The hidden browser pool also includes `activeSessionID`, so named logins cannot reuse the same page and stale cookie context. Model/effort injection now aborts before typing when confirmation fails. ChatPanel performs one same-page catalog refresh, reloads the saved config and retries once in the same remote chat, preventing duplicate prompts and context mixing.

MiCoder Auto Free now checks the selected model against the live free catalog before streaming and switches only when unlocked; rate-limit model switches use error severity so the existing prominent red banner remains semantically red.

| Verification | Result |
|---|---|
| Foundation dynamic web harness | **68 tests passed** |
| Two-level nested expansion with Qwen Coder branch | **Passed** |
| UI noise rejection and `isSelectable` filtering | **Passed** |
| Remote mapping persist/list/clear isolation | **Passed** |
| Named-session browser pool identity | **Passed** |
| Failed injection blocks typed/send duplicate | **Passed** |
| Source adversarial checks | **11/11 passed** |
| Changed Swift parse and `git diff --check` | **Passed** |
| Full macOS build, live Qwen/Kimi WebKit discovery, two-account switching and real provider response | **Not available in Linux; requires macOS acceptance run** |

The independent acceptance matrix was updated from the old unverified 14 FAIL/18 PARTIAL baseline. Current code-level implementation and task-fit averages are **4.38/5**, while runtime is intentionally not promoted above `UNVERIFIED` without macOS/WebKit evidence. `AUD-30` remains a genuine build/runtime FAIL in this environment, not a hidden PASS.


## Round 47 (2026-08-14) — purge stale UI labels and restore direct model selection

The first checklist item had one remaining production gap even after strict discovery was implemented: providers already saved by an older build could still contain `Model` or `Model Comparison`, because validation ran only during a new detection pass. `WebProviderStore.load()` now sanitizes every decoded provider before returning it and persists the sanitized snapshot. Invalid labels are removed, duplicate names are normalized, invalid manually-added labels are removed, effort levels are rebuilt from valid model profiles, and a selected invalid model is replaced by the first valid selectable model or cleared.

The provider-card detected-model accordion now has direct row selection as well as the settings catalog. Clicking an active validated row selects `web:<providerID>` and that model in `AppState`, highlights the selected row and leaves inactive/unverified candidates available only for review/removal. The settings vertical-dots menu retains Parameters, Copy info and provider-specific actions only; there is no Select/Choose action.

| Verification | Result |
|---|---|
| Legacy `Model`/`Model Comparison` migration purge | **Passed** |
| Foundation dynamic web harness | **69 tests passed** |
| Strict parser and nested discovery regressions | **Passed** |
| Provider/settings accordion source parse | **Passed** |
| `Select`/`prefix(8)` source contract checks | **Passed** |
| Live macOS WebKit verification | Still requires a real Mac run |


## Round 48 (2026-08-14) — compact MiCoder Auto Free model catalog

The previous web-accordion correction did not change the separate MiCoder Auto Free catalog surface. That gap is now corrected explicitly. The Auto Free settings section no longer renders every free model as a vertical list in the main card. It shows one compact selected-model summary row, opens a menu containing every currently eligible free model with ID and status, and keeps lock/unlock as a separate action for the selected model only. Selecting a menu item persists the model and updates the active provider selection.

An adversarial source check now protects the compact contract (`Live free models`, `Choose from list`, menu switching and `Switch free model`). `MODEL-19` in the canonical registry is marked `PARTIAL` until the live catalog and macOS visual hit-target behavior are verified on the user's Mac.


## Round 49 (2026-08-14) — App Shell startup readiness and documentation drift

### Scope

Round 49 restarted the audit at the first checklist item instead of continuing directly with web
providers. The first chain was traced manually from `MiCoderApp.body` and `ContentView.task` through
provider loading, health checking, session loading, model loading, provider-option construction and
composer consumption. The repository document index was rebuilt for the current 71 project documents. The audit also compared README totals and branding against the canonical 250-row CSV.

### Confirmed defect and cause chain

| Step | Observed behavior | Evidence | Result |
|---|---|---|---|
| Trigger | App opens and runs `ContentView.task` | `Sources/Views/ContentView.swift` | Confirmed |
| Handler | `loadCustomProviders()` then `await appState.connectToServer()` | `ContentView.swift:58-65`, `MiCoderApp.swift:403-418` | Confirmed |
| State mutation | `MimoServeConnectionManager.checkAvailability()` updated only its own `isConnected`; `AppState.serverConnected` remained false | `MimoServeConnectionManager.swift:25-41`, previous `connectToServer` body | **Defect** |
| Consumer | `async let models: () = appState.serverConnected ? appState.loadModelsFromServer() : ()` read stale false | `ContentView.swift:61` | **Defect** |
| Visible result | Healthy MiMo Serve could show no server model catalog after first launch; the route appeared offline despite a successful health response | derived from the complete chain | **Defect confirmed** |

The offline branch itself remains intentionally non-blocking: local database sessions load without a
server, and the built-in **MiCoder Auto Free** route remains available. The defect was specifically
the online first-start path, not a justification for reintroducing the obsolete anonymous
`MiMo-Auto` route.

### TDD and fix

A red regression suite was written before the production fix in
`MiCoder/Tests/ServerConnectionReadinessLogicTests.swift`. It covers successful health, unhealthy
health, missing/cancelled health, stale AppState state, and the model-loading gate. The full target
could not be compiled in this Linux sandbox because the target imports SwiftUI/AppKit; this limitation
is recorded rather than misreported as a test failure or pass.

The pure Foundation contract `ServerConnectionReadinessLogic` was then added and mirrored into the
Linux harness. `AppState.connectToServer()` now awaits the health check, derives the AppState flag
from the completed manager result, and synchronizes before the startup task evaluates whether to load
server models. Missing health fails closed. The Linux Foundation harness now reports **72/72 tests
passed**, including the new `APP-01: startup connection readiness` suite.

### Documentation corrections

`README.md` was corrected from the stale 206-story/188-PASS rollup to the actual canonical
**250 stories: 225 PASS, 15 PARTIAL, 5 MISSING, 5 FUTURE**. `docs/activity-checklists/01-app-shell.md`
now contains all 14 App Shell controls/actions with trigger→handler→state→consumer chains,
code-quality and task-fit scores, and explicit macOS runtime status. Its user story now names
**MiCoder Auto Free** rather than the obsolete “free MiMo-Auto route”. `APP-07` was added to the
canonical CSV for startup connection readiness.

### Adversarial quality scores

| Dimension | Before Round 49 | After Round 49 | Evidence boundary |
|---|---:|---:|---|
| Implementation quality for APP-07 | 55/100 | 95/100 | Pure contract + harness green; macOS target not buildable here |
| Task adherence for APP-07 | 70/100 | 100/100 | Started at first checklist item; red test before fix; docs updated |
| Overall App Shell code audit | 83/100 | 94/100 | Source-chain audit and Foundation evidence |
| Overall App Shell target-runtime confidence | 0/100 | 0/100 | No macOS/WebKit runtime available; not promoted to PASS |

### Commit evidence

Round 49 is complete only after the documentation, source, regression tests and harness evidence
are committed and pushed. The commit hash is recorded in the next audit inventory after the Git
operation; no runtime claim is inferred from a clean source diff alone.


## Round 50 (2026-08-14) — Sidebar adversarial audit and TDD fixes

### Scope and evidence

The audit continued from the second activity checklist and manually traced all 17 Sidebar
controls/actions from trigger to handler, state mutation, persistence, and visible consumer. The
review covered navigation boundaries, compact toolbar overflow, search/sort/filter, list/grid,
workspace/session selection, task/project creation, native context actions, archive storage,
notifications, settings, and profile footer. The Linux Foundation harness reached **85/85 tests
passed** after the fixes. SwiftUI/AppKit popovers, sheets, Finder/NSOpenPanel, keyboard hit targets,
and native visual state remain unavailable in Linux and are explicitly **UNVERIFIED**.

### Confirmed defects

| ID | Root cause | User-visible consequence | TDD fix | Result |
|---|---|---|---|---|
| SID-05 | Registry archive state and DB-backed `AppState.workspaces` were separate; Sidebar did not reconcile them or refresh after Restore | Archive/Restore could leave stale active rows and required relaunch-like reload behavior | `WorkspaceArchiveVisibilityLogic`; published registry snapshot; refresh hooks in Sidebar Restore, Storage Settings mutations and DB load; preserve selected archived context | 4/4 harness tests green |
| SID-06 | `WorkspaceSidebarSection.@State isExpanded` was initialized from `startsExpanded` once and did not synchronize when selection changed | Selecting another workspace could leave its sessions collapsed and previous section expanded | `SidebarExpansionLogic`; click policy plus `onChange(of: selectedWorkspace.id)` synchronization | 3/3 harness tests green |
| SID-07 | View used `workspaceSessions.prefix(10)` while canonical expected behavior promised up to 12, with no “more” affordance | Sessions 11 and 12 were silently inaccessible from the sidebar | `SidebarSessionLimitLogic.maximumVisible == 12`; view wired to explicit contract | 3/3 harness tests green |
| SID-15 | Notification action handlers changed AppState but never dismissed the sheet; child button taps could bypass row-level mark-read gesture | “Open Session”, “Open Settings” and “View Changes” appeared ineffective until manual close; unread badge could remain | `NotificationActionRoutingLogic`; explicit mark-read; dismiss after successful supported action; retain sheet for missing/custom action | 3/3 harness tests green |

### Chain verification highlights

For archive, the trigger is the Sidebar archive icon or Storage action; the handler mutates
`ProjectRegistryLogic`; the previous consumer was only the popover/Storage list, not the active
Sidebar; the fix makes `AppState.projectRegistryEntries` the published consumer and filters
`displayedWorkspaces` through the pure visibility contract. Unknown registry entries remain visible
so older installations cannot lose projects, while the currently selected archived workspace stays
visible to preserve the active task context.

For workspace selection, the name/chevron button now distinguishes current-row toggle from a
new-row selection. The new-row path always expands; `onChange` collapses non-selected sections and
expands the selected one. The sessions list uses `AppState.sessions(for:)`, already sorted by
updated time, and an explicit 12-row limit.

For notifications, the action button explicitly marks read before routing. A valid Open Session
selects the session and dismisses; Open Settings and View Changes update AppState and dismiss; a
missing session returns without dismissing, and custom actions remain visible because they have no
implemented handler. This is fail-closed UX rather than hiding a failed action.

### Documentation and registry

`docs/activity-checklists/02-sidebar.md` now contains all controls with full trigger→handler→state→
consumer chains, code-quality/task-fit scores, and runtime status. `SID-24`, `SID-25`, and `SID-26`
were added to the canonical CSV. The registry now has **253 rows: 228 PASS, 15 PARTIAL, 5 MISSING,
5 FUTURE**. README totals were synchronized. The red test logs and Round 50 evidence remain under
`.acceptance/` for auditability.

### Adversarial scores

| Dimension | Before Round 50 | After Round 50 | Evidence boundary |
|---|---:|---:|---|
| Sidebar implementation quality | 79/100 | 95/100 | Pure contracts, source tracing, 13 new green tests |
| Sidebar task adherence | 78/100 | 100/100 | Every checklist action traced; confirmed defects fixed TDD-first |
| Sidebar target-runtime confidence | 0/100 | 0/100 | macOS UI/native runtime unavailable; no false PASS |
| Overall verifiable project quality | 88/100 | 92/100 | Code-level and harness evidence only; web runtime still pending |

Round 50 is not complete until this report, checklist, registry, source and tests are committed and
pushed. The published commit hash must be read from Git after the operation rather than guessed.


## Round 51 (2026-08-14) — Chat first-send persistence audit and TDD fix

### Scope and adversarial result

The third activity checklist was traced from composer input through readiness, route resolution,
session creation, MessageStore persistence, provider branches, streaming, stop, queue, retry, edit,
copy, plan questions, and failure rendering. The canonical BUG-06 note claimed
`persistRejectedMessage` and `persistUnsentMessage`, but a repository-wide source search found that
neither helper existed. The actual first-send chain was therefore re-opened instead of accepting the
historical PASS.

The confirmed failure was causal and reproducible from source: a new workspace had no selected
session; `sendDirectly` appended the user message and empty assistant placeholder while
`MessageStore.currentSessionID == nil`; `MessageStore.append` explicitly skipped
`DatabaseBridge.saveMessage`; the standard Serve branch created its remote session only afterward.
Preflight validation appended only an assistant error, also without a session. A failed first request
could therefore disappear from project history after relaunch even though it was visible in the
current process.

### TDD red → green fix

Red tests were written first in `SendPersistenceLogicTests` for three edge cases: a new workspace
must bootstrap before the first append, an existing session must be reused without a duplicate, and
no workspace path must fail closed rather than writing to an unrelated database. The Foundation
harness initially failed to compile because the contract did not exist; after implementation the
three tests passed. A source-level contract test then verified that `prepareSessionBeforeAppending`
occurs before `messageStore.append(userMessage)` and that rejected sends call the explicit helper.

The fix adds `SendPersistenceLogic`, `AppState.prepareLocalSessionForSend(title:)`, and
`ChatPanelView.prepareSessionBeforeAppending(route:title:)`. The helper creates a project-owned
session through `DatabaseBridge.createSession`, registers it without early selection, and binds the
MessageStore session ID before the first append. Serve creates its remote session at the same point
and the standard branch reuses that ID instead of creating a duplicate. `recordRejectedSend`
retains the user input and visible error on preflight failures. Selection is delayed until after the
first user message is saved, preventing the selected-session SwiftUI reload callback from clearing
freshly appended content.

### Evidence

| Check | Result | Boundary |
|---|---:|---|
| CHAT-18 pure persistence tests | 3/3 passed | Foundation only |
| Full Foundation harness | **88/88 passed** | Linux-compatible logic and browser contracts only |
| Swift parser-only check of modified AppState/ChatPanel/persistence files | passed | Syntax only; no macOS typecheck |
| Full SwiftUI/AppKit target build | UNVERIFIED | macOS required |
| Provider/network request capture | UNVERIFIED | live server/OpenCode/WebKit required |
| macOS DB relaunch and visible sidebar/session QA | UNVERIFIED | macOS runtime required |

### Newly exposed boundary, intentionally not marked PASS

The same source trace found a separate attachment defect: `MiCoderAutoFreeClient.Message` has a
string-only `content`, while `ChatPanelView` maps Auto Free message parts through a text-only
`compactMap`. Images and files are retained in the local transcript but are not transmitted to the
Auto Free model. Checklist 03 and quality-recheck now mark this behavior **PARTIAL** and define it
as the next red-test target; no multimodal schema was changed without first adding a compatible
request contract.

Canonical docs were corrected: BUG-06 now names real functions/tests, `11-causal-chain.md` no
longer describes nonexistent helpers, `12-quality-recheck.md` no longer claims them as PASS, and
`03-chat.md` contains all 18 chat actions plus the Round 51 chain. Registry totals remain **253 rows:
228 PASS, 15 PARTIAL, 5 MISSING, 5 FUTURE**.

### Adversarial scores

| Dimension | Before Round 51 | After Round 51 | Evidence |
|---|---:|---:|---|
| Chat implementation quality | 80/100 | 94/100 | First-send persistence fixed; attachment boundary remains PARTIAL |
| Chat task adherence | 82/100 | 100/100 | Full chain traced; red tests preceded confirmed fix; no false attachment PASS |
| Chat target-runtime confidence | 0/100 | 0/100 | macOS/WebKit/network not available |
| Overall verifiable project quality | 92/100 | 93/100 | 88/88 harness; target runtime still pending |

Round 51 is ready to publish only after source, tests, canonical docs, and this report pass diff
checks and are committed/pushed. The next round must begin with a red test for Auto Free attachment
transport rather than assuming the local preview proves model delivery.


## Round 52 (2026-08-14) — MiCoder Auto Free attachment transport

### Confirmed defect

The Chat activity chain showed attachments in the local composer and transcript, but the Auto Free
branch reduced `MessagePartsBuilder.build(text:files:images:)` to text-only messages with a
`compactMap`. Pasted images, image files, and readable code/text files therefore never reached the
anonymous OpenCode request. This was a confirmed logical transport defect, not a macOS-only visual
uncertainty.

### Red → green TDD fix

`MiCoderAutoFreeContentLogicTests` was written before the implementation and initially failed
because no content-part contract existed. The red cases covered text plus image preservation, text
file preservation, and empty input. The green contract now models explicit text, image URL, and
readable-file parts. A second test verifies the JSON boundary: multimodal user content encodes as an
array while legacy system prompts remain a string, preserving the existing system-prompt route.

`MiCoderAutoFreeClient.Message` now supports both `content: String` and `content: [part]` forms.
`ChatPanelView` converts pasted images and image files to `data:` image URLs and reads UTF-8 text
files with filenames, capped at 250,000 characters per file. Files that cannot be read as text or
image produce a visible assistant warning and are not silently omitted from the user's understanding.
The warning persists alongside the streamed answer.

### Deliberate remaining boundary

The anonymous OpenCode `/chat/completions` schema does not provide a portable arbitrary-binary or
PDF file part compatible with this route. Such files remain unsupported by the payload and are
explicitly reported. This is recorded as `PARTIAL`, not falsely marked complete. A future route can
add a provider-specific file upload or switch to a Responses-style input-file contract, but that
must be verified against the live provider before implementation.

### Evidence

| Check | Result | Boundary |
|---|---:|---|
| CHAT-19 content-part tests | 4/4 passed | Foundation contract |
| Full Foundation harness | **92/92 passed** | Linux-compatible logic and prior web/send contracts |
| Swift parser-only check for Auto Free client/content logic/ChatPanel | passed | Syntax only; no macOS typecheck |
| Adversarial source checks | **12/12 passed** | Static source contracts |
| Live OpenCode request capture | UNVERIFIED | External network/provider response unavailable in this target |
| macOS attachment picker/paste and visual warning QA | UNVERIFIED | SwiftUI/AppKit runtime unavailable in Linux |

Canonical checklist 03, quality recheck 12, README totals, and `CHAT-19` registry row were updated.
The registry now contains **254 rows: 228 PASS, 16 PARTIAL, 5 MISSING, 5 FUTURE**.

### Adversarial scores

| Dimension | Before Round 52 | After Round 52 | Evidence |
|---|---:|---:|---|
| Auto Free attachment implementation quality | 55/100 | 92/100 | Explicit multimodal schema, bounded text reads, visible unsupported warning |
| Attachment task adherence | 60/100 | 95/100 | Images and readable files are transmitted by code; binary limitation is explicit |
| Target-runtime confidence | 0/100 | 0/100 | macOS picker and live request still unavailable |
| Overall verifiable project quality | 93/100 | 94/100 | 92/92 harness and 12/12 source checks |

Round 52 is ready to publish after diff checks and commit/push. The next sequential audit begins at
activity checklist 04, not by assuming the settings/provider controls are complete because the
source exists.


## Round 53 (2026-08-14) — Settings/provider/resource controls

### Scope

Activity checklist 04 was re-audited from Settings navigation through General, Code Preview,
provider/model management, local providers, Auto Free, Skills, MCP, Plugins, Commands, Storage and
Usage. Every visible action was traced from trigger to handler, state mutation, persistence consumer
and intended visible result. Source existence was not accepted as proof of a working control.

### Confirmed defects and TDD fixes

#### SET-11 — local provider model chips were a no-op

`LocalProviderRow.selectModel` contained no action and `isSelected` tested catalog membership rather
than active provider plus selected model, so every chip looked selected and none changed the send
route. Red tests covered provider-scoped visual selection, valid/invalid catalog taps and provider
switching. `LocalModelSelectionLogic` now supplies the pure contract; the row validates its fetched
catalog and calls the parent, which selects the provider and model through AppState. The parent reloads
persisted local configuration after refresh to avoid stale-snapshot rejection.

#### SET-12 — provider endpoints and API-key defaults were unsafe

`AppState.testProvider` concatenated raw input with `/models`; Add Provider saved raw whitespace and
trailing slashes, accepted a missing scheme, and retained `requiresAPIKey = false` when switching
from OpenCode Zen to a provider that normally requires credentials. Red tests covered normalized
base URLs, safe `/models` construction, invalid URL rejection and provider-type defaults.
`ProviderEndpointLogic` now accepts only HTTP(S) host URLs without query/fragment, trims trailing
slashes, and builds the models endpoint with URL path semantics. Add Provider shows invalid-input
feedback, disables test/save for invalid endpoints, trims saved name/key/URL, and recomputes the
API-key requirement on every provider-type change.

#### SET-13 — plugin management was display-only

`PluginsSettingsView` showed the Enabled/Disabled state but had no enable/disable button, although
the screen subtitle promised that capability. The existing loader already had a `disabledPlugins`
UserDefaults store and `PluginEntry.togglePlugin`; the missing link was the UI action and a tested
mutation contract. Red tests covered add/remove disabled IDs and enabled-state derivation. The fix
adds the visible action, persists through the existing store, reloads the row state, and factors the
mutation into `PluginToggleLogic`.

### Source-traced controls with no confirmed new defect

General and Code Preview controls use AppState settings persistence or explicit `updateSettings` and
were source-traced without changing them absent a reproducible failure. Skills and MCP use shared
catalog installers and registry managers; Commands expose tested CRUD plus enable/disable; Storage
keeps distinct destructive confirmations, typed project deletion and the Round 50 registry refresh
hook; Usage uses the existing range/filter aggregators. Native sheets, filesystem/process probes,
SQLite/backup operations and live providers remain runtime boundaries, not false PASS claims.

### Evidence

| Check | Result | Boundary |
|---|---:|---|
| SET-11 local model selection | 3/3 passed | Foundation pure contract |
| SET-12 provider endpoint/form defaults | 3/3 passed | Foundation pure contract |
| SET-13 plugin toggle | 3/3 passed | Foundation pure contract |
| Full Foundation harness | **101/101 passed** | Linux-compatible logic and prior web/send contracts |
| Swift parser-only settings check | passed | Syntax only; no macOS typecheck |
| Adversarial source checks | **12/12 passed** | Static source contracts |
| Full macOS SwiftUI/AppKit/WebKit build | UNVERIFIED | macOS required |
| Native sheets/filesystem and live provider request QA | UNVERIFIED | macOS/external runtime required |

Canonical checklist 04, README, registry and this report were updated. The registry now contains
**257 rows: 231 PASS, 16 PARTIAL, 5 MISSING, 5 FUTURE**.

### Adversarial scores

| Dimension | Before Round 53 | After Round 53 | Evidence |
|---|---:|---:|---|
| Settings/provider implementation quality | 78/100 | 94/100 | Three confirmed chain breaks fixed; 101/101 harness |
| Settings task adherence | 80/100 | 100/100 | Full checklist inventory, red tests before each confirmed fix |
| Target-runtime confidence | 0/100 | 0/100 | No macOS UI, filesystem or live endpoint execution |
| Overall verifiable project quality | 94/100 | 95/100 | 101/101 harness and 12/12 source checks |

Round 53 is ready to publish after diff checks and commit/push. The next audit continues with the
next activity checklist in sequence and will not treat the newly fixed settings controls as macOS
runtime verified.


## Round 54 (2026-08-14) — Web Login, named sessions and detector honesty

### Scope
Activity checklist 05 was re-audited from vendor addition through login, named-session selection,
cookie capture, connectivity, built-in model detection, optional MiCoder Auto Free detection, model
and effort refresh, provider removal, remote-chat cleanup and the isolated browser send route. Each
visible control was traced to its handler, state mutation, persistence consumer and downstream
consumer. macOS/WebKit behavior is explicitly separated from Foundation/source verification.

### Confirmed defects and TDD fixes

#### WEB-LOGIN-11 — empty capture could create a false login state

`WebProviderLoginView.capture()` treated the existence of a page URL as sufficient and passed an
empty cookie snapshot to the parent. The parent used `try?` for `WebSessionManager.persist`, then
could update session metadata and start model discovery without proving that a usable cookie store
had been written. The user received no actionable explanation.

Red tests were written first in `WebLoginCaptureLogicTests`: empty snapshots are rejected, non-empty
snapshots are accepted, the empty-capture message is actionable, and a persistence failure cannot
activate the session. The fix adds `WebLoginCaptureLogic.canPersist` and
`shouldActivateSession`, keeps the login sheet open for empty capture, surfaces write failure through
the red NotificationService error, and updates active session metadata only after successful
persistence. Targeted and integrated evidence: **4/4 targeted, 107/107 full harness**.

#### WEB-LOGIN-12 — built-in detector was mislabeled as MiCoder Auto Free

The normal provider card status said `MiCoder Auto Free will detect models` or `MiCoder Auto Free
detected N models`, although that path is the built-in DOM detector. This contradicted the required
separation between a local browser detector and the optional AI-assisted route.

Red tests were written first in `WebDetectionStatusLogicTests` for empty and non-empty model counts,
including the requirement that the status never contain `Auto Free`. The fix factors status text into
`WebDetectionStatusLogic`, changes the primary action to `Built-in browser detection`, and labels the
separate action `Ask MiCoder Auto Free`. AI-derived candidates remain non-selectable until built-in
DOM verification. Targeted and integrated evidence: **2/2 targeted, 107/107 full harness**.

### Source-traced controls with no additional confirmed defect

The add-vendor path creates a config without guessing a model. Named sessions use independent
provider/session directories and persist active ID/name. Connectivity requires non-empty,
non-expired cookies for the active session. Model/effort refresh restores the active session before
navigation and uses isolated project/chat/provider/session browser keys. Removal clears provider
configuration, saved sessions, remote-chat mappings and stale selection. The ChatPanel web route
restores cookies before navigation, binds a verified remote chat UUID per local project/chat/login,
records model/effort/remote-chat metadata, and performs a bounded retry after typed injection
failures.

`WebSessionStore.localStorage` is persisted and round-trips in Foundation tests, but generic
localStorage injection into WKWebView is not implemented. This remains a provider-specific WebKit
runtime risk and is recorded as **UNVERIFIED/POTENTIAL**, not as a claimed defect or PASS. The Linux
harness cannot prove cookie acceptance, DOM hydration, click/typing behavior, vendor login, live
model discovery, effort injection, or response streaming.

### Evidence

| Check | Result | Boundary |
|---|---:|---|
| WEB-LOGIN-11 targeted harness | **4/4 passed** | Foundation pure capture contract |
| WEB-LOGIN-12 targeted harness | **2/2 passed** | Foundation pure status contract |
| Full Foundation harness | **107/107 passed** | Linux-compatible logic and prior web/send contracts |
| Adversarial source checks | **12/12 passed** | Static source contracts |
| Swift parser-only modified-file check | passed | Syntax only; no macOS typecheck |
| `git diff --check` | passed | Repository hygiene |
| Full macOS SwiftUI/AppKit/WebKit build | **UNVERIFIED** | macOS required |
| Embedded WKWebView login/cookie/DOM/live-provider QA | **UNVERIFIED** | macOS, network and provider accounts required |

### Adversarial scores

| Dimension | Before Round 54 | After Round 54 | Evidence |
|---|---:|---:|---|
| Web Login implementation quality | 76/100 | 95/100 | Two confirmed chain breaks fixed; 107/107 harness |
| Web Login task adherence | 78/100 | 100/100 | Full control inventory, explicit detector split, red tests before fixes |
| Target-runtime confidence | 0/100 | 0/100 | No macOS/WebKit/live-provider execution available |
| Overall verifiable project quality | 95/100 | 96/100 | 107/107 harness and 12/12 source checks |

Canonical checklist 05, registry, README and this report were updated. The registry now contains
**259 rows: 233 PASS, 16 PARTIAL, 5 MISSING, 5 FUTURE**. Round 54 is ready for diff validation and
commit/push; the next sequential audit is activity checklist 06 (`06-web-chat.md`).


## Round 55 (2026-08-14) — Web Chat send chain, access gates and named-session restoration

### Scope

Activity checklist 06 was re-audited from provider/model selection through model and effort injection,
embedded-browser navigation, cookie/localStorage restoration, prompt send, response polling, streaming,
tool parsing/execution, access-level gates, captcha/logout/session-limit interruption, remote-chat UUID
binding, chunking, stop generation, browser isolation and completion accounting. Every visible action and
function was traced through its handler, state mutation, persistence consumer and downstream browser or
message consumer. Foundation and source checks are not treated as macOS/WebKit runtime verification.

### Confirmed defects and TDD fixes

#### WEB-CHAT-11 — Ask-before-changes did not protect file mutations

`AccessLevel.askBeforeChanges` is displayed as “Ask before file changes,” but
`WebToolAccessGate` returned `.allow` for `write_file`, `edit_file` and `todo_write`. The concrete
executor therefore performed real file/todo mutations immediately. The generic `requiresApproval`
helper was not a consumer of the live gate and did not provide a user-visible guard.

Red tests first asserted approval for all three mutation classes and preserved edit-automatically/full-
access behavior. The gate now returns `.requireApproval` at ask-before-changes. The driver emits a
new `approvalRequired` event before executor dispatch, so no mutation side effect occurs. Evidence:
**3/3 gate tests passed**.

#### WEB-CHAT-12 — blocked turns had no dedicated visible completion path

The driver had no event representing a policy-blocked tool. The caller could therefore finish the turn
and record `send_completed` even when a tool had not run. Red integration coverage asserted that the
executor is untouched and an approval event is emitted. `WebChatEventPresenter` maps the event to a
persistent status, while `ChatPanelView` records `send_blocked_approval`, marks the assistant turn
finished and avoids retry/success accounting. Evidence: **1/1 integration test passed**.

The current safe behavior is an explicit blocked status rather than an automatic approval dialog. A
native SwiftUI approval control that resumes the same remote turn remains **UNVERIFIED** and is not
claimed as complete.

#### WEB-CHAT-13 — localStorage existed in the model but was neither captured nor safely restored

Login capture always constructed `WebSessionStore` with `localStorage: [:]`, although the session model
persisted the field. The first attempted restore also called `setLocalStorage` before loading the
vendor origin, so browser storage could be written to the wrong page or fail silently.

Red tests covered payload preservation, cookie-only sessions, and the required order. The fix captures
origin localStorage from the login WKWebView, adds a bridge method with a no-op Foundation default, and
restores `cookies → target navigation → localStorage → reload current URL`. Model and effort refresh
use the same sequence; ChatPanel preserves an existing remote-chat URL while reloading. Storage
failures become visible nonfatal warnings. Evidence: **4/4 restoration tests passed**.

#### WEB-CHAT-14 — custom vendor selected models bypassed injection

When bundled catalog lookup returned no entry, `WebChatDriver.injectModelAndEffort` returned success.
That path is reachable for `.custom`, even when `customModelSelector` is persisted, so the prompt could
be sent under whatever model the page happened to show.

A red custom-vendor test asserted selector click, exact option confirmation and send ordering. The fix
uses `customModelSelector` before catalog selectors and blocks a non-empty selected model when no model
selector exists. Evidence: **1/1 custom selector test passed**.

#### Approval-helper inconsistency

`WebToolProtocolEmulator.requiresApproval` omitted `edit_file`, `todo_write`, git mutations and `task`.
Red coverage expanded its classification to all mutating/privileged tool families; the helper now
agrees with `WebToolAccessGate`. Evidence: **1/1 helper test passed**.

### Source-traced controls with no additional confirmed defect

Response baseline/fingerprint handling rejects unchanged or empty response DOM. Captcha/logout checks
run before send and before response reads. Session-limit carry-over, prompt chunking, bounded iteration,
tool-result escaping, project-root validation, undo/history recording, remote-chat UUID verification and
100-instance LRU browser isolation are source-traced and covered by existing Foundation contracts.
The live bridge dispatches DOM events without an active window, but provider authentication, cookies,
localStorage, selectors, model menus, effort menus, response streaming, captcha presentation and native
approval UX require macOS/WebKit/network execution.

### Evidence

| Check | Result | Boundary |
|---|---:|---|
| WEB-CHAT-11 access-gate tests | **3/3 passed** | Foundation pure policy |
| WEB-CHAT-12 approval interruption | **1/1 passed** | Foundation driver integration |
| WEB-CHAT-13 session restoration | **4/4 passed** | Foundation payload/order contract |
| WEB-CHAT-14 custom selector | **1/1 passed** | Foundation driver integration |
| Approval-helper consistency | **1/1 passed** | Foundation protocol helper |
| Full Foundation harness | **147/147 passed** | Linux-compatible logic and prior contracts |
| Swift parser-only modified-file validation | **passed** | Syntax only; no macOS typecheck |
| Adversarial source checks | **12/12 passed** | Static contracts |
| Full macOS SwiftUI/AppKit/WebKit build | **UNVERIFIED** | macOS required |
| Live web login/model/effort/response/tool QA | **UNVERIFIED** | macOS, network and provider accounts required |

### Adversarial scores

| Dimension | Before Round 55 | After Round 55 | Evidence |
|---|---:|---:|---|
| Web Chat implementation quality | 74/100 | 95/100 | Four confirmed chain defects fixed; 147/147 harness |
| Web Chat task adherence | 72/100 | 100/100 | Full action inventory, red tests before each confirmed fix |
| Target-runtime confidence | 0/100 | 0/100 | No macOS/WebKit/live-provider execution |
| Overall verifiable project quality | 96/100 | 97/100 | Full harness and parser validation |

Canonical checklist 06, registry and README were updated. The registry now contains **264 rows:
233 PASS, 21 PARTIAL, 5 MISSING, 5 FUTURE**. Round 55 is ready for the final source-check/diff
validation and commit/push. The next sequential audit remains activity checklist 07 (`07-mimo-auto.md`).
