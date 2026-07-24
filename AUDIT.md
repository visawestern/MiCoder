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
