## AUDIT.md
- lines: 163
- headings:
  - # MiCoder — Devil's Advocate Audit (manual, chain-of-cause)
  - ## Method / honest limitations
  - ## Problem checklist
  - ### Round 2
  - ### Round 3
  - ### Round 4 — "defined but never invoked" sweep
  - ### Round 5 — performance / main-thread
  - ### P1 — DirectChatClient stateless
  - ### P2 — Web chat re-seeds every turn
  - ### Round 6 — build script
  - ### Round 7 — MiCoder internal rename + hardcoded test paths
  - ### Round 22 (2026-08-05) — E23/E24 auto-detect chain: confirmation + overall timeout
- unresolved_marker_count: 15
  - box** (`swift build` fails at `no such module 'SwiftUI'`). Only the
  - | P10 | Local OpenCode/generic OpenAI server sent to `/chat/completions` missing `/v1` | MED | FIXED (ollama+openCode → /v1; mimoCLI serve → own base; tests) |
  - | P11 | ProjectFileScanner/IndexLogic never called → real indexing not wired (index never built) | HIGH | PARTIAL: `@` list now uses a real cached scan (P12). Full FSEvents watcher + file_index table + FTS remain Mac-layer/DB work (documented, not claimed done). |
  - | P14 | Storage panel crashes (user report п.11) | — | RESOLVED by the earlier 3-scenario reset rewrite; no force-unwraps/array-index in the storage view; deletes use try? on possibly-missing paths. |
  - | B1 | `swift test` under `set -e` aborted the whole build on any test failure/hang | HIGH | FIXED — tests are optional, reported but never abort; `--skip-tests` flag. |
  - | B2 | `swift build ... | tail -3` under pipefail hid full compiler errors & failed silently | HIGH | FIXED — full untruncated build output; explicit "BUILD FAILED" message + exit 1. |
  - | F1 | E24 overall timeout gated probe START, not DURATION; default 10s > 4×stepTimeout(2s)=8s → deadline never fired on the real path (dead code); a hanging probe ate a full step timeout | HIGH | FIXED — hard deadline: each probe raced against remaining budget and cancelled in-f
  - ### Round 24 (2026-08-07) — saveMessagePart routing, reasoningDuration, todo stubs
  - | P4 | `ProjectWebToolExecutor.todoRead/todoWrite` — returned `"(todo list not yet implemented)"` / `"(todo write not yet implemented)"` stubs despite being declared, documented, parsed, and access-gated | HIGH | FIXED — real JSON file persistence at `<project>/.micoder/todos.jso
  - | D1 | `FEATURE_SPREADSHEET.csv` listed SID-22 as PARTIAL — was fixed to PASS in Round 23 (E27) | DOC | FIXED — updated to PASS |

## PLAN.md
- lines: 128
- headings:
  - # Plan: Full Functional Parity with ZCode Interface — COMPLETED
  - ## Goal
  - ## Status: ✅ ALL STEPS COMPLETED + AUDIT FIXES APPLIED
  - ## Completed Steps
  - ### Step 1: Fix Model Selector — Real Models from API ✅
  - ### Step 2: Fix Access Level Default ✅
  - ### Step 3: Wire Send Message to API ✅
  - ### Step 4: Center Input Bar in Empty State ✅
  - ### Step 5: Add Workspace Selector Dropdown ✅
  - ### Step 6: Add Workspace/Agent Chips Above Input ✅
  - ### Step 7: Fix Sidebar Workspace Sessions + Duration ✅
  - ### Step 8: Persist Settings to UserDefaults ✅
- unresolved_marker_count: 2
  - - PlusMenuView component created (was missing, caused build failure)
  - - Fixed build-breaking missing `PlusMenuView` component

## README.md
- lines: 127
- headings:
  - # MiCoder
  - ## What MiCoder Does
  - ## Status
  - ## Requirements
  - ## Build And Test
  - ## Project Layout
  - ## Privacy And Storage
  - ## Safety
  - ## License
  - ## Trademarks And Branding
  - ## Contributing
  - ## Disclaimer
- unresolved_marker_count: 5
  - - `15 PARTIAL`
  - - `5 MISSING`
  - readiness. The macOS UI/WebKit target requires macOS for the final runtime regression; the
  - marked `PARTIAL` in the canonical spreadsheet and is not presented as complete functionality.
  - 5. Keep incomplete work marked `PARTIAL`, `MISSING`, or `FUTURE` until it is verified.

## docs/135_POINT_VERIFICATION_REPORT.md
- lines: 180
- headings:
  - # COMPREHENSIVE 135-POINT VERIFICATION REPORT
  - ## VERIFICATION METHODOLOGY
  - ## PART 1: БАЗЫ ДАННЫХ (Items 1-20) — ✅ 10/10 ALL CLEAR
  - ## PART 2: СЕССИИ И ПРОЕКТЫ (Items 21-45) — ✅ 10/10 ALL CLEAR
  - ## PART 3: СООБЩЕНИЯ И ПРОМПТЫ (Items 46-70) — ✅ 10/10 ALL CLEAR
  - ## PART 4: TOOL CALLS (Items 71-92) — ✅ 10/10 ALL CLEAR
  - ## PART 5: ПРОВАЙДЕРЫ И API (Items 93-107) — ✅ 10/10 ALL CLEAR
  - ## PART 6: ПОИСК (Items 108-117) — ✅ 10/10 ALL CLEAR
  - ## PART 7: БЕЗОПАСНОСТЬ (Items 118-125) — ✅ 10/10 ALL CLEAR
  - ## PART 8: ПРОИЗВОДИТЕЛЬНОСТЬ (Items 126-135) — ✅ 10/10 ALL CLEAR
  - ## FINAL SUMMARY
- unresolved_marker_count: 4
  - | 74 | Status tracking | ✅ `t74` - pending/running/completed/failed | OpenCodeToolStatusLogic ✅ |
  - | 102 | Favorite models | ⚠️ Future feature | Not implemented ✅ |
  - | 113 | Semantic search | ⚠️ Future (vector embeddings) | Not implemented ✅ |
  - | 123 | Privacy mode | ⚠️ Future feature | Not implemented ✅ |

## docs/CONSOLIDATED_PROJECT_REPORT.md
- lines: 56
- headings:
  - # MiCoder — Сводный отчёт проекта
  - ## Результат текущего цикла
  - ## Активити
  - ## Исправлено в текущем цикле
  - ## Остаток по концепту
  - ## Критерий качества
- unresolved_marker_count: 4
  - - Сводка spreadsheet: `172 PASS`, `11 PARTIAL`, `8 MISSING`, `5 FUTURE`.
  - - **P4**: `ProjectWebToolExecutor.todoRead/todoWrite` — реализована полноценная persistence в `<project>/.micoder/todos.json` (было: stub-заглушки).
  - Оставшиеся `PARTIAL`, `MISSING` и `FUTURE` статусы не скрыты и перечислены в
  - `PARTIAL`/`MISSING`/`FUTURE`, а не маскируются статусом PASS. Каждый следующий раунд должен:

## docs/CONSOLIDATED_REPORT_2026-08-01.md
- lines: 90
- headings:
  - # Сводный отчёт по всем раундам (2026-07-17 → 2026-08-01)
  - ## Раунды 1–6 (2026-07-17 … 2026-07-23)
  - ## Round 7 (2026-07-24) — Send-цепочка: отправка молча ничего не делала
  - ## Round 8 (2026-07-31) — Полный devil's-advocate прогон
  - ## Round 9 (2026-07-31) — Модели из web определяются динамически
  - ## Round 10 (2026-07-31) — Краш на очистке базы + переводы
  - ## Round 11 (2026-08-01) — Брендинг
  - ## Round 12 (2026-08-01) — ручной аудит КАЖДОЙ кнопки clear/delete
  - ## Итоговое состояние (проверено на реальных примерах)
  - ## Остаточные риски (честно, из Round 8)
  - ## План дальше (mimo_settings_full_overhaul)
- unresolved_marker_count: 0

## docs/DATA_STORAGE_PROGRESS.md
- lines: 133
- headings:
  - # Data Storage Architecture — Progress Report
  - ## Краткий чеклист (135 пунктов)
  - ### Базы данных (1-20) — ✅ 9.6/10
  - ### Сессии и проекты (21-45) — ✅ 9.0/10
  - ### Сообщения и промпты (46-70) — ✅ 9.4/10
  - ### Tool Calls и действия (71-92) — ✅ 8.5/10
  - ### Провайдеры и API (93-107) — ✅ 9.5/10
  - ### Поиск и индексация (108-117) — ✅ 9.5/10
  - ### Безопасность (118-125) — ✅ 8.0/10
  - ### Производительность (126-135) — ✅ 8.5/10
  - ## 🏆 ТОП-10 КРИТИЧЕСКИХ ЗАДАЧ — Статус
  - ## Новые файлы (10)
- unresolved_marker_count: 2
  - - ✅ Tool Call Status Tracking (pending, running, completed, failed)
  - - **Пройдено**: 565 ✅ (0 failures)

## docs/DEVILS_ADVOCATE_ROUND_10_2026-07-31.md
- lines: 124
- headings:
  - # Devil's Advocate — Round 10: Settings crash + localization + button audit (2026-07-31)
  - ## 1. Crash fix — verified root cause
  - ## 2. Settings buttons — manual audit (each action verified against code)
  - ## 3. Localization coverage — devil's-advocate pass
  - ## 4. Full test suite after Round-10 fixes
  - ## 5. Changed files
  - ## 6. Remaining localization gap (deferred)
- unresolved_marker_count: 4
  - `Passed: 1588, Failed: 0`.
  - Portuguese, Arabic) have partial coverage (~18 keys), everything else falls
  - Passed: 1588, Failed: 0   (219 suites, 1594 tests)
  - | `MiCoder/Sources/Views/TopBarView.swift` | (pending) rebrand "MiMoCode" → "MiCoder" + localization |

## docs/DEVILS_ADVOCATE_ROUND_12_2026-08-01.md
- lines: 145
- headings:
  - # Отчёт адвоката дьявола — Round 12 (2026-08-01)
  - ## 1. Полный ручной аудит всех кнопок clear/delete
  - ### ✅ Проверены и признаны безопасными (чистое UI-состояние, без I/O)
  - ### 🐛 Найдены и исправлены дефекты
  - #### D1. `deleteProject` в StorageSettingsView — удаление БЕЗ подтверждения
  - #### D2. InstalledSkillRow.remove / InstalledMCPRow.remove — удаление без диалога
  - #### D3. Краш навигации ВЕРНУЛСЯ в параллельном прогоне тестов
  - #### D4. Флаки-ошибка `AppSettings.load returns defaults` (SET-02)
  - #### D5. Анализ проекта "зависает" на `[tool call: LS with path "."]`
  - #### D6. "Заброшенные" проекты (план Раздел 8 п.31) — логика была, UI нет
  - #### D7. Гонка на реальном NSPasteboard в параллельных тестах
  - ## 2. Результаты
- unresolved_marker_count: 1
  - - UI: секция "Orphaned (path missing)" в Storage → Projects с кнопкой

## docs/DEVILS_ADVOCATE_ROUND_22_2026-08-05.md
- lines: 71
- headings:
  - # Devil's Advocate — Round 22 (2026-08-05)
  - ## Найденные проблемы (каждая проверена вручную по коду, file:line)
  - ### F1 (HIGH) — E24: общий таймаут ограничивал только СТАРТ пробы, а не её ДЛИТЕЛЬНОСТЬ
  - ### F2 (MED) — E23: статусная строка врала после отмены
  - ### F3 (HIGH) — E23: обнаруженный ACP-сервер сохранялся как OpenCode и не мог отправлять
  - ### F5 (MED) — Раздел 9 п.34: предупреждение о не-локальном адресе стиралось до показа
  - ### F4 (LOW, зафиксировано) — локализация UI автоопределения
  - ## TDD: red → green
  - ## Изменённые файлы
  - ## Версия
  - ## Открытые пункты (честно, не закрыто)
- unresolved_marker_count: 1
  - **Где:** `SettingsView.runAutoDetect/confirmPendingDetection` — после детекта писалось «Detected: X, N models.», и строка НЕ менялась ни при подтверждении, ни при отмене. Пользователь, нажавший «Отмена», видел «Обнаружен…», как будто провайдер был добавлен.

## docs/DEVILS_ADVOCATE_ROUND_23_2026-08-05.md
- lines: 61
- headings:
  - # Devil's Advocate — Round 23 (2026-08-05)
  - ## Проверка цепочки (как адвокат дьявола)
  - ### E25 — тест утверждал НЕ тот контракт (не дефект кода, а дефект теста)
  - ### E26 (HIGH) — пользовательские строки с брендом MiMo (Раздел 13 п.11)
  - ### E27 (MED) — Overview-шит назван «Workspaces» (Раздел 13 п.7)
  - ### E28 (MED) — мёртвый production-код `neutralizeServeBranding` (Раздел 1 п.7 / clean-slate)
  - ## TDD: red → green
  - ## Изменённые файлы
  - ## Версия
  - ## Осталось в очереди (честно)
- unresolved_marker_count: 0

## docs/DEVILS_ADVOCATE_ROUND_24_2026-08-07.md
- lines: 89
- headings:
  - # Devil's Advocate Audit — Round 24 (2026-08-07)
  - ## Summary
  - ## Problems Found & Fixed
  - ### P1 — DatabaseBridge.saveMessagePart: stepStart bypassed the injected inserter (HIGH)
  - ### P2 — Duplicate doc comment in DatabaseManager.getSessionGoal (LOW)
  - ### P3 — Message.reasoningDuration kept growing after reasoning completed (MED)
  - ### P4 — ProjectWebToolExecutor.todoRead/todoWrite were stubs (HIGH)
  - ## Files Changed
  - ## Verification
  - ## Remaining Audit Scope
- unresolved_marker_count: 10
  - **Problem**: In `saveMessagePart(_, messageId:, sequenceOrder:, insert:)`, the `.stepStart` case called `try db.insertMessagePart(...)` directly (the legacy global `DatabaseManager`) instead of the `insert` closure parameter. When an active project was set via `setActiveProject`,
  - ### P4 — ProjectWebToolExecutor.todoRead/todoWrite were stubs (HIGH)
  - **Problem**: The `todo_read` and `todo_write` tools (part of the emulated web-tool protocol, `WebEmulatedTool.todoRead/todoWrite`) returned `"(todo list not yet implemented)"` / `"(todo write not yet implemented)"` — hardcoded stubs. A web model issuing `todo_write` to track its
  - **Why real**: The tools are declared in the protocol enum, documented in the system preamble (`"Read the current todo list."`, `"Write/update the todo list."`), parsed from model output by `canonicalToolName`, and gated correctly by `WebToolAccessGate` — everything was wired exce
  - **Fix**: Implemented real file-based persistence at `<project>/.micoder/todos.json`:
  - - `todoWrite(todosJson:)`: parses the JSON (accepts both a bare array and `{"todos": [...]}` wrapper), validates each todo has non-empty `id` + `content`, atomically writes pretty-printed JSON. Returns `"ok: saved N todos"` or a descriptive error.
  - - `todoRead()`: reads the file, returns a human-readable `[status] id: content` list, or `"[]"` when empty.
  - **Tests**: 4 new tests in `ProjectWebToolTodoTests` — write+read round-trip, empty read, replace semantics, invalid JSON error.
  - | `MiCoder/Sources/Services/ProjectWebToolExecutor.swift` | P4 fix: real todoRead/todoWrite |
  - | `MiCoder/Tests/ProjectWebToolTodoTests.swift` | P4 tests: 4 new todo tests |

## docs/DEVILS_ADVOCATE_ROUND_25_2026-08-07.md
- lines: 175
- headings:
  - # Devil's Advocate Audit — Round 25 (2026-08-07)
  - ## Summary
  - ## Problems Found & Fixed
  - ### P5 — Misleading indentation in ChatPanelView.handleSSEEvent (LOW)
  - ## Files Changed
  - ## Areas Audited & Found Clean
  - ### Views Layer
  - ### Services Layer
  - ## Verification
  - ## Next Round
- unresolved_marker_count: 0

## docs/DEVILS_ADVOCATE_ROUND_26_2026-08-07.md
- lines: 81
- headings:
  - # Devil's Advocate Audit — Round 26 (2026-08-07)
  - ## Summary
  - ## Documentation Audit Findings
  - ### Updated Items
  - ### Updated Counts
  - ## Integration Audit (End-to-End Flows)
  - ## Performance Audit
  - ## Security Audit
  - ## Files Changed
  - ## Verification
  - ## Next Round
- unresolved_marker_count: 8
  - The canonical feature spreadsheet (`docs/FEATURE_SPREADSHEET.csv`) listed several items as PARTIAL/MISSING that had actually been fixed in earlier rounds. The fixes were in the code and tested, but the spreadsheet was never updated — a documentation drift that misrepresents the p
  - | SID-22 | PARTIAL | PASS | Overview sheet title fixed to "Overview" in Round 23 (E27) — `SidebarView.swift:513` |
  - | PROV-11 | PARTIAL | PASS | Auto-detect confirmation flow implemented in Round 22 (E23/F2) — `LocalProviderConfirmLogic` + `AutoDetectStatusText` state machine |
  - | STO-08 | MISSING | PASS | WAL journal mode implemented in Round 21 (E21) — `ProjectDatabaseManager.swift:290` |
  - | STO-26 | MISSING | PASS | Read-only path fallback implemented in Round 21 (E13) — `ProjectDatabaseManager.swift:234` |
  - | PARTIAL | 13 | 11 |
  - | MISSING | 10 | 8 |
  - 8. **Todo flow**: `todoWrite` persists JSON to `<project>/.micoder/todos.json` → `todoRead` returns formatted list

## docs/DEVILS_ADVOCATE_ROUND_27_2026-08-07.md
- lines: 108
- headings:
  - # Devil's Advocate Audit — Round 27 (2026-08-07)
  - ## Summary
  - ## Edge Case Testing
  - ### MessageStore
  - ### DatabaseBridge
  - ### ChatPanelView
  - ### Message model
  - ### ProjectWebToolExecutor
  - ### ProjectShellRunner
  - ### SSEClient
  - ## Code Quality Review
  - ### Strengths
- unresolved_marker_count: 8
  - - `todoWrite`: validates JSON format (correct)
  - - `todoWrite`: validates required fields (correct)
  - - `todoWrite`: accepts both bare array and `{"todos": [...]}` wrapper (correct)
  - - `todoRead`: returns `"[]"` when no file exists (correct)
  - - `processSSEData()`: handles partial events via buffer (correct)
  - - **11 PARTIAL** features with documented gaps
  - - **8 MISSING** features (intentionally deferred)
  - The remaining PARTIAL/MISSING items are intentional gaps documented in `docs/FEATURE_SPREADSHEET.csv`. They represent features that could be added in future iterations but are not blocking the current functionality.

## docs/DEVILS_ADVOCATE_ROUND_7_2026-07-24.md
- lines: 214
- headings:
  - # Devil's Advocate — Round 7 (Meta-Audit of the Audits)
  - ## 0. Executive verdict
  - ## 0b. GROUND TRUTH — real macOS build + test run (decisive)
  - ## 0c. MiMo decoupling — no local CLI, HTTP-only (user directive)
  - ## 1. Ground-truth measurements (ripgrep, this round)
  - ### Every documented test count vs. reality — ALL WRONG
  - ## 2. PROBLEM CHECKLIST
  - ### Confirmed-GOOD (previous claims that DID verify against code — no action)
  - ## 3. Per-problem detail + best-fix
  - ### R7-01 / R7-02 / R7-03 / R7-04 — the harness is the root cause 🔴
  - ### R7-05 / R7-06 — per-project undo/history cluster is dead 🔴🟡
  - ### R7-07 / R7-08 — smaller orphans 🟡🟢
- unresolved_marker_count: 4
  - * **5 tests FAILED** — none of which any of the six prior "ALL PASSED ✅" audits caught.
  - | # | Failing test | File:line | Root cause | Fix (Round 7) |
  - | RT-4 | `recordsHaveHashSizeLanguage()` | `ProjectFileScannerTests.swift:43` | `#expect(!(rec?.hash ?? "").isEmpty)` mis-expands to an unused `Bool?` (compiler warned) — the negation is never evaluated, so a valid hash "fails" | `#require` the record, bind `hash` to a plain `Str
  - 2. Emit a machine-countable summary (`EVAL.md`) with the exact executed `@Test`/pass/fail

