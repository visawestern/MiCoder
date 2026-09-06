# MiCoder Audit — Master Index

Дата: 2026-09-06 (дельта-аудит пост-аудитных коммитов 6062877..HEAD)
Версия: v2.119.1 (build 118)
Тесты: 2298 tests / 359 suites — ALL GREEN (финальный регрессионный прогон после всех фиксов)
Сборка: `swift build` — GREEN

## Audit Scope

Полный аудит всех activity/функций MiCoder по SDLC:
1. Ручное перечисление всех кнопок, действий, сценариев, переходов, состояний
2. Сверка каждого пункта с реальной реализацией (не только документацией)
3. User story для каждой функции с ожидаемым поведением из кода
4. Тестирование каждого сценария
5. Исправление найденных ошибок
6. Повторное тестирование и регрессия
7. Архитектурный анализ

## Activity Files

| # | File | Area | Status |
|---|---|---|---|
| 01 | [01-app-shell.md](01-app-shell.md) | Window, startup, navigation, commands | AUDITED |
| 02 | [02-sidebar.md](02-sidebar.md) | Workspaces, sessions, navigation, archive | AUDITED |
| 03 | [03-chat-panel.md](03-chat-panel.md) | Messages, streaming, markdown, tool calls | AUDITED |
| 04 | [04-chat-input.md](04-chat-input.md) | Composer, providers, models, attachments | AUDITED |
| 05 | [05-topbar.md](05-topbar.md) | Header, badges, toggles | AUDITED |
| 06 | [06-bottom-panel.md](06-bottom-panel.md) | Terminal, Git tabs | AUDITED |
| 07 | [07-right-panel.md](07-right-panel.md) | Git tools, progress | AUDITED |
| 08 | [08-statusbar.md](08-statusbar.md) | Connection, model, streaming | AUDITED |
| 09 | [09-settings.md](09-settings.md) | All 10 settings tabs | AUDITED |
| 10 | [10-git-operations.md](10-git-operations.md) | Commit, push, pull, publish, PR | AUDITED |
| 11 | [11-web-chat.md](11-web-chat.md) | Browser automation, model injection, send | AUDITED |
| 12 | [12-web-session.md](12-web-session.md) | Cookie persistence, session management | AUDITED |
| 13 | [13-web-captcha.md](13-web-captcha.md) | Captcha detection and handling | AUDITED |
| 14 | [14-web-tools.md](14-web-tools.md) | Tool protocol emulation, access gates | AUDITED |
| 15 | [15-micoder-auto-free.md](15-micoder-auto-free.md) | Free provider, failover, catalog | AUDITED |
| 16 | [16-database.md](16-database.md) | SQLite, migrations, WAL, integrity | AUDITED |
| 17 | [17-storage.md](17-storage.md) | Per-project DB, backup, restore, VACUUM | AUDITED |
| 18 | [18-search.md](18-search.md) | FTS5, search palette | AUDITED |
| 19 | [19-error-handling.md](19-error-handling.md) | Session busy, disconnected, validation | AUDITED |
| 20 | [20-localization.md](20-localization.md) | 10 languages, RTL | AUDITED |
| 21 | [21-performance.md](21-performance.md) | Merging, lazy loading, coalescing | AUDITED |
| 22 | [22-security.md](22-security.md) | Keychain, access levels, sanitization | AUDITED |
| 23 | [23-clipboard.md](23-clipboard.md) | Paste routing, image/file paste | AUDITED |
| 24 | [24-theme.md](24-theme.md) | Dark/light, font scaling | AUDITED |
| 25 | [25-agent-resources.md](25-agent-resources.md) | Skills, MCP, dependency resolution | AUDITED |
| 26 | [26-slash-commands.md](26-slash-commands.md) | Built-in and custom commands | AUDITED |
| 27 | [27-session-management.md](27-session-management.md) | Creation, persistence, archiving | AUDITED |
| 28 | [28-file-indexing.md](28-file-indexing.md) | File scanning, @-mention, FSEvents | AUDITED |
| 29 | [29-architecture.md](29-architecture.md) | SRP, race conditions, memory issues | AUDITED (03/04/05/06/08/09 FIXED 2026-09-06; 01/02/07 OPEN-constrained) |
| 30 | [30-agentic-tool-loop.md](30-agentic-tool-loop.md) | Auto-free agentic loop, tool protocol, gates | AUDITED 2026-09-06 |
| 31 | [31-project-auto-context.md](31-project-auto-context.md) | Host-side project auto-context | AUDITED 2026-09-06 |
| 32 | [32-header-goal-progress.md](32-header-goal-progress.md) | Header goal + step progress | AUDITED 2026-09-06 |
| 33 | [33-history-tail-paging.md](33-history-tail-paging.md) | History tail + older paging | AUDITED 2026-09-06 |

