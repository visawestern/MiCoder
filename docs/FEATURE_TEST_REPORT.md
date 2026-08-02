# MiCoder — Feature Test Report (canonical)

Date: 2026-08-01 · Method: every user story from `FEATURE_SPREADSHEET.csv` (194 features) verified against actual code + full test suite (1638 tests, 225 suites, all green on baseline run).

Canonical status source: `docs/FEATURE_SPREADSHEET.csv` (single spreadsheet — the /goal deliverable).
This report documents the **errors found** (Phase 2), which Phase 3 fixes.

---

## Baseline

- Full test suite: `swift test` → 1638 tests in 225 suites, **all passing** (baseline run before fixes).
- Feature status rollup: 158 PASS · 21 PARTIAL · 12 MISSING · 3 FUTURE.
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
| E09 | **`executeWithUndo` has zero production callers** — the per-project undo stack is always empty at runtime; snapshots never created during real tool operations. | `ProjectUndoManager.swift:34` (no callers) | Раздел 7 п.13/14 |
| E10 | **`request_history` never written in normal flow** — table + API exist, only `importBundle` writes it; applied edits/commands are never logged as requests. | `ProjectDatabaseManager.swift:674` (writer = import only) | Раздел 7 п.12 |
| E11 | **MCP health check is a stub** — `MCPRegistryManager.updateHealthCheck` has zero callers; the green dot in the UI reflects `isEnabled`, not real health. | `AgentResourceRegistryManager.swift:168` | Раздел 4 п.5 |
| E12 | **`run_command` in web tool executor returns a message** instead of executing or gating by AccessLevel — approval exists but is never enforced. | `ProjectWebToolExecutor.swift:60-64` | Раздел 12 п.18 |

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
| E23 | **Auto-detect adds a provider without user confirmation** — violates "без самодеятельности"; no "Подтвердить и добавить" step. | `SettingsView.swift:2459-2472` | Раздел 9 п.30 |
| E24 | `ProviderAutoDetector.overallTimeout` declared (10s) but **never enforced** — worst case is 4 sequential probes × 2s with no deadline. | `ProviderAutoDetector.swift:30` | Раздел 9 п.33 |
| E25 | `SettingsIntegrationTests` asserts `.modelSettings` in `allCases` (count 11) — contradicts the plan's single-Providers-tab consolidation (case should be removed). | `SettingsIntegrationTests.swift:705-712` | Раздел 1 п.21 |
| E26 | User-facing "MiMo" strings remain: "Manage MiMo Agent .md command files", "…Ollama, OpenCode, or MiMo CLI/Serve", "Auto-commit from MiMo". | `SettingsView.swift:1527,2384`, `BottomPanelView.swift:487` | Раздел 13 п.11 |
| E27 | Overview sheet still titled "Workspaces". | `SidebarView.swift:502` | Раздел 13 п.7 |
| E28 | `neutralizeServeBranding` is dead production code (defined + tested, never called). | `LocalProviderConfig.swift:111-119` | Раздел 1 п.7 |
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

Remaining fix order: E09/E10 → E11 → E12 → E23/E24 → E25 → E26/E27/E28 → E13/E14/E15 → E17/E18/E19 → E07/E22 → E20/E21 → E29/E30/E31.
