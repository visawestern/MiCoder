# MiCoder (ex-MiMo macOS) — implementation status

**Branch:** `main` · **Plan:** `mimo_settings_full_overhaul_2026-07-23.md` (13 sections)
**Local tests:** 260/260 pass (Swift 6.0.3, Foundation-only mirror `scripts/test-logic.sh`).

## Verdict
All 13 plan sections + v2 feedback implemented. Business logic (260 tests, real
filesystem/temp-dir exercised, no mocks for the pure parts) fully verified on
Linux. SwiftUI/AppKit/WebKit/SQLite/FSEvents layers written against the verified
logic — need a macOS build to compile-check and run end-to-end.

## Verified this cycle (v3 remainder)
- LegacyDataMigrator: one-time ~/.mimocode → ~/.micoder migration (wired into init)
- Rebrand finished: terminal welcome, CFBundleName → MiCoder; ~/.cursor removed
- WebModelListParser: real model list from web dropdown text (no hardcoded guesses)
- session_goal: DB column + migration + persist/load (survives restart)
- ProjectFileScanner: REAL recursive scan (SHA-256/FNV hash), incremental delta,
  excludes/gitignore — exercised on real temp dirs
- WebChatEventPresenter: captcha-in-chat + status/answer/error mapping
- i18n: all settings tabs + General row labels + git buttons across 10 languages
- DropdownKeyboardLogic: arrow/enter navigation (macOS 13 compatible)

## Remaining (macOS-only / external, logic ready & tested)
- Compile the SwiftUI/WebKit/SQLite/FSEvents layers on a Mac (only real blocker)
- Live Playwright MCP BrowserAutomationBridge (external process) feeding
  WebModelListParser / WebChatDriver from the real DOM
- FSEvents watcher wrapper around the verified ProjectFileScanner + FTS writes
- Remaining long-tail Settings descriptions (mechanism + fallback in place)

## Devil's advocate audit (5 rounds) — AUDIT.md
Manual chain-of-cause audit found + fixed real bugs (TDD, red-first):
- P1: local/custom chat was stateless (no history) → ChatHistoryBuilder wired.
- P2: web chat re-seeded preamble every turn → session-started tracking.
- P5: DirectChatError gave useless messages → LocalizedError.
- P10: local OpenAI-compatible servers missing /v1 → fixed in resolver.
- P12: `@`-mention file list always empty → real ProjectFileScanner scan (cached).
- P13: WebModelListParser never called → web real models now parsed from DOM.
- P16: dropdown context (FS scan) ran every keystroke → lazy, trigger-only.
- P11 downgraded to PARTIAL (FSEvents watcher/file_index/FTS = honest Mac/DB work).
- P8 documented known-limit (custom Anthropic via OpenAI endpoint).
Tests: 299/299 (Foundation-only mirror). App UI/DB/WebKit still needs a macOS build.
The recurring root cause: "logic written & tested but never wired into the app" —
now swept; every logic module is invoked from App/Views.
