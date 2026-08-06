# MiCoder — Сводный отчёт проекта

Дата: 2026-08-06

## Результат текущего цикла

- Все активити покрыты отдельными Markdown-чеклистами в `docs/activity-checklists/`.
- Каждый пункт содержит действие, триггер, ожидаемое поведение, качество и источник кода.
- Канонический реестр user stories: `docs/FEATURE_SPREADSHEET.csv`.
- Полный тест: `1713 tests / 234 suites — green`.
- Сборка: `swift build — green`.
- Сводка spreadsheet: `168 PASS`, `13 PARTIAL`, `10 MISSING`, `5 FUTURE`.

## Активити

1. `01-sidebar.md` — workspaces, задачи, архив, уведомления, поиск, настройки.
2. `02-chat-panel.md` — ввод, отправка, streaming, attachments, Markdown, tool calls, Plan-вопросы.
3. `03-right-panel.md` — Git, ветки, commit, push/pull, прогресс и Premium-flow.
4. `04-bottom-panel.md` — Terminal и Git tabs, команды, остановка, история, изменения.
5. `05-settings.md` — все 10 видимых вкладок Settings.
6. `06-topbar-taskheader-statusbar-newproject.md` — top bar, task header, status bar, project sheet.
7. `07-app-shell-modals-and-menu.md` — ContentView, macOS commands, overlays, restore and routing.

## Исправлено в текущем цикле

- E13: read-only/system path fallback в `~/.micoder/projects/<stable-hash>/project.db`.
- E21: WAL journaling и честный размер базы с учётом `-wal`/`-shm`.
- E30: удалён скрытый лимит 100 проектов, явные лимиты сохранены.
- E04: on-disk SQLite header validation и read-only integrity probe без schema mutation.
- Test isolation: scoped project eviction вместо глобального `evictAll()`.
- UX: объяснение disabled Plan-agent и точное сообщение о пропущенном push.
- Rebrand: stale user-facing MiMo strings обновлены на MiCoder.

## Остаток по концепту

Оставшиеся `PARTIAL`, `MISSING` и `FUTURE` статусы не скрыты и перечислены в
`FEATURE_SPREADSHEET.csv`. Основные следующие продуктовые блоки: registry/settings export,
chunked delete, skill updates/dependencies, persistent file indexing, usage cost aggregation,
storage localization, interactive captcha bridge и опасные команды.

Интерактивные native macOS проверки Finder, Keychain, drag/resize и реальные remote/GitHub
сценарии отмечены как условные: в текущем окружении нет живого UI-сеанса. Они не выдаются за
кликнутые вручную; логика и unit-тесты проверены отдельно.

## Критерий качества

Нет намеренных заглушек в закрытых user stories. Неполные функции остаются явно отмеченными
`PARTIAL`/`MISSING`/`FUTURE`, а не маскируются статусом PASS. Каждый следующий раунд должен:

```text
/goal → code-based user stories → canonical spreadsheet → real/error testing
→ fix logistics and UX → repeat every behavior → devil's-advocate review
```
