# Devil's Advocate Audit — Round 29 (2026-08-21)

## Summary

- **Status**: 5 issues found and fixed, 0 remaining from this round
- **Tests**: 2229 tests / 350 suites — ALL GREEN (baseline 2215/349 was already green)
- **Build**: `swift build` — green
- **Method**: manual chain-of-cause verification from first plan point; every issue confirmed by
  reading source before fixing; TDD red-first for all behavior changes

## Baseline

Round 28 left "25 pre-existing failures" open. Before starting this round they were re-run:
commit `d421aa4` ("resolve all 25 failing tests") had already closed them. Fresh baseline:
2215 tests / 348 suites green. This round therefore audited **green** code — and still found
five real defects, three of them in code "verified" by earlier rounds.

## Problems Found & Fixed

### R1 (HIGH, security) — shell injection through model-controlled git arguments

**File**: `MiCoder/Sources/Services/ProjectWebToolExecutor.swift` (git_* cases)

**Chain-of-cause**: web model emits `git_commit` with `message` → driver validates ONLY
`path` arguments (`WebToolProtocolEmulator.validate`) → executor interpolates raw:
`git commit -m "\(message)"` → `ProjectShellRunner` runs `/bin/zsh -c <command>`.

A message like `x" && touch pwned.marker && echo "` escaped the surrounding quotes and
executed arbitrary shell. Same hole in `branch`, `remote` (`git push/pull`) and `limit`
(`git log -N`). The access gate approves *the operation* (`git_commit`), not arbitrary
commands — this was privilege escalation even at `.fullAccess`.

**Fix**: all interpolated values go through new `shellQuoted(_:)` (single-quote wrapping,
`'` → `'\''`); numeric options through `sanitizedNumber` (digits-only, fallback 10, bounded).
Command construction extracted into testable statics: `gitCommitCommand`, `gitBranchCommand`,
`gitCheckoutCommand`, `gitRemoteRefCommand`, `gitLogCommand`.

**Tests (red→green)**: 6 unit tests on builders + 1 end-to-end integration test that creates a
real temp git repo, sends a malicious `git_commit`, and asserts the side-effect marker file is
NOT created while the literal message reaches git history. Under the old code the marker file
was created (red proven).

### R2 (MED) — grep silently truncated at the 100-match limit

**File**: `MiCoder/Sources/Services/ProjectWebToolExecutor.swift` — `grep(...)`

The inner match loop did `if hits.count >= 100 { return ... }` — an early return that bypassed
the Round-28 truncation-warning logic entirely (that warning only covered the file-count path).
A grep over a 150-match file returned a bare 100-line prefix with no notice.

**Fix**: single-exit restructure with `truncatedFiles` / `truncatedHits` flags; hit-limit now
appends `⚠️ Truncated: showing first 100 matches`. File-limit warning preserved unchanged.

**Test**: `grepHitLimitWarning` — 150 matching lines → result warns and shows ≤100 matches.

### R3 (MED) — glob never matched patterns containing "/"

**File**: `MiCoder/Sources/Services/ProjectWebToolExecutor.swift` — `glob(...)`

The pattern was matched against `lastPathComponent` only, so standard patterns like
`src/*.swift` or `**/*.swift` always answered `(no matches)` — actively lying to the model
about project state. Additionally the naive escaping (Round 28 P3 left it as-is) had no
`**` support and no `/` semantics.

**Fix**: proper glob→regex converter (`globToRegexPattern`): `*` → `[^/]*` (does not cross
`/`), `**` → `.*` (spans directories), `?` → `[^/]`, `[...]` classes pass through with glob
`!` negation translated to `^`, everything else escaped literally. Matched against the path
relative to the scan root; results sorted; capped at 500 entries with an explicit truncation
warning.

**Latent bug surfaced during TDD**: `appendingPathComponent(".")` yields a `/.`-suffixed root,
and on macOS the enumerator returns paths under the resolved symlink target (`/var` →
`/private/var`), so naive prefix stripping dropped EVERY entry. Fixed by resolving both sides
(`standardizedFileURL.resolvingSymlinksInPath()` vs `resolvingSymlinksInPath()` per entry) and
guarding with `hasPrefix(rootPath + "/")`.

**Tests**: nested `src/*.swift`, double-star spanning, bare-star staying at root level,
500-entry cap warning. All Round-28 flat-directory glob tests still pass (semantics for
filename-only patterns are compatible).

### R4 (HIGH) — `/api/send` responded with stale chatId/providerId/modelId

**File**: `MiCoder/Sources/Services/MiCoderAPIServer.swift` — `handleSend`

Commit af0ef4d fixed the SIGSEGV by moving @Published mutations into fire-and-forget
`DispatchQueue.main.async`, but kept building the HTTP response from values captured BEFORE
that block runs. Since the closure executes asynchronously, `handleSend` always answered with
pre-mutation state: for a brand-new chat the response carried `""` or the previously selected
session id instead of the freshly created one. External clients could not know which chat got
the message — the exact contract the endpoint exists to provide.

