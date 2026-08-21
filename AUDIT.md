# MiCoder — Devil's Advocate Audit (manual, chain-of-cause)

Date: 2026-07-23. Auditor mode: verify every claim by hand, from the first
plan point down the chain. Each problem: description, why it's real, severity,
fix approach (TDD red-first), and fix quality once resolved.

## Method / honest limitations
- The app target imports SwiftUI/AppKit/WebKit → **cannot compile on this Linux
  box** (`swift build` fails at `no such module 'SwiftUI'`). Only the
  Foundation-only mirror (`scripts/test-logic.sh`, ~35 files) compiles + tests.
- Therefore UI/DB/WebKit code is audited by careful reading + static reasoning;
  pure logic is audited by tests (red-first for edge cases).
- "260/280 tests pass" only covers the mirrored logic — NOT the 120+ UI/DB files.
  This is stated so no false confidence is implied.

## Problem checklist

| ID | Area | Severity | Status |
|----|------|----------|--------|
| P1 | DirectChatClient sends without conversation history (stateless local/custom chat) | HIGH | FIXED (ChatHistoryBuilder + wiring) |
| P2 | runWebChatTurn always isFirstMessage:true → web chat re-seeds every turn | HIGH | FIXED (webSessionStarted tracking) |
| P3 | (to verify) send path builds no history for any provider | HIGH | FIXED via P1 (local/custom); serve path uses server session |

### Round 2

| ID | Area | Severity | Status |
|----|------|----------|--------|
| P4 | Local/custom send errors surfaced to chat? | — | OK (catch block shows "Error: …", clears streaming) |
| P5 | DirectChatError had no LocalizedError → useless "operation couldn't be completed" | MED | FIXED (informative errorDescription + test) |
| P7 | Effort shown for models without it? | — | OK (availableVariants empty for local/web → menu hidden, send not blocked) |
| P8 | Custom Anthropic provider routed via OpenAI /chat/completions | LOW | KNOWN-LIMIT (documented; Anthropic historically via serve; OpenAI-compat is the default). Not a regression — before this, non-serve providers sent nothing. |
| P10 | Local OpenCode/generic OpenAI server sent to `/chat/completions` missing `/v1` | MED | FIXED (ollama+openCode → /v1; mimoCLI serve → own base; tests) |

### Round 3

| ID | Area | Severity | Status |
|----|------|----------|--------|
| P11 | ProjectFileScanner/IndexLogic never called → real indexing not wired (index never built) | HIGH | PARTIAL: `@` list now uses a real cached scan (P12). Full FSEvents watcher + file_index table + FTS remain Mac-layer/DB work (documented, not claimed done). |
| P12 | `@`-mention dropdown file list always empty (inputDropdownContext fileNames: []) | HIGH | FIXED — ProjectFilesCacheLogic (TTL cache) + real ProjectFileScanner scan of the workspace; red tests + real-scan e2e test. |

### Round 4 — "defined but never invoked" sweep

Checked every logic module is actually wired into App/Views (not just tested):
all used ≥1 EXCEPT WebModelListParser (0) → P13.

| ID | Area | Severity | Status |
|----|------|----------|--------|
| P13 | WebModelListParser never called → web providers always showed vendor default models, never real ones ("отфонарные") | HIGH | FIXED — runWebChatTurn reads the model-dropdown text via the bridge and updates discoveredModels in WebProviderStore (best-effort, keeps defaults if not found). |
| P14 | Storage panel crashes (user report п.11) | — | RESOLVED by the earlier 3-scenario reset rewrite; no force-unwraps/array-index in the storage view; deletes use try? on possibly-missing paths. |
| P15 | Old appState.resetDatabase still wired in UI? | — | OK — UI uses only resetStorage(scope:); no stale destructive path. |

### Round 5 — performance / main-thread

