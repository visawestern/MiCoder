# Devil's Advocate Review — Round 1 (2026-07-17)

Full-chain audit of the project and every document (`docs/FEATURE_REGISTRY.md`, `PLAN.md`, `docs/ZCODE_PARITY_IMPLEMENTATION_PLAN.md`, `docs/mimo_zcode_parity_2026-06-20.md`, `plans/1.md`, `plans/1_parity.md`, `docs/provider_cascade_api_probe.md`, `docs/clipboard_paste_verification.md`) against the current codebase. Two independent auditors verified F1–F25 and F26–F60 + all other docs, feature by feature.

## Scope and method

- Every registry feature (F1–F60) checked against actual source, tests, and UI wiring.
- Every claim in the other docs (test counts, gaps, compile status, mock claims) verified against code.
- Verified counts: **100** source files, **489** `@Test` declarations (~502 executed with parameterization), **107** `@Suite` declarations.

## Findings: 39 discrepancies total

### A. FEATURE_REGISTRY.md (24 findings — all fixed in this round)

| # | Feature | Problem | Resolution |
|---|---------|---------|------------|
| 1 | Header | Stale metrics (88 files / 460 tests / 102 suites) | Updated to 100 / 489 / 107 |
| 2 | F04 | "Hover actions not implemented" — they are | Gap cleared |
| 3 | F06 | "UI partially wired" — Cmd+K fully opens SearchPaletteView | Status fixed |
| 4 | F07 | Claimed uninstall support — installer has install-only API | Gap documented |
| 5 | F08 | Claimed input focus on Cmd+N — `requestInputFocus` never consumed | Gap documented |
| 6 | F09 | Cited non-existent "EmptyChatStateView" tests | Corrected to InputBarPositionParityTests |
| 7 | F14 | Claimed disabled-with-reason UI — menu is hidden instead | Gap documented |
| 8 | F15 | Menu items misdescribed ($skill vs actual # session) | Corrected to actual 5 items |
| 9 | F19 | Claimed italic support — MarkdownInline parses bold+code only | Gap documented |
| 10 | F22 | Claimed in-chat step headers — helpers unused; progress in right panel | Corrected |
| 11 | F23 | Claimed collapse for code blocks — thinking blocks only | Corrected |
| 12 | F24 | "Copy on hover" — copy lives in the action bar | Corrected |
| 13 | F26 | Cited non-existent MessageHistoryPaginationLogic suite | Corrected to MessageStoreTests |
| 14 | F34 | Cited ParityTests — coverage is in Screenshot12Tests/ZCodeFeatureTests | Corrected |
| 15 | F38/F44 | F38 implied ACP protocol implemented; F44 says toggle-only | Wording aligned |
| 16 | F40 | "Read-only, no add UI" — AgentResourceLibraryView installs MCP servers | Corrected |
| 17 | F51 | Cited MessageFlowTests — no abort-flow coverage exists | Gap documented |
| 18 | F53 | "Tests: None" — a "Status Bar" suite exists (string helpers) | Corrected |
| 19 | F54 | Claimed files/git/settings header toggles — only terminal/goal/sidebar | Corrected |
| 20 | F55 | "UI exists" — GoalPanelView has zero call sites (dead code) | Marked as not wired |
| 21 | F58 | "Overview not accessible" — sidebar opens it | Corrected |
| 22 | F60 | Claimed click-for-profile — avatar/name non-interactive | Corrected |
| 23 | Summary | 44+8 ≠ 60 | Fixed: 56 ✅ / 4 ⚠️ (F44, F55, F58, F59) |
| 24 | Priorities | Listed already-done items (F01 409-retry, F33 private repos, F35 terminal input) | Replaced with real candidates |

### B. Other documents (15 findings — all fixed in this round)

| # | Document | Problem | Resolution |
|---|----------|---------|------------|
| 25 | PLAN.md | "152 tests / 34 suites" | Historical note + current counts |
| 26 | PLAN.md | Claimed 3-item Plus menu, `insertCommand` removed — code has 5 incl. it | Correction in note |
| 27 | PLAN.md | Claimed "Z watermark" — actual MiMoLogoMark / "mi" | Correction in note |
| 28 | ZCODE_PARITY_IMPLEMENTATION_PLAN.md | "App does not compile" ([weak self]) — long fixed | Historical banner |
| 29 | ZCODE_PARITY_IMPLEMENTATION_PLAN.md | Stale gaps (remote connection, open folder, session filter, search/skills, hardcoded progress) | Historical banner |
| 30 | mimo_zcode_parity_2026-06-20.md | "206 tests" | Historical banner |
| 31 | mimo_zcode_parity_2026-06-20.md | "Git actions no-op" — real commit/checkout/push implemented | Historical banner |
| 32 | mimo_zcode_parity_2026-06-20.md | "Terminal is mock" — real /bin/zsh via Process | Historical banner |
| 33 | plans/1_parity.md | "FULL PARITY 45/45" — F44/F55/F58/F59 partial | Correction banner |
| 34 | plans/1_parity.md | Claimed `Text("Z")` watermark | Correction banner |
| 35 | plans/1_parity.md | Claimed hardcoded username "Win Pei" — NSFullUserName() | Correction banner |
| 36 | plans/1_parity.md | Claimed 4 access levels — 3 (Plan is agent mode) | Correction banner |
| 37 | plans/1_parity.md | "81 tests" | Correction banner |
| 38 | project-review/ | Referenced 1.md / 1_parity.md missing (live in plans/) | Noted here; files not moved |
| 39 | OpenModel | Presets/ads — removed this round (see F38, OpenModelAdRemovalTests) | Verified: 0 promo strings in Sources |

## Code-level issues carried to Round 2 (require TDD fixes, not doc edits)

1. **F55** — `GoalPanelView` is dead code: wire it or remove it.
2. **F19** — inline italic not parsed in markdown.
3. **F08** — `requestInputFocus` flag is set but never consumed → Cmd+N does not focus the input.
4. **F14** — `variantMenuDisabledReason` computed but never shown.
5. **F51** — no test coverage of the stop/abort flow.
6. **F07/F39** — no skill uninstall.
7. **F31** — no auto `--set-upstream` on first push of a new branch.
8. **User-reported (2026-07-17):** empty-state (first entry) message input does not autogrow — behaves as a fixed single-line field.
9. **User-reported (2026-07-17):** pasting plain text is misrouted as an image attachment.

## Round 1 verdict

Documentation is now consistent with the code (all 39 discrepancies addressed: registry rewritten in place, historical docs banner-corrected without rewriting history). Code-level debt is explicitly enumerated for Round 2.