**Fix**: mutation block extracted into `@MainActor static func resolveSendTargets(...)` which
applies selection, creates/selects the session, reads back state, and RETURNS it.
`handleSend` uses the house pattern already established by `handleRefreshModels`/
`handleEvaluate` (`semaphore` + `Task { @MainActor }`) so the response is built AFTER mutations;
on main-thread stall >30s it returns an explicit timeout error instead of stale data.
Notification posting stays inside the MainActor block after mutations.

**Tests (red→green)**: 3 tests in `MiCoderAPIServerSendResolutionTests` — new chat resolves to
the created session id; existing chatId selects without duplicates; provider selection applied
before readback. Red state = compile error (API did not exist); one initial assertion was
corrected after reading real AppState semantics (`selectModel` rejects unknown models —
documented in the test comment rather than asserted naively).

### R5 (LOW) — Round 28 P4 timeout fix was cosmetic (dead configuration)

**File**: `MiCoder/Sources/Services/SSEClient.swift`

Round 28 set SSE-friendly timeouts (300s/600s) on `sharedSession`, but `connect()` still used
`URLSession.shared` — the configured session was never referenced by live code, so the fix had
zero runtime effect and long-idle streams remained subject to the default 60s request timeout.

**Fix**: `connect()` now uses `Self.sharedSession`. Config-only change completing the Round-28
intent; no behavioral red test possible without network stubbing (noted honestly here instead
of faked).

## Files Changed

| File | Change |
|------|--------|
| `MiCoder/Sources/Services/ProjectWebToolExecutor.swift` | R1 shell-safe git builders; R2 grep hit-limit warning; R3 glob rewrite |
| `MiCoder/Sources/Services/MiCoderAPIServer.swift` | R4 resolveSendTargets + synchronous response |
| `MiCoder/Sources/Services/SSEClient.swift` | R5 connect uses configured session |
| `MiCoder/Tests/DevilsAdvocateRound29Tests.swift` | NEW: 11 tests (R1 unit+integration, R2, R3) |
| `MiCoder/Tests/MiCoderAPIServerSendResolutionTests.swift` | NEW: 3 tests (R4) |

## Verification

```bash
swift build   # green
swift test    # 2229 tests / 350 suites — all green
```

## Re-analysis (devil's advocate on this round's own fixes)

- R1: injection neutralization is proven end-to-end against a REAL zsh+git repo, not just
  string assertions. Remaining honest limitation: `run_command` at `.fullAccess` is by-design
  arbitrary execution — unchanged, documented gate semantics.
- R2/R3: single-exit restructure reviewed against both truncation paths; Round-28 tests kept
  green proves backward compatibility of warnings and filename patterns.
- R4: deadlock risk assessed — semaphore waits happen on NWConnection worker threads; the
  MainActor task is independent, worst case is the explicit 30s timeout response.
- R5: no test added deliberately; recorded as config correction to avoid fake coverage.

## Quality Pass (2026-08-21, same round)

Every fix was re-audited manually chain-by-chain. Scorecard after the pass:

| Item | Claim | Re-verification | Score |
|------|-------|-----------------|-------|
| R1 | no shell injection via git args | execute() wiring read line-by-line (all five mutating verbs use builders; git_status/diff take no model args); real-repo proof extended from git_commit to git_checkout (`b1$(touch …)` → marker absent, literal name reaches git) | 100% |
| R2 | grep never truncates silently | GAP FOUND: >500-file scan with zero matches returned bare `(no matches)`, hiding the truncation. FIXED — warning appended to the empty result | 100% |
| R3 | glob truthful for slash patterns | semantics verified (`*` no cross-`/`, `**` spans, classes pass through, cap+warning); preserved pre-existing semantics documented: directories may match a pattern, `{a,b}` braces are NOT expanded (literal) | 100% |
| R4 | /api/send echoes post-mutation state | all server handlers swept: handleSelect echoes nothing (safe); handleAddAccount touches only disk-backed store; webviews/save-session/inspect already MainActor-synchronized. Accepted trade-off (documented): GET handlers still READ @Published state off-main — blocking them on MainActor would risk API stalls when the UI is busy; the SIGSEGV class was write-driven (objectWillChange→AppKit), reads do not trigger it | 100% |
| R5 | SSE uses configured timeouts | verified connect() is the only bytes() call site | 100% |

New tests this pass: `maliciousCheckoutDoesNotExecuteSideEffects`, `grepFileLimitNoMatchesStillWarns`.

Full suite: **2231 tests / 350 suites — all green**.

## Next Round Candidates

1. `receiveHTTPRequest` reads at most 64KB per request — large POST bodies truncate silently
   (JSON parse error). Consider looping until `isComplete` before routing.
2. `executeTask` sub-agent hardcodes kimi/k2 selectors/config instead of inheriting active
   provider context.
3. `read_file` treats `.svg` (text format) as unreadable image.
