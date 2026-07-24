# Devil's Advocate Review — Round 2 (2026-07-17)

Round 1 fixed 39 documentation discrepancies and enumerated 9 code-level debts. Round 2 fixed the user-reported bugs plus the highest-value code debts, all via TDD (red test → implementation → green run).

## Fixed in this round

### 1. User-reported: prompt field on first entry did not autogrow
`CompactChatPromptField` (empty-state input card) forced `compactSingleLine: true`, which rendered a fixed single-line `NSTextField` that truncated input and never grew.
**Fix:** `CompactMessageTextField` now always uses a multiline `ZeroInsetTextField`; `compactSingleLine` only tightens the starting height, growth is allowed up to `textMaxHeight`. Height math extracted into testable `ZeroInsetTextField.clampedHeight`.
**Tests:** `PromptAutogrowTests` (4 tests).

### 2. User-reported: pasting plain text was misrouted as an image attachment
Two root causes in `ClipboardProvider`:
- `consumeByScanningAllItemTypes` probed **every** pasteboard type (including text types) and, when `NSImage(data:)` failed, still fell through to `ClipboardImage(imageData:mimeType:)`;
- `ClipboardImage(imageData:mimeType:"image/png")` blindly base64-encoded **any** bytes as PNG without validating the payload.
**Fix:** the scanner now only probes image-like pasteboard types (`PasteboardAttachmentDetector.looksLikeImageType`), and the PNG path validates the 8-byte PNG signature before accepting data.
**Tests:** `TextPasteRoutingTests` (5 tests, incl. live-pasteboard cases).

### 3. F19 — inline italic in markdown
`MarkdownInline` parsed only bold and code, and emitted parts out of source order (bold always won regardless of position).
**Fix:** parser now picks the **earliest** match among code/bold/italic; italic supports `*x*` and `_x_` with lookaround guards so bold is untouched.
**Tests:** `MarkdownInlineItalicTests` (5 tests).

### 4. F08 — Cmd+N did not focus the message input
`requestInputFocus` existed but nothing consumed it in the empty-state prompt (`ZeroInsetTextField` had no focus plumbing).
**Fix:** `AppState.inputFocusRequest` monotonic counter incremented by `startNewTask`; piped through `CompactChatPromptField` → `CompactMessageTextField` → `ZeroInsetTextField`, which calls `makeFirstResponder`.
**Tests:** `NewTaskFocusTests` (2 tests).

### 5. F55 — dead `GoalPanelView` removed
Zero call sites; `showGoal` opens `RightPanelView` whose Plan section is the actual goal/progress UI. File deleted; regression test scans Sources for any resurrection.
**Tests:** `DeadCodeRemovalTests` (1 test).

### 6. F31 — auto `--set-upstream` on first push
`GitRepository.push` ran bare `git push`, which fails on a branch without upstream.
**Fix:** `hasUpstream(in:)` (via `rev-parse @{upstream}`) + `pushArguments(hasUpstream:branch:)`; push now runs `push --set-upstream origin <branch>` when needed. Verified against a real local bare remote.
**Tests:** `GitPushUpstreamTests` (4 tests).

## Remaining debts (carried to Round 3 candidates)

1. **F44** — ACP protocol client (toggle exists, no client).
2. **F59** — real notification system.
3. **F14** — surface `variantMenuDisabledReason` instead of hiding the menu.
4. **F07/F39** — skill uninstall.
5. **F51** — test coverage for stop/abort flow.
6. **F58** — richer workspace overview.

## Verification

- Full suite: **525 tests in 113 suites — all pass**.
- App bundle builds (`./build-app.sh` → `MiMoMacOS.app`).
- `docs/FEATURE_REGISTRY.md` updated (F08, F19, F31, F55 closed; summary now 57 ✅ / 3 ⚠️).