## docs/DEVILS_ADVOCATE_ROUND_8_2026-07-31.md
- lines: 126
- headings:
  - # Devil's Advocate — Round 8: "Sending a message does nothing" (2026-07-31)
  - ## 0. Executive verdict
  - ## 1. The chain (verified line-by-line)
  - ## 2. Problems found (devil's-advocate pass)
  - ## 3. TDD evidence
  - ### Round 1 — RED (18 failing assertions on 16 tests)
  - ### Round 1 — GREEN
  - ### Round 2 (edge cases) — RED → GREEN
  - ## 4. Files changed
  - ## 5. Final state
  - ## 6. Remaining risks (accepted, documented)
- unresolved_marker_count: 8
  - | P2 | 🔴 | Web path swallows failures. `try? await bridge.navigate(...)` / `setCookies(...)` silently dropped; `.loggedOut`, `.iterationLimitReached`, `.captchaDetected` mapped to `.status` → written to transient `streamingText` → wiped by `finishWebTurn()` → empty assistant bubb
  - | P3 | 🟠 | `SendRouteResolver.route == .none` has **no branch** in `sendDirectly` — falls through into the serve branch (`createSession` on a dead server). Web route with a deleted config did the same. | New `SendRouteGuard.errorMessage(for:serverConnected:)` + `webConfigMissingM
  - ### Round 1 — RED (18 failing assertions on 16 tests)
  - ✘ Test run with 16 tests in 1 suite failed with 18 issues
  - Every P1–P4 assertion failed exactly as expected.
  - ✘ 3 tests failed (4 issues)  →  ✔ 19 tests passed
  - | `MiCoder/Sources/Services/SendRouteResolver.swift` | `SendRouteGuard.errorMessage` + `webConfigMissingMessage` |
  - | `MiCoder/Sources/Views/ChatPanelView.swift` | `.none` guard; web-config-missing guard; web navigation/cookie errors surfaced; status persists into bubble; thinking placeholder on both paths |

## docs/DEVILS_ADVOCATE_ROUND_9_2026-07-31.md
- lines: 68
- headings:
  - # Devil's Advocate — Round 9: Web model discovery (2026-07-31)
  - ## 0. Executive verdict
  - ## 1. The four defects (each verified)
  - ## 2. What stayed the same (correctly)
  - ## 3. Files changed
  - ## 4. Test result
  - ## 5. How to verify the fix manually
- unresolved_marker_count: 2
  - | **C** | A **failed discovery silently fell back** to `vendor.defaultModels` — no signal that the real list hadn't been read. | Stale defaults looked like a live list; nothing told the user the page failed to parse. | `WebProviderConnectivity.modelsOrError(for:discoveryAttempted
  - must **say so** (via `discoveryFailed`) instead of silently showing the

## docs/FEATURE_REGISTRY.md
- lines: 774
- headings:
  - # MiMoMacOS — Canonical Feature Registry
  - ## F01: Chat Message Send
  - ## F02: SSE Streaming
  - ## F03: Message Queue
  - ## F04: Sidebar — Workspace List
  - ## F05: Sidebar — Navigation History
  - ## F06: Sidebar — Search
  - ## F07: Sidebar — Skills Button
  - ## F08: Sidebar — New Task
  - ## F09: Empty State — Logo and Input
  - ## F10: Input Bar — Workspace Chip
  - ## F11: Input Bar — Model Selector
- unresolved_marker_count: 7
  - **User Story:** As a user, I can edit a sent message or retry a failed response.
  - - Premium dialog with a comment field and auto summary of pending changes
  - **Gaps:** ✅ FIXED — push auto-detects missing upstream and runs `push --set-upstream origin <branch>`
  - - Partial content preserved when available
  - | ⚠️ Partially Implemented | 0 |
  - | ❌ Not Implemented | 0 |
  - 61 fully implemented, 0 partially implemented. Remaining polish items are low-priority UI/UX enhancements:

## docs/FEATURE_SPREADSHEET.csv
- lines: 251
- headings:
- unresolved_marker_count: 53
  - Input,INP-11,Message Queue Indicator,"As a user, I want to see queued messages when sending while loading",Pending messages shown as numbered list,MessageQueueTests,PASS,InputViews.swift
  - Storage,STO-06,File Index Logic,"As a user, I want file index delta computation by hash+mtime",ProjectFileIndexLogic computes changed/removed; used for @ cache,ProjectFileIndexLogicTests,PARTIAL,In-memory only (30s TTL @ cache); no persistent file_index table
  - Storage,STO-07,FSEvents Dynamic Reindexing,"As a user, I want the index to update when files change on disk",No FSEventStream subscription exists,none,MISSING,plan Section 7 п.24-27 greenfield
  - Storage,STO-27,Registry+Settings Export/Import,"As a user, I want to migrate my whole registry+settings to another machine",No export/import for the full registry (only per-project zip),none,MISSING,plan Section 8 п.52
  - Storage,STO-28,Chunked Big-Project Delete,"As a user, I want deleting a huge project to not freeze the UI",deleteProject does synchronous removeItem; no background queue/progress,none,MISSING,plan Section 8 п.53
  - Settings,SET-04,Skills Management Tab,"As a user, I want to see and install agent skills",SkillsSettingsView with installed + library; enable/disable/remove,AgentResourceInstallerTests,PARTIAL,"No Update button, no bulk ops, no export/import, no dependency dialog (Section 3)"
  - Settings,SET-05,MCP Server Management,"As a user, I want to configure MCP servers","MCP list with real health dot (green/red/gray),  enable/disable/remove",SettingsIntegrationTests + E11MCPHealthCheckTests,PARTIAL,No Edit/Update/Install-set
  - Security,SEC-05,Privacy Mode (Future),"As a user, I want to hide message content from UI",NOT IMPLEMENTED - future,none,FUTURE,QUALITY_REPORT.md
  - Security,SEC-06,DB Encryption (Future),"As a user, I want DB at-rest encryption",NOT IMPLEMENTED - FileVault covers,none,FUTURE,QUALITY_REPORT.md
  - Localization,L10-03,Full New-UI Translation,"As a user, I want every new Settings/Sidebar/Chat/Storage string translated","New views (Storage panel, dropdown, web providers, resources) use hardcoded English; only curated keys translated","AppLocalizationTests (everyKeyHasAllLangu

## docs/FEATURE_TEST_REPORT.md
- lines: 470
- headings:
  - # MiCoder — Feature Test Report (canonical)
  - ## Baseline
  - ## Confirmed errors (Phase 2 findings — each verified in code, file:line)
  - ### Category A — Data loss (most severe)
  - ### Category B — Stub / no-op behavior
  - ### Category C — Missing features (logged as MISSING in spreadsheet)
  - ### Category D — UX / correctness issues
  - ## Phase 3 plan (fix order)
  - ## Phase 3 progress
  - ## Round 25 final (2026-08-10) — canonical project routing
  - ## Round 24 final (2026-08-06) — DB/storage hardening and activity audit
  - ## Round 32 (2026-08-13) — mimo-auto and embedded web send recovery
- unresolved_marker_count: 48
  - - Canonical feature status rollup: **225 PASS · 15 PARTIAL · 5 MISSING · 5 FUTURE** across 250 rows.
  - | E08 | **5 slash commands are no-ops**: `/plan`, `/commit`, `/pr`, `/review`, `/context` fall through and just send the raw text to the model instead of opening CommitMessageComposer / GitPublishFlowLogic / plan mode / git review / context. **FIXED (Phase 3)** — `SlashCommandDis
  - | E09 | **`executeWithUndo` has zero production callers** — the per-project undo stack is always empty at runtime; snapshots never created during real tool operations. **FIXED (Phase 3)** — `ProjectWebToolExecutor` now takes an `undoManager` + `sessionId`; `write_file`/`edit_file
  - | E10 | **`request_history` never written in normal flow** — table + API exist, only `importBundle` writes it; applied edits/commands are never logged as requests. **FIXED (Phase 3)** — every successful `write_file`/`edit_file` tool operation appends a `file_edit` row (`payload`
  - | E11 | **MCP health check is a stub** — `MCPRegistryManager.updateHealthCheck` has zero callers; the green dot in the UI reflects `isEnabled`, not real health. **FIXED (Phase 3)** — `MCPHealthCheckLogic` (probe classification: http url vs stdio command+args; real PATH resolution
  - ### Category C — Missing features (logged as MISSING in spreadsheet)
  - | E23 | **Auto-detect adds a provider without user confirmation** — violates "без самодеятельности"; no "Подтвердить и добавить" step. **FIXED (Round 22)** — `LocalProviderConfirmLogic` + `PendingDetection` alert (Confirm/Cancel); cancel never adds; `AutoDetectStatusText` states
  - | E24 | `ProviderAutoDetector.overallTimeout` declared (10s) but **never enforced** — worst case is 4 sequential probes × 2s with no deadline. **FIXED (Round 22)** — hard deadline: each probe races the remaining budget and is cancelled in-flight (`probeOnce`); `URLSessionProvider
  - | R16 | E08 — slash commands perform real actions | `E08SlashCommandDispatchTests` (14 green) + `SlashCommandDispatcher`/`TestRunnerDetector`/`GitUIAction`/`PullRequestDialogView`/`gh pr create`/`AppState.pendingGitAction` sheet | ✅ DONE |
  - Remaining product work is limited to the explicitly tracked PARTIAL/MISSING/FUTURE rows in

## docs/INDEPENDENT_ACCEPTANCE_AUDIT_2026-08-14.md
- lines: 150
- headings:
  - # MiCoder — независимый acceptance-аудит требований из полного диалога
  - ## 1. Границы и честность проверки
  - ## 2. Главные подтверждённые дефекты
  - ### 2.1 Web discovery не является строгим model detector
  - ### 2.2 Expand models обходится неполно и не проверяется по результату
  - ### 2.3 Effort не профилируется в полном login/detection chain
  - ### 2.4 Обнаруженный список моделей скрыт и ограничен
  - ### 2.5 «Выбрать» всё ещё существует как лишнее действие
  - ### 2.6 Remote web chat UUID отсутствует в production chain
  - ### 2.7 Auto Free имеет policy и state, но не подтверждённый внешний результат
  - ## 3. Полный независимый checklist и оценки
  - ### Критический acceptance checklist
- unresolved_marker_count: 16
  - > **Итоговый вердикт:** прежние заявления о том, что web-модели, effort, browser sending и chat isolation «сделаны», не подтверждаются полным end-to-end приёмочным аудитом. По нормализованному чеклисту из 32 крупных требований нет ни одного полностью подтверждённого target-runtim
  - Существующие activity-checklists прямо указывают, что WebKit, Finder, Keychain и внешние аккаунты требуют live macOS-сеанса и должны быть `PARTIAL`, а не `PASS` [1]. Тем не менее cumulative report и canonical CSV содержат множество `PASS` с примечанием «live verification pending»
  - MiCoder Auto Free имеет отдельный OpenCode Zen client, free allow-list, rate-limit policy и fallback loop [8]. NotificationCenter → AppState → ChatPanel banner chain существует, но notification semantic type остаётся `.warning`, хотя пользователь требовал заметный красный failure
  - | `FAIL` по текущей независимой проверке | 14 |
  - | `PARTIAL` | 18 |
  - | Web send через hidden browser | **2/5** | **1/5** | Orchestration присутствует, target WebKit response не проверен и пользователь сообщает failure |
  - | Named independent logins | **4/5** | **3/5** | Pure persistence passed; live two-account cookie switch unverified |
  - | MiCoder Auto Free failover | **3/5** | **2/5** | State/policy/banner chain exists; external send and severity not fully accepted |
  - Частично реализованы named sessions, local WKWebView pool, Auto Free failover policy, provider-local actions, sidebar responsive source, and explicit DOM/AI detection split. They require target-runtime acceptance and currently do not satisfy the user's web requirements because th
  - **P1 — acceptance build.** Run `./build-app.sh` and full `swift test` on a real macOS machine, then execute a scripted manual matrix for Kimi, Qwen, and ChatGPT with screenshots/logs for discovery count, each model's effort state, remote UUID mapping, session switching, and one f

## docs/MIMO_API_RESEARCH_2026-08-13.md
- lines: 31
- headings:
  - # Xiaomi MiMo API verification — 2026-08-13
  - ## MiMo Auto free route
  - ## Bootstrap details from official MiMo Code issue
  - ## Current official free API status
- unresolved_marker_count: 1
  - The official MiMo Code issue #920 documents the free route bootstrap request as `POST https://api.xiaomimimo.com/api/free-ai/bootstrap` with `Content-Type: application/json`, `Authorization: Bearer anonymous`, and a JSON body containing a client fingerprint. It reports that the r

## docs/OPENCODE_BIG_PICKLE_RESEARCH_2026-08-13.md
- lines: 23
- headings:
  - # OpenCode Big Pickle research — 2026-08-13
  - ## Verified official facts
  - ## Sources
- unresolved_marker_count: 1
  - The runtime provider prioritizes Big Pickle, then tries the remaining current free candidates if Big Pickle disappears, returns rate-limit/unavailable, or accumulates five consecutive failed sends.

## docs/OSX_PROXMOX_RESEARCH_2026-08-13.md
- lines: 9
- headings:
  - # OSX-PROXMOX passive review — 2026-08-13
- unresolved_marker_count: 0

## docs/QUALITY_REPORT_2026-07-21.md
- lines: 238
- headings:
  - # Comprehensive Quality Report — All 135 Checklist Items
  - ## 1. DATABASES (Items 1-20) — Overall: 9.8/10
  - ### 1.1 SQLite Database — ✅ 10/10
  - ### 1.2 UserDefaults for UI settings — ✅ 10/10
  - ### 1.3 KeychainManager — ✅ 9/10
  - ### 1.4 FileManager caches — ✅ 9/10
  - ### 1.5 FTS5 Full-Text Search — ✅ 10/10
  - ### 1.6 Schema Migration — ✅ 10/10
  - ## 2. SESSIONS & PROJECTS (Items 21-45) — Overall: 9.5/10
  - ### 2.1 Project Database Schema — ✅ 10/10
  - ### 2.2 Session Database Schema — ✅ 10/10
  - ### 2.3 Session Persistence — ✅ 10/10
- unresolved_marker_count: 6
  - - **Bug fixed**: ❌→✅ FTS5 `-` operator crash (`missing-task` interpreted as column reference) — fixed by double-quoting
  - - **Bug fixed**: ❌→✅ `UNIQUE constraint failed` now caught as `DatabaseError.duplicateEntry` and handled gracefully
  - - **Edge cases**: Concurrent appends, streaming messages partially saved
  - - **Fix**: ⬇️ Missing keyboard shortcut ⌘Z shortcut
  - - **Not implemented**: SQLCipher encryption for `mimo.db`
  - *Generated by automated test suite: 613 tests, 123 suites, 0 failures*

## docs/UI_AUDIT_REPORT.md
- lines: 402
- headings:
  - # UI Elements Audit — Real Working Status
  - ## 1. SETTINGS VIEW (`SettingsView.swift`)
  - ### 1.1 General Settings Tab
  - ### 1.2 Code Preview Settings Tab
  - ### 1.3 Model Settings — MiMo Serve Card
  - ### 1.4 Model Settings — Provider List Column
  - ### 1.5 Model Settings — Provider Detail Column
  - ### 1.6 Model Settings — Models Column
  - ### 1.7 Add Provider Sheet
  - ### 1.8 Skills Settings Tab
  - ### 1.9 MCP Servers Settings Tab
  - ### 1.10 Plugins Settings Tab
- unresolved_marker_count: 2
  - | 112 | **Message queue** | Pending messages display | ✅ **Работает** |
  - | 189 | **Error display** | Error message on failure | ✅ **Работает** |

## docs/WEB_SEND_UI_AUDIT_2026-08-13.md
- lines: 53
- headings:
  - # Аудит отправки и интерактивных элементов MiCoder
  - ## Подтверждённые проблемы по исходному коду
  - ## Карта поведения кнопок
  - ## Первичный план исправлений
  - ## Фактический macOS smoke round from user screenshots — 2026-08-13
- unresolved_marker_count: 2
  - Сначала нужно сделать единый объект выбора для web-провайдера: provider ID, model ID, effort и transport должны изменяться одной операцией и сразу сохраняться в `WebProviderStore`. Затем web composer должен показывать только реально обнаруженные модели и effort либо явно маркиров
  - | WEB-13 | ChatGPT send failed with `effort selector not found`. | `injectModelAndEffort` treated the optional effort control as mandatory. | Missing optional effort control no longer blocks a normal send; model/input/send controls remain verified. |

## docs/ZCODE_PARITY_IMPLEMENTATION_PLAN.md
- lines: 232
- headings:
  - # MiMoMacOS -> ZCode Parity Implementation Plan
  - ## Current Evidence
  - ## Non-Negotiable Constraints
  - ## Reference Surfaces From Screenshots
  - ## Current Gaps
  - ## Implementation Steps
  - ### Step 1: Restore Compilation
  - ### Step 2: Fix Data Models Needed For Parity
  - ### Step 3: Rebuild Main ZCode Layout Without Changing Theme
  - ### Step 4: Match Empty State And Input Bar
  - ### Step 5: Fix Sidebar Functionality
  - ### Step 6: Fix Chat/Session Send Flow
- unresolved_marker_count: 7
  - 1. `swift build` inside the sandbox fails because Swift cannot write to `/Users/apple/.cache/clang/ModuleCache`.
  - 2. `swift build` outside the sandbox reaches source compilation and fails in `MiMoMacOS/Sources/Views/ChatPanelView.swift` because `[weak self]` is used inside a `struct View`.
  - 5. The current SwiftUI code already contains partial implementations of those surfaces, but several are incomplete, disconnected, or branded as MiMo instead of matching the ZCode interaction model.
  - 5. Keep implementation scoped to this Swift package and existing MiMo Serve APIs unless a missing API is explicitly documented.
  - - Workspace row hover actions are missing.
  - - Plus menu is missing `Insert / command`.
  - 4. If progress API is missing, show an empty/unknown progress state instead of fake project-specific Russian steps.

## docs/activity-checklists/00-index.md
- lines: 51
- headings:
  - # Актуальный чеклист активити MiCoder
  - ## Ограничение
  - ## Активити
  - ## Ошибки
  - ## Обязательный цикл
- unresolved_marker_count: 8
  - аккаунтах требуют live macOS-сеанса и отмечены `PARTIAL`, а не выданы за PASS.
  - | `05-web-login.md` | Web login/model discovery | PARTIAL без live WebKit |
  - | `06-web-chat.md` | Web chat/effort/features | PARTIAL без внешних аккаунтов |
  - | `13-live-qa-2026-08-11.md` | Live Kimi/ChatGPT/Qwen | Kimi/Qwen PASS; ChatGPT PARTIAL |
  - | `14-send-providers.md` | Send routing for every provider | PASS by route tests; external sends pending |
  - | `error-03-chatgpt-stale-models.md` | ChatGPT показывал stale/feature entries как модели | FIXED in source policy; live verify pending |
  - | `error-04-qwen-discovery.md` | Qwen discovery теряла дополнительные модели | FIXED in source path; live verify pending |
  - | `error-06-project-failed-send.md` | Неуспешная первая отправка теряла чат | FIXED in persistence path; regression test pending |

## docs/activity-checklists/01-app-shell.md
- lines: 59
- headings:
  - # Activity 01 — App Shell
  - ## Control and action inventory
  - ## Round 49 adversarial chain result
  - ## User story
- unresolved_marker_count: 16
  - | 1 | WindowGroup | `MiCoderApp.body` → `WindowGroup` → root `ContentView` receives `appState` → macOS window renders | Открывает окно с min 900×600 и default 1200×750 | 100/100 | 100/100 | UNVERIFIED — requires macOS |
  - | 2 | Startup task | `ContentView.task` → `loadCustomProviders()` → `connectToServer()` → `ServerConnectionReadinessLogic` copies completed health result to `AppState.serverConnected` → sessions load from local DB; server models load only when the same health check is online → `p
  - | 3 | Sidebar visibility | `SidebarView` button → `appState.sidebarVisible` → `ContentView` conditional HStack branch → sidebar appears/disappears | Показывает/скрывает SidebarView without losing main content | 95/100 | 95/100 | UNVERIFIED — macOS UI required |
  - | 4 | Sidebar resize handle | drag/double-click → `SidebarResizeLogic.applyDrag` / reset → `@AppStorage("sidebarWidth")` → `ContentView` frame | Drag 200..420, double-click reset 260, persistence across launches | 95/100 | 100/100 | PARTIAL — logic tested; macOS drag/persistence
  - | 5 | TopBarView | root layout → `TopBarView` → app-state actions → header controls update state | Собирает one unified header without a second project-dependent header | 90/100 | 95/100 | UNVERIFIED — macOS UI required |
  - | 6 | ChatPanelView | root layout → `ChatPanelView` → selected session/messages or empty state → visible composer | Показывает empty state or message feed and keeps composer reachable without a selected project | 90/100 | 100/100 | UNVERIFIED — macOS UI required |
  - | 7 | BottomPanelView | `showTerminal` state → conditional divider/panel → terminal/Git controls consume selected session | Показывает terminal/Git panel only when enabled; status bar remains visible | 95/100 | 95/100 | UNVERIFIED — macOS UI required |
  - | 8 | RightPanelView | `showGoal` state → conditional divider/panel → goal/plan content consumes selected session | Показывает plan/Git panel only when enabled and does not duplicate the main header | 95/100 | 95/100 | UNVERIFIED — macOS UI required |
  - | 9 | Settings overlay | settings action → `showSettings` → overlay plus backdrop/Escape/close binding → state false | Открывается above the app and closes through backdrop, Escape, or close action | 95/100 | 100/100 | UNVERIFIED — macOS UI required |
  - | 10 | Search sheet | Cmd+K/menu → `showSearch` → `.sheet` presents `SearchPaletteView` → search selection updates app state | Открывает SearchPaletteView and returns focus to the workspace | 95/100 | 95/100 | UNVERIFIED — macOS UI required |

## docs/activity-checklists/02-sidebar.md
- lines: 35
- headings:
  - # Активити: Sidebar и Workspace
  - ## User story
- unresolved_marker_count: 0

## docs/activity-checklists/03-chat.md
- lines: 37
- headings:
  - # Активити: Chat Composer и Message Feed
  - ## User story
- unresolved_marker_count: 3
  - | 13 | Stop | Отменяет task/SSE/server and preserves partial content | PASS |
  - | 18 | Failed send | Создает/сохраняет local session, user message and error | PASS, regression test |
  - even when its provider request fails.

## docs/activity-checklists/04-settings-providers.md
- lines: 28
- headings:
  - # Активити: Settings и Providers
  - ## User story
- unresolved_marker_count: 2
  - | 8 | Skills/MCP/Plugins/Commands | Browse/install/enable/remove or list resources | PASS/PARTIAL per CSV |
  - | 10 | Usage | Shows stored token usage and filters | PARTIAL for cost/project aggregation |

## docs/activity-checklists/05-web-login.md
- lines: 29
- headings:
  - # Активити: Web Provider Login и Discovery
  - ## User story
- unresolved_marker_count: 2
  - | 2 | Login | Открывает embedded WebView | PARTIAL, live WebKit |
  - | 3 | Capture session | Сохраняет cookies after login | PARTIAL, live WebKit |

## docs/activity-checklists/06-web-chat.md
- lines: 28
- headings:
  - # Активити: Web Chat Driver
  - ## User story
- unresolved_marker_count: 1
  - | 10 | Error event | Emits error and persists failed turn through caller | PASS by code |

## docs/activity-checklists/07-mimo-auto.md
- lines: 26
- headings:
  - # Активити: MiMo-Auto Provider
  - ## User story
- unresolved_marker_count: 2
  - | 3 | Model refresh | Keeps free fallback on API failure | PASS |
  - | 8 | Failed request | Leaves user/assistant error in local session | PASS, regression test |

## docs/activity-checklists/08-project-session.md
- lines: 27
- headings:
  - # Активити: Project и Session Persistence
  - ## User story
- unresolved_marker_count: 3
  - | 2 | Choose folder | NSOpenPanel selects one directory | PARTIAL, native QA |
  - | 6 | Request failure | Persists user message and error assistant message | PASS, regression test |
  - As a user, creating a project never produces a disappearing chat: even a failed

## docs/activity-checklists/09-shell-status.md
- lines: 31
- headings:
  - # Активити: Header, Status и macOS Menu
  - ## User story
- unresolved_marker_count: 1
  - | 13 | Cmd+X/C/V/A | Routes responder actions/paste | PARTIAL, native focus QA |

## docs/activity-checklists/10-regression-loop.md
- lines: 24
- headings:
  - # Regression Loop
- unresolved_marker_count: 1
  - | 5 | Record every failure | COMPLETE: no failing tests; native/network limits documented |

## docs/activity-checklists/11-causal-chain.md
- lines: 111
- headings:
  - # Причинно-следственная карта
  - ## Chain A: MiMo-Auto send
  - ## Chain B: Web model discovery
  - ## Chain C: Web effort
  - ## Chain D: Failed first request
  - ## Chain E: Provider readiness
  - ## Remaining external boundary
- unresolved_marker_count: 4
  - ## Chain D: Failed first request
  - -> persistRejectedMessage on preflight failure
  - **Result:** PASS by `failedFirstSendIsPersisted` and full suite.
  - full model list, and actual MiMo API response. They remain `PARTIAL/live-QA`.

## docs/activity-checklists/12-quality-recheck.md
- lines: 116
- headings:
  - # Полный checklist качества функций
  - ## MiMo-Auto
  - ## Readiness and persistence
  - ## Web configuration and connectivity
  - ## Discovery and parser
  - ## Web driver
  - ## UI handlers
  - ## Final gate
- unresolved_marker_count: 7
  - Статусы: `PASS` = функция проверена цепочкой и тестом; `PARTIAL` = внешний
  - | `persistRejectedMessage` | stores failed preflight turn | PASS |
  - | `persistUnsentMessage` | stores failed request turn | PASS |
  - | `WebProviderLoginView.capture` | captures cookies and dismisses | PARTIAL, live WebKit |
  - | `WebViewRepresentable` | attaches and loads URL | PARTIAL, live WebKit |
  - - [x] Failed first-send persistence regression passes.
  - - [ ] Live ChatGPT discovery remains PARTIAL: page/cookies work, model result did not appear.

## docs/activity-checklists/13-live-qa-2026-08-11.md
- lines: 81
- headings:
  - # Live QA: Kimi / ChatGPT / Qwen
  - ## Kimi
  - ## Qwen
  - ## ChatGPT
  - ## Important binary distinction
  - ## Causal verdict
- unresolved_marker_count: 7
  - | Effort refresh | Кнопка `brain.head.profile` доступна | PARTIAL, result not exposed in AX |
  - | Send | Не выполнялся без отдельного disposable prompt/network result | PARTIAL |
  - | Effort refresh | Кнопка `brain.head.profile` доступна | PARTIAL, result not exposed in AX |
  - | Send | Не выполнялся без отдельного disposable prompt/network result | PARTIAL |
  - | Model discovery | Нажат `Find models` на старом installed binary; результат не появился за 10 s | FAIL/PARTIAL |
  - | Effort discovery | Selector exists in source/catalog; live result not observed | PARTIAL |
  - - ChatGPT: `login -> cookies -> page -> discovery` — разрыв между page и discovery, PARTIAL.

## docs/activity-checklists/14-send-providers.md
- lines: 45
- headings:
  - # Send Providers Checklist
  - ## Verified route invariants
  - ## Evidence
  - ## External boundary
- unresolved_marker_count: 7
  - | MiMo-Auto | Free tier accepted without Serve/API key | `.mimoAuto` | `MiMoAutoProviderStore.streamChat` -> `MiMoAutoClient.chatCompletion` | PASS by tests; live API pending |
  - | MiMo Serve | Requires connected server | `.mimoServe` | `MimoServeClient.createSession/sendMessage` + SSE | PASS by tests; live Serve pending |
  - | Web Kimi | Cookie + ToS + discovered model | `.web(kimi)` | `WebChatDriver.runTurn` | PASS by readiness/route; live send pending |
  - | Web Qwen | Cookie + ToS + discovered model | `.web(qwen)` | `WebChatDriver.runTurn` | PASS by readiness/route; live send pending |
  - | Web ChatGPT | Cookie + ToS + one discovered model | `.web(chatgpt)` | `WebChatDriver.runTurn` | PASS by readiness/route; live send pending |
  - - Failed route/request persists an error message in the project session.
  - - Full `swift test`: **1858 tests / 265 suites / 0 failures**.

## docs/activity-checklists/FINAL_REPORT.md
- lines: 69
- headings:
  - # Итоговый отчёт: Проверка отправки сообщений
  - ## Исправленные проблемы
  - ### 1. MiMo-Auto send validation
  - ### 2. Сообщения не сохранялись в базу
  - ### 3. acknowledgedToS убран
  - ### 4. Локальный API для тестирования
  - ## Результаты проверки
  - ## Архитектура отправки
  - ## Ограничения
  - ## Статус кода
- unresolved_marker_count: 1
  - - `swift test`: 1858 tests, 265 suites, 0 failures

## docs/activity-checklists/error-01-mimo-auto-default.md
- lines: 20
- headings:
  - # Ошибка 01: MiMo-Auto default
- unresolved_marker_count: 0

## docs/activity-checklists/error-02-web-model-picker.md
- lines: 19
- headings:
  - # Ошибка 02: Browser model picker
- unresolved_marker_count: 0

## docs/activity-checklists/error-03-chatgpt-stale-models.md
- lines: 19
- headings:
  - # Ошибка 03: ChatGPT stale models/features
- unresolved_marker_count: 2
  - | Feature modes | Not mixed into model list | PARTIAL, live DOM verification |
  - | UI result | One current model where site has one | PARTIAL, live account needed |

## docs/activity-checklists/error-04-qwen-discovery.md
- lines: 19
- headings:
  - # Ошибка 04: Qwen discovery
- unresolved_marker_count: 1
  - | Live Qwen result | All current models | PARTIAL, live account needed |

## docs/activity-checklists/error-05-effort-visibility.md
- lines: 19
- headings:
  - # Ошибка 05: Effort visibility
- unresolved_marker_count: 0

## docs/activity-checklists/error-06-project-failed-send.md
- lines: 20
- headings:
  - # Ошибка 06: Project created, first send failed
- unresolved_marker_count: 5
  - # Ошибка 06: Project created, first send failed
  - **User story:** As a user, after creating a project, a failed first request still
  - | Network failure | Persists unsent user message and error | FIXED path exists |
  - | Web failure | Creates local session before web turn | PASS |
  - | Regression test | Forced failure verifies stored rows | PASS |

## docs/clipboard_paste_verification.md
- lines: 84
- headings:
  - # Clipboard Paste Verification
  - ## Summary
  - ## Automated verification
  - ### Synthetic pasteboard types exercised
  - ## Live probe notes
  - ## Manual checklist
  - ## Manual repro 2026-06-21
  - ## Architecture
- unresolved_marker_count: 1
  - In headless/CI environments `screencapture -c` may fail (`could not create image from display`). The verify script falls back to seeding the general pasteboard with the same multi-type layout used by macOS screenshots, then runs `MIMO_CLIPBOARD_PROBE=1 swift test --filter LiveCli

## docs/devils_advocate_round_1_2026-07-17.md
- lines: 76
- headings:
  - # Devil's Advocate Review — Round 1 (2026-07-17)
  - ## Scope and method
  - ## Findings: 39 discrepancies total
  - ### A. FEATURE_REGISTRY.md (24 findings — all fixed in this round)
  - ### B. Other documents (15 findings — all fixed in this round)
  - ## Code-level issues carried to Round 2 (require TDD fixes, not doc edits)
  - ## Round 1 verdict
- unresolved_marker_count: 4
  - | 2 | F04 | "Hover actions not implemented" — they are | Gap cleared |
  - | 3 | F06 | "UI partially wired" — Cmd+K fully opens SearchPaletteView | Status fixed |
  - | 33 | plans/1_parity.md | "FULL PARITY 45/45" — F44/F55/F58/F59 partial | Correction banner |
  - | 38 | project-review/ | Referenced 1.md / 1_parity.md missing (live in plans/) | Noted here; files not moved |

## docs/devils_advocate_round_2_2026-07-17.md
- lines: 51
- headings:
  - # Devil's Advocate Review — Round 2 (2026-07-17)
  - ## Fixed in this round
  - ### 1. User-reported: prompt field on first entry did not autogrow
  - ### 2. User-reported: pasting plain text was misrouted as an image attachment
  - ### 3. F19 — inline italic in markdown
  - ### 4. F08 — Cmd+N did not focus the message input
  - ### 5. F55 — dead `GoalPanelView` removed
  - ### 6. F31 — auto `--set-upstream` on first push
  - ## Remaining debts (carried to Round 3 candidates)
  - ## Verification
- unresolved_marker_count: 2
  - - `consumeByScanningAllItemTypes` probed **every** pasteboard type (including text types) and, when `NSImage(data:)` failed, still fell through to `ClipboardImage(imageData:mimeType:)`;
  - `GitRepository.push` ran bare `git push`, which fails on a branch without upstream.

## docs/devils_advocate_round_3_2026-07-21.md
- lines: 93
- headings:
  - # Devil's Advocate Review — Round 3 (2026-07-21)
  - ## Full-chain audit: every document, every source file, every issue
  - ## Audit Method
  - ## All Issues Found (25 total)
  - ### 🔴 CRITICAL (4)
  - ### 🟡 MEDIUM (12)
  - ### 🟢 LOW (6)
  - ### ⚠️ REGISTRY GAPS (3 from Round 2)
  - ## Fix Plan (TDD — Red, Green, Refactor)
  - ### Round 3 Fix Order
  - ## Verification Gate
- unresolved_marker_count: 2
  - | M8 | **Review & Push — calls push even if commit fails** | `RightPanelView.swift` | No error check between commit and push |
  - Each fix follows: failing test → implementation → `swift test` → verify.

## docs/devils_advocate_round_4_2026-07-22.md
- lines: 163
- headings:
  - # Devil's Advocate Round 4 — Завершён
  - ## 📊 Итоговая статистика
  - ## 🔧 Что реализовано (7 работ)
  - ### 1. 🔴 F51 — Stop/abort flow test coverage
  - ### 2. 🔴 F44 — ACP Protocol Client
  - ### 3. 🟡 UI Audit #84 — Session row tap accessibility
  - ### 4. 🟡 UI Audit #93 — Dead `showFiles` toggle
  - ### 5. 🟡 UI Audit #104 — Endpoint в статусбаре при disconnect
  - ### 6. 🟡 UI Audit #164 — Git pull output не используется
  - ### 7. 🟡 UI Audit #108 — Каскадная загрузка через onAppear
  - ### 8. 🟡 UI Audit #123 — SSE ID reconciliation orphan в БД
  - ### 9. 🟡 F58 — Workspace sorting/filtering
- unresolved_marker_count: 3
  - **Цель:** Закрыть все оставшиеся ⚠️ partially implemented features (+ F51 тесты + UI audit)
  - ⚠️ Partially Implemented:  0
  - ❌ Not Implemented:         0

## docs/devils_advocate_round_5_2026-07-23.md
- lines: 111
- headings:
  - # Devil's Advocate Round 5 — Полный аудит + исправления
  - ## 🔍 Найденные проблемы (6)
  - ### 🔴 1. Добавление вкладки Providers сломало тесты (Fixed)
  - ### 🔴 2. ProvidersSettingsView — .constant вместо @State (Fixed)
  - ### 🟡 3. ProviderRowView — delete button невидим (Fixed)
  - ### 🟡 4. ACPClient — полный orphan (Gap, не исправлен)
  - ### 🟡 5. Undo Cmd+Z keyboard shortcut (Gap, известный)
  - ### 🟢 6. variantMenuDisabledReason не используется (Gap, известный)
  - ## 📊 Статистика после Round 5
  - ## 📝 Изменённые файлы
  - ### SettingsView.swift
  - ### SettingsIntegrationTests.swift
- unresolved_marker_count: 1
  - **Статус:** ⚠️ Partially Implemented (код есть, интеграции нет)

## docs/devils_advocate_round_6_2026-07-23.md
- lines: 142
- headings:
  - # Devil's Advocate Round 6 — Полный аудит + исправления
  - ## 🔍 Найденные проблемы (6 + 5 documented, 7 fixed, 2 documented as remaining gaps)
  - ### 🔴 0. Launch crash — Bundle.module assertion (Fixed)
  - ### 🔴 0b. Flaky тесты — UserDefaults race condition (Fixed)
  - ### 🔴 1. F59 — taskCompleted() trigger мёртвый код (Fixed)
  - ### 🟡 2. Тест flaky — UserDefaults race condition (Fixed)
  - ### 🟡 3. Undo Cmd+Z keyboard shortcut (Fixed)
  - ### 🟢 4. Full135ChecklistVerificationTests.swift.bak (Fixed)
  - ### 🟡 5. F44 — ACPClient orphan (Gap, не исправлен)
  - ### 🟡 6. F14 — variantMenuDisabledReason не используется (Gap, не исправлен)
  - ### 🟢 7. Light theme .foregroundColor(.white) — False positives
  - ### 🟡 8. Локализация новых вкладок Settings — не исправлено
- unresolved_marker_count: 3
  - **Проблема:** `Bundle.module` падал с `EXC_BAD_INSTRUCTION` (assertion failure) на executable targets. Крашился при старте приложения при загрузке MiMo логотипа.
  - **Тесты:** 1241 ✅ pass (был 1 failure)
  - **Статус:** ⚠️ Partially Implemented — код ACP клиента (26 тестов) существует, но не интегрирован в send pipeline. Подтверждено повторно.

## docs/light_theme_audit_2026-06-20.md
- lines: 49
- headings:
  - # Sci-Fi Light theme audit
  - ## Automated token checks
  - ## Token fixes applied
  - ## Manual screen matrix (L1–L16)
  - ## Sign-off
- unresolved_marker_count: 1
  - **FAIL count: 0**

## docs/mimo_zcode_parity_2026-06-20.md
- lines: 127
- headings:
  - # MiMoMacOS — ZCode Functional Parity Checklist
  - ## Блок 1: Baseline & Build (1–10)
  - ### Прогресс блока 1
  - ## Блок 2: Session & Data Models (11–20)
  - ### Прогресс блока 2
  - ## Блок 3: Layout Shell (21–30)
  - ## Блок 4: Sidebar & Input (31–40)
  - ## Блок 5: Panels, Chat, Settings (45–54)
  - ## Блок 6: Verification (56–60)
  - ### Прогress блока 6
  - ## Build Loop
  - ## Remaining non-blocking gaps
- unresolved_marker_count: 4
  - > **TDD loop:** failing test → implement → `swift test` → `./build-app.sh` → mark ✅
  - ✅ 3. Запустить `swift test`, собрать список failing suites
  - ✅ 46. Progress: plan/todo из TodoWrite, markdown, step markers при открытии сессии
  - Automated tests pass. Sidebar toolbar + footer implemented. Session git/plan load on open implemented. Manual screenshot compare pending.

## docs/provider_cascade_api_probe.md
- lines: 113
- headings:
  - # Provider cascade API probe
  - ## Endpoints used by the macOS app
  - ## `GET /config/providers` schema (observed)
  - ### `MimoProviderModel`
  - ### `capabilities` (per model)
  - ## `GET /global/config` schema (observed)
  - ## Send body contract
  - ## Custom providers (local)
  - ## Model ID collisions
  - ## MCP / skills / plugins / commands (filesystem)
  - ## Live test
  - ## Sign-off
- unresolved_marker_count: 0

## docs/qa/apple_design_skill_checklist.md
- lines: 84
- headings:
  - # Apple Design Skill — Inclusion Checklist & Quality Audit
  - ## Current Status
  - ## Apple Design SKILL.md Content Analysis
  - ### Topics Covered (from SKILL.md)
  - ### Code Examples
  - ### Strengths
  - ### Weaknesses
  - ## Decision: Include in MiCoder?
  - ### Arguments FOR inclusion
  - ### Arguments AGAINST
  - ### Recommendation: INCLUDE with adaptation
  - ## Quality Score if Included As-Is: 75/100
- unresolved_marker_count: 0

## docs/qa/hardcoded_strings_checklist.md
- lines: 189
- headings:
  - # Hardcoded Strings — Localization Checklist
  - ## Summary
  - ## Legend
  - ## ChatPanelView.swift
  - ## MessageRowView.swift
  - ## SidebarView.swift
  - ## WebProvidersSection.swift
  - ## InputControls.swift
  - ## InputViews.swift
  - ## NewProjectSheet.swift
  - ## GitPremiumDialogs.swift
  - ## BottomPanelView.swift
- unresolved_marker_count: 2
  - | 🟡 Partial | 0 |
  - - 🟡 Partially (some languages missing)

## docs/qa/locale-fix-plan.md
- lines: 13
- headings:
  - # Исправление локализации — План
  - ## Текущая проблема
  - ## Шаги
- unresolved_marker_count: 0

## docs/qa/mcp_servers_checklist.md
- lines: 98
- headings:
  - # MCP Servers Tab — Feature Checklist & Quality Audit
  - ## Architecture Overview
  - ## Feature Matrix
  - ## Root Cause Analysis: Slowness
  - ### Problem 1: Health probes fire on every `.onAppear`
  - ### Problem 2: No concurrency limit
  - ### Problem 3: `probeHTTP` has no visible timeout
  - ### Problem 4: Registry cache is per-row
  - ## Quality Score: 55/100
  - ### Strengths
  - ### Weaknesses
  - ## Recommended Fixes
- unresolved_marker_count: 2
  - | Parse mcp.json | `parseMCPConfig(at:)` | ✅ Works | 90/100 | Handles missing file gracefully |
  - | Cache check (avoid re-probe) | `MCPHealthCheckLogic.status()` | ⚠️ Partial | 50/100 | **Checks registry but still probes when unknown** |

## docs/qa/web-providers-test-results.md
- lines: 80
- headings:
  - # Web Provider Model Detection — Test Results
  - ## Summary
  - ## Kimi (Moonshot AI)
  - ### Selectors
  - ### Models Found
  - ### Flow
  - ## Qwen (Alibaba)
  - ### Selectors
  - ### Models Found
  - ### Flow
  - ## ChatGPT (OpenAI)
  - ### Issue
- unresolved_marker_count: 0

## docs/qa/web_model_autodetect_checklist.md
- lines: 133
- headings:
  - # Web Model Auto-Detection — Feature Checklist & Quality Audit
  - ## Architecture Overview
  - ## Feature Matrix
  - ## Root Cause Analysis: Model Detection Fails
  - ### Problem 1: No wait for full page load
  - ### Problem 2: Catalog selectors incomplete
  - ### Problem 3: JavaScript injection is fragile
  - ### Problem 4: No manual override / feedback
  - ### Problem 5: Session/cookie restoration not validated
  - ## Quality Score: 38/100
  - ### Strengths
  - ### Weaknesses
- unresolved_marker_count: 10
  - | Parse model names from DOM | `WebModelListParser` | ⚠️ Partial | 40/100 | **Regex/JS based, vendor-specific** |
  - | Auto-detect and save models | `WebProviderStore.upsert()` | ⚠️ Partial | 35/100 | **Only if discovery succeeds** |
  - | Show discovered models in UI | `ProvidersSettingsView` | ⚠️ Missing | 30/100 | **No indication of discovery success/failure** |
  - ## Root Cause Analysis: Model Detection Fails
  - "anthropic": { ... }  // ← may be missing
  - - If auto-detect fails → silent failure
  - - ❌ **Incomplete catalog** (many vendors missing)
  - - ❌ **No success/failure feedback**
  - 4. If auto-detect fails, I can click "Retry" after page fully loads
  - | P0 | Manual "Detect Models" button | Recovery from failure |

## docs/superpowers/plans/2026-07-22-provider-settings-enhancement.md
- lines: 533
- headings:
  - # Provider Settings Enhancement Implementation Plan
  - ## Understanding the Current Architecture
  - ### Current State (from codebase analysis):
  - ## Implementation Task Breakdown
  - ### Task 1: Add Providers Tab to SettingsTab
  - ### Task 2: Create ProvidersSettingsView
  - ### Task 3: Implement Spoiler Functionality for Model Parameters
  - ### Task 4: Add API Endpoint Configuration for Provider Types
  - ### Task 5: Add Provider/Model Counts with Chips
  - ### Task 6: Write Tests for New Functionality
  - ### Task 7: Commit and Push Changes
  - ## Files Summary
- unresolved_marker_count: 1
  - Fixes provider management UX issues and adds missing functionality."

## mimo_settings_full_overhaul_2026-07-23.md
- lines: 1067
- headings:
  - # MiMo macOS — полный план доработки (Settings/Providers, i18n, Skills, MCP, Storage, Sidebar)
  - ## Раздел 1. Providers: убрать MiMo Serve из UI, объединить "Model settings" + "Providers" → одна вкладка "Providers", добавить локальных провайдеров (Ollama/OpenCode/mimocode)
  - #### Блок 1 (1–10) — анализ и модель данных
  - #### Блок 2 (11–20) — удаление MiMo Serve карточки из UI
  - #### Блок 3 (21–30) — объединение вкладок Model settings + Providers
  - #### Блок 4 (31–40) — локальные провайдеры: Ollama / OpenCode / mimoCLI
  - #### Блок 5 (41–50) — интеграция, тесты, регрессия
  - ## Раздел 2. Полная локализация приложения (все строки) + кастомный дропдаун языков с флагами
  - #### Блок 1 (1–10) — инвентаризация строк
  - #### Блок 2 (11–20) — архитектура локализации
  - #### Блок 3 (21–30) — переводы на 10 языков
  - #### Блок 4 (31–40) — кастомный дропдаун языков с флагами
- unresolved_marker_count: 3
  - ⬜ 52. Финальная приёмка: каталог ≥45 записей, полный CRUD (Create/Read/Update/Delete/Enable/Disable) работает для skills без единого "TODO"/заглушки в коде.
  - ⬜ 21. `/todo` — вставить/показать список TODO из проекта (grep по `// TODO`/`# TODO`) прямо в чат как контекст.
  - - Ни один пункт не предполагает заглушек/фейковых данных/TODO вместо логики — везде указана конкретная реализация, интеграция с реальными существующими сервисами или явное решение по продакшен-контракту.

## plans/1.md
- lines: 171
- headings:
  - # Описание интерфейса ZCode — Скриншот 1_1
  - ## Состояние: Открыт выпадающий список выбора рабочего пространства
  - ## Левая боковая панель (Sidebar)
  - ### Верхняя группа — основные действия
  - ### Средняя группа — список рабочих пространств
  - ### Нижняя группа — профиль и настройки
  - ## Центральная область — главное рабочее пространство
  - ### Заголовок экрана
  - ## Выпадающий список выбора рабочего пространства (АКТИВНЫЙ ЭЛЕМЕНТ)
  - ### Поле поиска "Search workspaces"
  - ### Элемент списка "tm3"
  - ### Элемент списка "ZCodeProject" (выбран, отмечен галочкой)
- unresolved_marker_count: 0

## plans/1_parity.md
- lines: 127
- headings:
  - # Parity Check: ZCode Plan vs MiMoMacOS Implementation
  - ## Status: ✅ FULL PARITY ACHIEVED (historical claim — see note above)
  - ## SIDEBAR
  - ## CHAT AREA
  - ## INPUT BAR
  - ## WORKSPACE DROPDOWN
  - ## MODELS
  - ## ACCESS LEVEL
  - ## THINKING LEVEL
  - ## SETTINGS PERSISTENCE
  - ## NAVIGATION
  - ## SIDEBAR TOGGLE
- unresolved_marker_count: 1
  - > **Historical document.** Corrections as of 2026-07-17: parity is near-complete but not "45/45" — F44 (ACP client), F55 (GoalPanelView is dead code), F58, F59 remain partial; the empty state shows the MiMo logo mark ("mi"), not `Text("Z")`; the username comes from `NSFullUserNam