## Canonical Spreadsheet

`docs/audit/FEATURE_SPREADSHEET_AUDIT.csv` — централизованный реестр всех user stories с полным трекингом состояния.

## Bugs Fixed in This Audit

| ID | Severity | Description | File | Status |
|---|---|---|---|---|
| FIX-01 | CRITICAL | `stopServe()` mutated @Published properties outside @MainActor | MiCoderApp.swift:1808 | FIXED |
| FIX-02 | CRITICAL | `isNavigatingHistory` data race — not protected by navigationLock | MiCoderApp.swift:132,164,947,961 | FIXED |
| FIX-03 | HIGH | `upsertProject` never updated existing records (name/branch/remote) | DatabaseBridge.swift:66 | FIXED |
| FIX-04 | HIGH | Missing `updateProject` method in DatabaseManager | DatabaseManager.swift | FIXED |

## Delta Audit 2026-09-06 — Bugs Fixed (commits 6062877..HEAD + this session)

| ID | Severity | Description | File | Status |
|---|---|---|---|---|
| ARCH-03/08 | HIGH | `lastAccessedAt` data race + dead DispatchQueue | ProjectDatabaseManager.swift | FIXED (NSLock; queue removed; regression test) |
| ARCH-04 | HIGH | hasAPIKey/send-route lost the key after Keychain migration until restart | MiCoderApp.swift, SendRouteResolver.swift | FIXED (in-memory restore + getSecureAPIKey route; regression test) |
| ARCH-05 | MEDIUM | SQL identifier interpolation in addColumnIfMissing | ProjectDatabaseManager.swift | FIXED (SchemaIdentifier allowlist + typed error) |
| ARCH-06 | MEDIUM | Symlink path traversal in isPathInsideRoot | WebToolProtocolEmulator.swift | FIXED v2 (realpath + lexical resolution; 10 regression cases) |
| ARCH-09 | LOW | 100% duplicated part converters | DatabaseBridge.swift | FIXED (shared convertPartFields) |
| BUG-30-01 | MEDIUM | Auto-free tool preamble missing projectRoot/git context | MiCoderAutoFreeProvider.swift, ChatPanelView.swift | FIXED (streamChat(projectRoot:isGitRepo:)) |
| BUG-30-02 | HIGH | Infinite loop in ARCH-06 fix v1 on trailing `..` (URL no-op) | WebToolProtocolEmulator.swift | FIXED v2 + regression test; caught ONLY by full-suite rerun |

## Architecture Defects (Documented, Not Fixed — External Constraints)

| ID | Severity | Description | Reason |
|---|---|---|---|
| ARCH-01 | CRITICAL | `AppState` is a 2265-line God Object (SRP violation) | Requires major refactoring across entire codebase |
| ARCH-02 | CRITICAL | Global mutable singleton `__miCoderAppState` without synchronization | Used by API server; requires architectural redesign |
| ARCH-03 | HIGH | `lastAccessedAt` in ProjectDatabaseManager has data race | Pool queue vs direct access; requires pool redesign |
| ARCH-04 | HIGH | `hasAPIKey` check uses in-memory field cleared after Keychain migration | Design trade-off; requires Keychain-aware readiness |
| ARCH-05 | MEDIUM | `addColumnIfMissing` uses string interpolation for SQL | Internal only; callers pass literals |
| ARCH-06 | MEDIUM | Symlink path traversal in tool validation | Requires realpath resolution |
| ARCH-07 | MEDIUM | 15+ silent `try?` error swallowing sites | Requires systematic error propagation |
