# Activity 09 — Settings (All 10 Tabs)

Источники: `Sources/Views/SettingsView.swift`, `Sources/Views/Settings/*.swift`

## Settings Tabs

| # | Tab | Controls | Status |
|---|---|---|---|
| 1 | General | Theme (Dark/Light), Language picker, Zoom (Smaller/Default/Larger), Terminal inherit profile, Terminal font, HTTP proxy, Input dropdown toggle, Code preview (line numbers, wrap, font size, light/dark themes) | PASS |
| 2 | Providers | Auto Free section (status, model selector, lock/unlock, system prompt, refresh), Local providers (auto-detect, quick-add, remove, toggle, model chip), Custom providers (search, add, remove), Web providers (Kimi/Qwen/ChatGPT/custom, detect models, cookie capture) | PARTIAL |
| 3 | Skills | Library of installable skills, installed skills management (enable/disable/remove/update) | PARTIAL |
| 4 | MCP Servers | Library of MCP servers, health checks, install/uninstall, enable/disable | PARTIAL |
| 5 | Plugins | Plugin enable/disable, search | PASS |
| 6 | Commands | Built-in + custom commands, CRUD, template injection | PASS |
| 7 | Indexing | Auto-index folders/repos, manual indexing controls | PARTIAL |
| 8 | Storage | Projects admin, export/import config, archive/delete/VACUUM, backup, orphaned relink, quota warning, auto-archive, storage stats | PARTIAL |
| 9 | Usage | Time range filter, total tokens/cost/messages/active days, database size, favorite model, per-model breakdown | PARTIAL |
| 10 | Code Preview | Light/dark code themes, line numbers, wrap, font size | PASS |

## User Story

As a user, I can configure all aspects of MiCoder through 10 settings tabs: general preferences, provider connections, agent skills, MCP servers, plugins, custom commands, file indexing, storage management, usage statistics, and code preview.
