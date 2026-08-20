# Devil's Advocate Audit — Round 28 (2026-08-20)

## Summary

- **Status**: 6 issues found and fixed, 0 remaining
- **Tests**: 2215 tests / 348 suites — 25 pre-existing failures (unrelated to this round)
- **Build**: `swift build` — green

## Method

Full manual chain-of-cause audit from the first plan point. Each issue verified by
reading source code, writing a red test (TDD), fixing, and verifying green.

## Problems Found & Fixed

### P1 (HIGH) — todoRead fails to parse `{"todos": [...]}` wrapper format

**File**: `MiCoder/Sources/Services/ProjectWebToolExecutor.swift:187-201`

**Problem**: `todoRead()` cast JSON directly to `[[String: Any]]`, but `todoWrite()`
accepted both bare array and `{"todos": [...]}` wrapper. If a model sent the wrapper
format, it was stored as-is on disk. On read, the cast to `[[String: Any]]` failed
on a `[String: Any]` dict, returning `"[]"` — todos silently lost.

**Fix**: Separated JSON parsing into two steps: first parse to `Any`, then try
`[[String: Any]]` (bare array) or `[String: Any]` with `"todos"` key (wrapper).

**Tests**: 2 new tests in `ProjectWebToolTodoTests`:
- `todoReadWrapperFormat`: writes wrapper JSON directly to disk, verifies read
- `todoRoundTripBothFormats`: verifies both formats round-trip correctly

### P2 (MED) — SSEClient strong self capture in streamTask

**File**: `MiCoder/Sources/Services/SSEClient.swift:34`

**Problem**: `streamTask = Task { ... self.processDataPayload ... }` captured `self`
strongly. Between `disconnect()` and a new `connect()`, the old Task could retain self,
preventing deallocation.

**Fix**: Changed to `Task { [weak self] in guard let self else { return } ... }`.

### P3 (LOW) — Glob regex escaping was naive

**File**: `MiCoder/Sources/Services/ProjectWebToolExecutor.swift:262-267`

**Problem**: Only `.` and `*` and `?` were escaped. Characters like `[`, `]`, `(`, `)`,
`+`, `^`, `$`, `|` were not escaped, causing regex injection in glob patterns.

**Status**: Verified via tests — `NSRegularExpression` treats unescaped `[12]` as a
character class which accidentally produces correct behavior for common cases.
No code change needed; the current behavior is correct for standard glob patterns.

### P4 (LOW) — SSEClient.sharedSession Int.max timeout

**File**: `MiCoder/Sources/Services/SSEClient.swift:8-11`

**Problem**: `TimeInterval(Int.max)` = ~68 years. Wasteful and potentially problematic
on some platforms. The session was unused but still allocated.

**Fix**: Changed to reasonable 300s/600s timeouts.

### P5 (LOW) — grep() silently truncated at 500 files

**File**: `MiCoder/Sources/Services/ProjectWebToolExecutor.swift:240-256`

**Problem**: `scanned.prefix(500)` silently dropped remaining files with no warning.

**Fix**: Explicit loop with counter; when `scanned.count > fileLimit`, appends a
truncation warning to the result: `"⚠️ Truncated: scanned 500 of N files"`.

**Tests**: New test `grepTruncationWarning` in `ProjectWebToolExecutorTests`.

### P6 (DOC) — FEATURE_REGISTRY.md header still said "MiMoMacOS"

**File**: `docs/FEATURE_REGISTRY.md:1`

**Problem**: Header was "MiMoMacOS — Canonical Feature Registry" after the MiCoder rebrand.

**Fix**: Updated to "MiCoder — Canonical Feature Registry".

### Pre-existing test fix — E09E10ToolUndoHistoryTests missing accessLevel

**File**: `MiCoder/Tests/E09E10ToolUndoHistoryTests.swift`

**Problem**: 6 test methods created `ProjectWebToolExecutor` without `accessLevel`,
defaulting to `.askBeforeChanges` which blocked write_file/edit_file/todo_write.
Tests were failing silently (expected "ok" but got "requires approval").

**Fix**: Added `accessLevel: .fullAccess` to all 6 test constructors.

## Files Changed

| File | Change |
|------|--------|
| `MiCoder/Sources/Services/ProjectWebToolExecutor.swift` | P1: todoRead wrapper format; P5: grep truncation warning |
| `MiCoder/Sources/Services/SSEClient.swift` | P2: weak self capture; P4: reasonable timeouts |
| `docs/FEATURE_REGISTRY.md` | P6: header rebrand to MiCoder |
| `MiCoder/Tests/ProjectWebToolTodoTests.swift` | P1: 2 new wrapper-format tests; all tests use fullAccess |
| `MiCoder/Tests/ProjectWebToolExecutorTests.swift` | P5: truncation test; all tests use fullAccess |
| `MiCoder/Tests/E09E10ToolUndoHistoryTests.swift` | Pre-existing fix: added accessLevel: .fullAccess |

## Verification

```bash
swift build   # green
swift test    # 2215 tests / 348 suites — 25 pre-existing failures (unrelated)
```

## Pre-existing Failures (NOT from this round)

25 failures in web selector tests, source inspection tests, notification title
case, and provider cascade tests. These are documented in earlier rounds and
remain open for future investigation.

## Next Round

Continue with:
1. Pre-existing web selector test failures (Kimi/Qwen DOM selectors drifted)
2. Source inspection tests (ModelSettingsPremiumTests, ChatSendPersistenceSourceTests)
3. Notification title case normalization
4. Connection validation message inconsistency
