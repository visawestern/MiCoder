# Devil's Advocate — Round 7 (Meta-Audit of the Audits)

**Date:** 2026-07-24
**Method:** Manual chain-of-cause verification of EVERY prior document (concept, plan,
changelog, quality reports, 6 devil's-advocate rounds) against the ACTUAL code, with
ripgrep-backed counts. Unlike rounds 1–6 (which were self-reported on a box that could
not compile the project), this round establishes **ground truth** and treats every
prior "✅ FIXED / 10/10" as a claim to be refuted until proven.

**Auditor stance:** the previous rounds' recurring self-diagnosis — *"logic written &
tested but never wired"* — is treated as a hypothesis that may still be true, plus a
new hypothesis: *"the audit documents themselves are unreliable."*

---

## 0. Executive verdict

The code is in **much better shape than the documents' internal contradictions suggest**,
but the **documentation and test-count claims are not trustworthy**, and there remains a
concrete cluster of **unwired ("orphan") modules** the docs claim to have eliminated.

Two classes of problem:

* **Class A — Documentation integrity.** Test/suite counts are mutually contradictory
  across every document and none match the code. Several "✅ FIXED" statuses are
  contradicted by same-day sibling documents or by the code itself.
* **Class B — Real code defects.** A per-project database/undo/history cluster is fully
  tested but never wired; the runnable Linux test mirror points at a non-existent repo
  path and covers only ~23% of the suite; ~30 tests assert nothing; a stale `.cursor/`
  directory contradicts the "rebrand complete" claim.

---

## 0b. GROUND TRUTH — real macOS build + test run (decisive)

A full `./build-app.sh` was run on a real Mac (Swift 6, x86_64-apple-macos). This is
the reproducible number every prior doc lacked. Results:

* **Build: SUCCEEDED.**
* **Test run: 1568 tests in 216 suites** — **exactly** the ripgrep counts below,
  and **contradicting every one of the 8 documented numbers** (152/671/679/613/260/299/1241/1247).
* **5 tests FAILED** — none of which any of the six prior "ALL PASSED ✅" audits caught.
  This is the sharpest devil's-advocate result of the round: the "all green" claims
  were never true against a real run.

| # | Failing test | File:line | Root cause | Fix (Round 7) |
|---|---|---|---|---|
| RT-1 | "Input placeholder matches MiMo spec" | `Screenshot1Tests.swift:28` | Stale MiMo branding assertion not updated during the MiCoder rebrand | assert `"Ask MiCoder anything"` |
| RT-2 | "Prompt placeholder uses MiMo branding" | `MiMoCopyTests.swift:9` | same stale-brand assertion | assert `"Ask MiCoder anything"` + negative-assert `"Ask MiMo"` |
| RT-3 | "Prompt placeholder switches with language" | `AppLocalizationTests.swift:20` | same | assert `en.contains("Ask MiCoder")` |
| RT-4 | `recordsHaveHashSizeLanguage()` | `ProjectFileScannerTests.swift:43` | `#expect(!(rec?.hash ?? "").isEmpty)` mis-expands to an unused `Bool?` (compiler warned) — the negation is never evaluated, so a valid hash "fails" | `#require` the record, bind `hash` to a plain `String`, assert `hash.isEmpty == false` |
| RT-5 | "Idle connections are evicted…" | `ProjectDatabaseManagerTests.swift:180` | `ChatSession.normalizedPath` used `standardizingPath`, which is **not idempotent** for the `/var`→`/private/var` tmp symlink; the pool key and `isPooled`'s re-normalization disagreed | make `normalizedPath` resolve symlinks (`resolvingSymlinksInPath`) so it is deterministic & idempotent |

RT-5 is a genuine product bug, not just a test bug: the same project reached via
`/var/…` vs `/private/var/…` (or any symlinked path) would have been pooled under
two different keys, leaking/duplicating per-project DB connections.

The rebrand-stale tests (RT-1..3) also confirm R7-05's theme: prior rounds changed
product strings but never ran the suite, so the stale assertions sat undetected.

## 0c. MiMo decoupling — no local CLI, HTTP-only (user directive)

The app is now **fully decoupled from MiMo and from any local CLI**. It never
spawns `mimo`, `ollama`, or `opencode`, and never launches `mimo serve`. A local
provider is reached **only** over HTTP at a `host:port` the user has already
started themselves. Changes:

| Area | Before | After (Round 7) |
|---|---|---|
| `MimoCLISessionLoader` (+ `MimoCLISessionEntry`, tests) | shelled out to `mimo session list` / `mimo export`, searched `/usr/local/bin/mimo`, `/opt/homebrew/bin/mimo`, `~/.micoder/bin/mimo` | **deleted** |
| `MiCoderApp.loadSessionsFromServer()` | loaded global sessions via the CLI, then merged | local DB + optional HTTP server sync only |
| `ChatPanelView` message load | CLI `loadMessages` fallback | local DB fallback (`DatabaseBridge`) |
| `LocalProviderConfig` | `.cli` mode, `executablePath`, `defaultExecutablePath` (`/usr/local/bin/ollama`, `/usr/local/bin/opencode`), `autoStart`, `workingDirectory`, `supportsCLIMode` | serve-only: `kind` + `host` + `port` + `models`; no exec paths, no CLI mode |
| `LocalProviderKind.mimoCLI` | branded "MiMo CLI" | renamed `.localAgent` ("Local Agent") |
| Provider connection | (unchanged) `MimoServeConnectionManager` only **connects**, never spawns; `ProviderAutoDetector` only HTTP-probes via `URLSession` | verified — no process launch anywhere for providers |

Only legitimate local `Process()` uses remain: **git** (`GitRepository`,
`GitHubCLIService`, `GitPublishFlowLogic`) and the **integrated terminal**
(`BottomPanelView`) — these are user-facing git/terminal features, not MiMo.

Everything runs on Intel (x86_64) exactly as on Apple Silicon — none of the
Round-7 changes are architecture-specific.

## 1. Ground-truth measurements (ripgrep, this round)

| Measurement | Value | How |
|---|---|---|
| Test files | **138** `.swift` in `MiCoder/Tests/` | glob |
| `@Test` declarations | **1568** | `rg -o '@Test\b' \| wc -l` |
| `@Suite` declarations | **216** | `rg -o '@Suite\b' \| wc -l` |
| Service source files | **107** in `MiCoder/Sources/Services/` | ls |
| Files importing AppKit/SwiftUI (macOS-only, cannot run on Linux) | **17** | rg |
| Foundation-only test files (could run on Linux) | **121** | rg |
| Test files wired into `scripts/test-logic.sh` mirror | **32** (30 real + 2 helpers) | script `TESTS=()` |
| Foundation-only tests runnable but NOT in the mirror | **89** | derived |

### Every documented test count vs. reality — ALL WRONG

| Document | Claimed count | Matches 1568/216? |
|---|---|---|
| `PLAN.md` | 152 / 34 suites | ❌ |
| `docs/135_POINT_VERIFICATION_REPORT.md` | 671 / 131 | ❌ |
| `docs/QUALITY_REPORT_2026-07-21.md` (header) | 679 / 132 | ❌ |
| `docs/QUALITY_REPORT_2026-07-21.md` (footer) | 613 / 123 | ❌ (self-contradicts its own header) |
| `docs/DATA_STORAGE_PROGRESS.md` | 565 / 122 | ❌ |
| `.openresearch/STATUS.md` | 260 / 260 | ❌ |
| `AUDIT.md` | 299 / 299 (also "260/280") | ❌ |
| `docs/FEATURE_REGISTRY.md` | 1241 / 178 | ❌ |
| `docs/devils_advocate_round_6` | 1241 → 1247 / 178 | ❌ |

None reconcile, and the Round-4 "growth table" (607→671→679→769) matches **none** of the
individual round docs' own stated numbers. Root cause: numbers were **hand-typed on a
Linux box that never compiled or ran the macOS suite** — there was no reproducible run to
count from.

---

## 2. PROBLEM CHECKLIST

Severity: 🔴 high · 🟡 medium · 🟢 low. "Fix quality" is graded only once resolved.

| ID | Severity | Area | Status |
|----|----------|------|--------|
| R7-01 | 🔴 | Test/suite counts in every doc are contradictory & none match code | OPEN → fix docs + add ground-truth harness |
| R7-02 | 🔴 | No reproducible test run exists; "all pass" is unverifiable | OPEN → make Foundation mirror the canonical, runnable harness (EVAL.md) |
| R7-03 | 🔴 | `scripts/test-logic.sh` REPO path points at non-existent `mimo-macos-de098ca6` → all symlinks broken, mirror cannot run | OPEN |
| R7-04 | 🟡 | Mirror wires only 32/138 test files; 89 Foundation-only files runnable but excluded | OPEN |
| R7-05 | 🔴 | Orphan cluster: `ProjectUndoManager`, `ProjectSnapshotManager`, `ProjectHistoryExporter`, `ProjectDatabaseMigrator` tested but never wired | OPEN |
| R7-06 | 🟡 | Cmd+Option+Z wired to LEGACY `UndoRedoManager.shared`; the newer per-project undo stack is dead | OPEN |
| R7-07 | 🟡 | `ChatPasteRoutingLogic` orphan yet `FEATURE_SPREADSHEET.csv:106` marks it "✅ PASS" | OPEN |
| R7-08 | 🟢 | Orphans `GitignoreEntryLogic`, `InputFieldHeightLogic`, `DirectChatClient.messages(...)` | OPEN |
| R7-09 | 🟡 | 3 empty-body tests (t03/t07/t10) + ~27 assertion-free tests inflate the count | OPEN |
| R7-10 | 🟢 | `Full135ChecklistVerificationTests.swift` is ~⅓ non-asserting theater; Round 6 only deleted its `.bak`, the real file remains | OPEN |
| R7-11 | 🟡 | ~19 "source-inspection" tests (grep a `.swift` for a string) across 14 files are blind to behavioral regressions; pattern institutionalised in `RepoRoot.sourceText` | OPEN (document as lint, not test) |
| R7-12 | 🟡 | `.cursor/` dir still in repo root (`.cursor/plans/mimo_settings_overhaul_*.plan.md`) despite AUDIT/STATUS "~/.cursor removed" | OPEN |
| R7-13 | 🟢 | UI_AUDIT_REPORT body still shows all 19 bugs as ❌ while its summary claims 19/19 fixed — doc self-contradictory | OPEN |
| R7-14 | 🟢 | `docs/QUALITY_REPORT.md` referenced by Round 6 but the real file is `QUALITY_REPORT_2026-07-21.md` (dangling reference) | OPEN |
| R7-15 | 🟢 | Round-3 LOW item "L6 Undo ⌘Z" silently dropped from later tallies without resolution record | OPEN (superseded by R7-06) |
| R7-16 | 🟢 | `DirectChatError` / P1 doc names wrong method (`DirectChatClient.messages`); real path is `ChatHistoryBuilder.messages` → `DirectChatClient.send` | OPEN (doc fix) |

### Confirmed-GOOD (previous claims that DID verify against code — no action)

* P1 history carrying — **WIRED** (`ChatPanelView.swift:488-499` via `ChatHistoryBuilder`).
* P12/P16 `@`-mention lazy scan — **WIRED & lazy** (`InputCommandDropdownView.swift:22-25`, cache-gated).
* P13 `WebModelListParser` — **WIRED** (best-effort, WebKit-only, `ChatPanelView.swift:798-803`).
* F59 `taskCompleted()` — **WIRED** (two call sites: `ChatPanelView.swift:644` serve, `:553` ACP).
* F44 ACP send path — **WIRED** (`MiCoderApp.swift:517-533`, `ChatPanelView.swift:522-535`).
* Internal rebrand to MiCoder — **DONE** (0 `MiMoMacOS` identifiers; `MiCoderApp.swift` exists).
* Keychain-first API key read/write — **PRESENT** (`SettingsView.swift:528,536`), so R3-C4 is resolved in code (but was contradicted by same-day DATA_STORAGE claiming 10/10 before the fix).

---

## 3. Per-problem detail + best-fix

### R7-01 / R7-02 / R7-03 / R7-04 — the harness is the root cause 🔴
**Why real:** every downstream count and "all pass" claim traces back to the absence of a
single reproducible run. The one script that *executes* anything (`scripts/test-logic.sh`)
is broken (R7-03: `REPO=…/mimo-macos-de098ca6` does not exist → 74 broken symlinks) and,
even repaired, covers only 32/138 files (R7-04).
**Best fix (TDD-compatible):**
1. Repair `test-logic.sh` to point at the real clone and auto-discover Foundation-only
   test files rather than a hand-maintained whitelist.
2. Emit a machine-countable summary (`EVAL.md`) with the exact executed `@Test`/pass/fail
   numbers, so docs can cite a *reproduced* number, never a hand-typed one.
3. Every future doc quotes the harness output, not a guess.
**Fix quality:** TBD.

### R7-05 / R7-06 — per-project undo/history cluster is dead 🔴🟡
**Why real:** `ProjectUndoManager`, `ProjectSnapshotManager`, `ProjectHistoryExporter`,
`ProjectDatabaseMigrator` have full test coverage but ZERO live call sites; the actual
Cmd+Option+Z menu uses the older global `UndoRedoManager.shared`. This is exactly the
"tested but never wired" root cause rounds 3–6 claimed to have swept.
**Best fix:** either (a) wire the per-project cluster into the App/menu and DB init and
retire the legacy manager, or (b) if the legacy path is intentionally canonical, delete
the dead cluster and its tests. Decision needed; document explicitly. Red test first:
assert the wired manager is the one the menu action invokes.
**Fix quality:** TBD.

### R7-07 / R7-08 — smaller orphans 🟡🟢
`ChatPasteRoutingLogic` (live path uses `PasteRoutingDecision`), `GitignoreEntryLogic`,
`InputFieldHeightLogic`, `DirectChatClient.messages(...)`. **Best fix:** wire or delete;
in all cases correct the registry/spreadsheet status (R7-07's "✅ PASS" is false).

### R7-09 / R7-10 / R7-11 — test theater 🟡🟢
Empty bodies (t03/t07/t10 assert nothing), ~27 assertion-free tests, ~19 source-grep
tests. **Best fix:** give the empty "absence" checks real assertions (grep-for-absence
is legitimate as a lint — make it assert), and stop counting non-asserting bodies toward
"tests passed." Keep source-inspection tests but label them lints, not behavioral tests.

### R7-12 — stale `.cursor/` 🟡
**Best fix:** remove `.cursor/` from the repo (or explicitly document why it stays) and
correct AUDIT/STATUS which claim it was removed.

### R7-13 / R7-14 / R7-15 / R7-16 — documentation integrity 🟢
Reconcile UI_AUDIT body vs summary; fix the dangling `QUALITY_REPORT.md` reference;
record L6's supersession by R7-06; correct P1's method name.

---

## 4. Fix plan (rounds, TDD red-first)

* **R7.a (harness):** R7-03, R7-01, R7-02, R7-04 — make the mirror real & self-discovering,
  produce EVAL.md with ground-truth counts. This is the prerequisite: without a runnable
  harness, red/green tests are meaningless.
* **R7.b (orphans):** R7-05, R7-06, R7-07, R7-08 — red test proving the orphan is unwired,
  then wire or delete, green.
* **R7.c (test integrity):** R7-09, R7-10, R7-11 — convert non-asserting/empty tests to
  real assertions; drop theater from the count.
* **R7.d (doc/hygiene):** R7-12..R7-16 — remove stale `.cursor/`, reconcile every doc's
  numbers to the harness output, fix dangling references.

Each round: red tests → fix → green → re-run harness → update this file + affected docs →
commit + push → re-analyze as devil's advocate. Repeat until the checklist is clear and
the harness output matches the documented numbers exactly.