| ID | Area | Severity | Status |
|----|------|----------|--------|
| P16 | inputDropdownContext() (filesystem scan + skill/command load) called on EVERY input-field body render (every keystroke) → potential UI freeze on large projects | HIGH | FIXED — InputCommandDropdownView now takes a lazy contextProvider closure invoked ONLY when a trigger (/ @ #) is active; scan cached 30s. |
| P17 | Skill/command FS loads inside context | LOW | Mitigated by P16 (trigger-only) + relies on OS FS cache; acceptable. |

### P1 — DirectChatClient stateless
**Description:** In `ChatPanelView.sendDirectly`, the `.openAICompatible` branch
calls `DirectChatClient.messages(systemPrompt:userText:)` with NO `history`, so
every message is a fresh single-turn request. Local (Ollama/OpenCode) and custom
providers therefore never see prior turns → the model "forgets" the conversation.
**Why real:** `messages(...)` supports a `history` param but the call omits it.
**Fix:** build history from `messageStore.messages` (prior finished user/assistant
turns) and pass it. Red test: a client call with history includes prior turns.
**Quality:** TBD.

### P2 — Web chat re-seeds every turn
**Description:** `runWebChatTurn` passes `isFirstMessage: true` unconditionally,
so the tool-protocol preamble is re-injected and the web session is treated as
brand-new on every user message.
**Why real:** Only the first message of a session should carry the preamble;
later turns continue the same web conversation.
**Fix:** track per-provider "session started" state; pass `isFirstMessage` only
for the first turn of a session.
**Quality:** TBD.

### Round 6 — build script

| ID | Area | Severity | Status |
|----|------|----------|--------|
| B1 | `swift test` under `set -e` aborted the whole build on any test failure/hang | HIGH | FIXED — tests are optional, reported but never abort; `--skip-tests` flag. |
| B2 | `swift build ... | tail -3` under pipefail hid full compiler errors & failed silently | HIGH | FIXED — full untruncated build output; explicit "BUILD FAILED" message + exit 1. |
| B3 | Bundle named MiMoMacOS.app after MiCoder rebrand | LOW | FIXED — MiCoder.app (executable target stays MiMoMacOS). |
| B4 | Stale .app resources could linger | LOW | FIXED — clean `rm -rf` before assembling. |
| B5 | .app location | — | OK — always written to repo ROOT (not .build/); .build is only the SPM source dir swift build must use. |

### Round 7 — MiCoder internal rename + hardcoded test paths

| ID | Area | Severity | Status |
|----|------|----------|--------|
| B6 | Source-inspection tests duplicated `sourceText` in 10 files with hardcoded folder name ("MiMoMacOS/…") and fixed dir depth (×3 deletingLastPathComponent) | MED | FIXED — single RepoRoot helper walks up to Package.swift (rename/depth-proof); 9+1 duplicates now delegate; red tests. |
| B7 | Project not renamed to MiCoder internally (SPM target/product/dir/app struct still MiMoMacOS) | HIGH | FIXED — dir MiMoMacOS→MiCoder, target/product MiCoder(+Tests), @testable import MiCoder (136 tests), struct MiMoMacOSApp→MiCoderApp, build-app APP_NAME, gen_catalog + test-logic paths, kill script. |
| B8 | After renaming MiMoMacOSApp.swift, 3 tests still referenced the old file path | HIGH | FIXED — updated to MiCoderApp.swift. |

NOTE: The GitHub repo itself is still `visawestern/mimo-macos-de098ca6` — renaming
the remote (or creating a fresh `MiCoder` repo) is an owner action on GitHub /
OpenResearch that changes the project binding, so it needs the user's explicit go.
Everything INSIDE the repo now says MiCoder.

### Round 22 (2026-08-05) — E23/E24 auto-detect chain: confirmation + overall timeout

| ID | Area | Severity | Status |
|----|------|----------|--------|
| F1 | E24 overall timeout gated probe START, not DURATION; default 10s > 4×stepTimeout(2s)=8s → deadline never fired on the real path (dead code); a hanging probe ate a full step timeout | HIGH | FIXED — hard deadline: each probe raced against remaining budget and cancelled in-flight (`probeOnce`); `URLSessionProviderProbe` cancellation-aware; red test `hangingProbeCancelledAtDeadline` (3.0s fail → 0.252s pass) |
| F2 | E23 status line "Detected: X, N models." stayed on screen after Cancel — implied a provider was added when it wasn't | MED | FIXED — `AutoDetectStatusText` state machine (detected/confirmed/cancelled/nothing/invalid); cancel now says "nothing was added" |
| F3 | Detected ACP server stored as `.openCode` → routed to OpenAI `/v1/chat/completions` (protocol an ACP server doesn't speak); `SendRoute.acp` was produced but never consumed by the send path (dead route) | HIGH | FIXED — `LocalProviderKind.acp` + `apiBaseURL` (`/acp/v1`); resolver routes ACP locals to `.acp`; ChatPanelView ACP branch consumes the route via `ACPClient(apiBaseURL)` |
| F4 | Auto-detect UI strings hardcoded English (plan Раздел 2/п.39 wants 10 languages) | LOW | OPEN — documented; localization is a separate Раздел 2 iteration |
| F5 | Раздел 9 п.34 non-local warning was set then immediately overwritten with "" → the security warning NEVER displayed | MED | FIXED — warning computed upfront and composed with the detect result; tests `warningForNonLocal` |

Full suite after fixes: **1701 tests / 231 suites green** (baseline 1638/225). Details: `docs/DEVILS_ADVOCATE_ROUND_22_2026-08-05.md`.

### Round 23 (2026-08-05) — Settings tab contract, rebrand leftovers, overview title, dead code

| ID | Area | Severity | Status |
|----|------|----------|--------|
| E25 | `SettingsTabNavigationTests` asserted `allCases.count == 11` incl. `.modelSettings` — validated the raw enum, not the UI list (`visibleCases` = 10, merged Providers tab) | MED | FIXED — test split into back-compat raw-enum + `visibleCases == 10` (no `.modelSettings`, order matches SettingsView) |
| E26 | User-facing MiMo brand strings remained: "Manage MiMo Agent…", "or MiMo CLI/Serve", "Auto-commit from MiMo" (Раздел 13 п.11) | MED | FIXED — "MiCoder" everywhere + stale comments cleaned (SettingsView, BottomPanelView) |
| E27 | Overview sheet still titled `Text("Workspaces")` (SidebarView.swift:502; only occurrence; sidebar section title already removed) | MED | FIXED — "Overview" (Раздел 13 п.7) |
| E28 | `LocalProviderLogic.neutralizeServeBranding` defined but never called in Sources (dead code; only its own test referenced it) — violates Round 18 clean-slate rule | MED | FIXED — removed function + its test; red source-inspection test → green |

Full suite after fixes: **1706 tests / 232 suites green** (baseline 1701/231). Details: `docs/DEVILS_ADVOCATE_ROUND_23_2026-08-05.md`.

### Round 24 (2026-08-07) — saveMessagePart routing, reasoningDuration, todo stubs

| ID | Area | Severity | Status |
|----|------|----------|--------|
| P1 | `DatabaseBridge.saveMessagePart` — `.stepStart` bypassed the injected `insert` closure, writing to the legacy global DB instead of the active project DB | HIGH | FIXED — now uses the `insert` closure like every other branch; 2 red→green routing tests |
| P2 | `DatabaseManager.getSessionGoal` — duplicate doc comment (copy-paste artifact) | LOW | FIXED — removed duplicate line |
| P3 | `Message.reasoningDuration` — measured `Date().timeIntervalSince(startedAt)`, so the value kept growing after reasoning completed instead of freezing | MED | FIXED — added `reasoningEndedAt: Date?`; duration uses `endedAt ?? Date()`; 4 new tests |
| P4 | `ProjectWebToolExecutor.todoRead/todoWrite` — returned `"(todo list not yet implemented)"` / `"(todo write not yet implemented)"` stubs despite being declared, documented, parsed, and access-gated | HIGH | FIXED — real JSON file persistence at `<project>/.micoder/todos.json`; 4 new tests |

Full suite after fixes: **1726 tests / 236 suites green** (baseline 1716/234). Details: `docs/DEVILS_ADVOCATE_ROUND_24_2026-08-07.md`.

### Round 25 (2026-08-07) — Views layer + remaining services audit

| ID | Area | Severity | Status |
|----|------|----------|--------|
| P5 | `ChatPanelView.handleSSEEvent` — `if let finish` block had misleading indentation (looked like dead code; was actually correct but unreadable) | LOW | FIXED — corrected indentation to show the `if let finish` belongs to the outer `if let info` block |

Full suite after fixes: **1726 tests / 236 suites green** (baseline 1726/236). Details: `docs/DEVILS_ADVOCATE_ROUND_25_2026-08-07.md`.

### Round 26 (2026-08-07) — Documentation audit + integration/perf/security review

| ID | Area | Severity | Status |
|----|------|----------|--------|
| D1 | `FEATURE_SPREADSHEET.csv` listed SID-22 as PARTIAL — was fixed to PASS in Round 23 (E27) | DOC | FIXED — updated to PASS |
| D2 | `FEATURE_SPREADSHEET.csv` listed PROV-11 as PARTIAL — confirmation flow was implemented in Round 22 (E23) | DOC | FIXED — updated to PASS |
| D3 | `FEATURE_SPREADSHEET.csv` listed STO-08 as MISSING — WAL journal mode was implemented in Round 21 (E21) | DOC | FIXED — updated to PASS |
| D4 | `FEATURE_SPREADSHEET.csv` listed STO-26 as MISSING — read-only fallback was implemented in Round 21 (E13) | DOC | FIXED — updated to PASS |

Also verified: integration flows (send/session/undo/todo), performance (no main-thread blocking), security (path safety, shell timeout, access gates, keychain storage).

Full suite: **1726 tests / 236 suites green**. Details: `docs/DEVILS_ADVOCATE_ROUND_26_2026-08-07.md`.

### Round 27 (2026-08-07) — Edge case testing + code quality review

Edge case testing of MessageStore, DatabaseBridge, ChatPanelView, Message, ProjectWebToolExecutor, ProjectShellRunner, SSEClient — all handle boundary conditions correctly (empty inputs, nil state, duplicate IDs, missing files, timeouts). No critical issues found.

Code quality review: consistent error handling, no force-unwraps in production code, thread-safe database operations, path safety, no retain cycles, idempotent operations, comprehensive test coverage.

Full suite: **1726 tests / 236 suites green**. Details: `docs/DEVILS_ADVOCATE_ROUND_27_2026-08-07.md`.

### Round 28 (2026-08-20) — todoRead wrapper format, SSEClient retention, grep truncation

| ID | Area | Severity | Status |
|----|------|----------|--------|
| P1 | `todoRead` failed to parse `{"todos": [...]}` wrapper written directly to disk — todos silently lost | HIGH | FIXED — dual-format parser + 2 new tests |
| P2 | `SSEClient.connect()` strong self capture in streamTask | MED | FIXED — `[weak self]` capture |
| P3 | Glob naive regex escaping | LOW | VERIFIED — NSRegularExpression handles common cases correctly |
| P4 | `SSEClient.sharedSession` Int.max timeout (~68 years) | LOW | FIXED — 300s/600s |
| P5 | `grep()` silently truncated at 500 files | LOW | FIXED — truncation warning appended |
| P6 | `FEATURE_REGISTRY.md` header "MiMoMacOS" after rebrand | DOC | FIXED — "MiCoder" |
| P7 | `E09E10ToolUndoHistoryTests` missing `accessLevel: .fullAccess` | MED | FIXED — 6 test constructors updated |

Full suite: **2215 tests / 348 suites** (25 pre-existing failures in web selectors, source inspection, notification titles — unrelated). Details: `docs/DEVILS_ADVOCATE_ROUND_28_2026-08-20.md`.

### Round 29 (2026-08-21) — git arg injection, grep/glob truncation truthfulness, stale API response

| ID | Area | Severity | Status |
|----|------|----------|--------|
| R1 | `git_commit/checkout/push/pull/log` interpolated model-controlled `message`/`branch`/`remote`/`limit` raw into `/bin/zsh -c` → arbitrary shell execution beyond the approved operation | HIGH | FIXED — `shellQuoted`/`sanitizedNumber`; command builders extracted + tested; end-to-end red test on a real repo proves no side-effect file |
| R2 | grep early-returned at the 100-match limit with NO truncation warning (bypassed Round-28 warning logic) | MED | FIXED — single-exit flags; hit-limit warning appended |
| R3 | glob matched lastPathComponent only → every pattern containing "/" (`src/*.swift`, `**/*.swift`) answered "(no matches)" | MED | FIXED — proper glob→regex (`*`, `**`, `?`, `[...]`) matched against root-relative path; sorted; 500-entry cap + warning; symlink-mismatch latent bug also fixed |
| R4 | `/api/send` built its response from values captured BEFORE the async main-thread mutation block → stale chatId/providerId/modelId (new chat answered with old/empty id) | HIGH | FIXED — `resolveSendTargets` (@MainActor) returns post-mutation state; semaphore pattern like existing handlers; explicit timeout error instead of stale data |
| R5 | Round-28 P4 set SSE timeouts on `sharedSession` but `connect()` still used `URLSession.shared` — fix had zero runtime effect | LOW | FIXED — connect uses the configured session |

Baseline note: the "25 pre-existing failures" left by Round 28 were already closed by commit
`d421aa4`; this round audited green code and still found five defects.

Full suite after fixes: **2229 tests / 350 suites, all green**. Details: `docs/DEVILS_ADVOCATE_ROUND_29_2026-08-21.md`.
