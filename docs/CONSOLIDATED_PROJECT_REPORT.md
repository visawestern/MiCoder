# MiCoder — Сводный отчёт проекта

Дата: 2026-08-21

## Результат текущего цикла

- Все активити покрыты отдельными Markdown-чеклистами в `docs/activity-checklists/`.
- Каждый пункт содержит действие, триггер, ожидаемое поведение, качество и источник кода.
- Канонический реестр user stories: `docs/FEATURE_SPREADSHEET.csv`.
- Полный тест: `2229 tests / 350 suites` — все зелёные (25 падений из Round 28 закрыты коммитом d421aa4 до начала Round 29).
- Сборка: `swift build — green`.
- Сводка spreadsheet: `172 PASS`, `11 PARTIAL`, `8 MISSING`, `5 FUTURE`.

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
- **P1**: `DatabaseBridge.saveMessagePart` — `.stepStart` теперь использует `insert` closure (данные пишутся в project DB, а не в legacy global).
- **P3**: `Message.reasoningDuration` — добавлен `reasoningEndedAt`, значение замораживается после завершения reasoning.
- **P4**: `ProjectWebToolExecutor.todoRead/todoWrite` — реализована полноценная persistence в `<project>/.micoder/todos.json` (было: stub-заглушки).

## Раунд 28 (2026-08-20)

- **P1 (HIGH)**: `todoRead` теперь обрабатывает оба формата JSON (bare array и `{"todos": [...]}` wrapper) — предотвращает тихую потерю данных.
- **P2 (MED)**: `SSEClient.connect()` использует `[weak self]` для предотвращения retain cycle.
- **P4 (LOW)**: `SSEClient.sharedSession` timeouts изменены с `Int.max` (~68 лет) на 300s/600s.
- **P5 (LOW)**: `grep()` теперь предупреждает об обрезке результатов при 500+ файлах.
- **P6 (DOC)**: `FEATURE_REGISTRY.md` заголовок обновлён на "MiCoder".
- **P7 (MED)**: `E09E10ToolUndoHistoryTests` исправлен с `accessLevel: .fullAccess`.

## Раунд 29 (2026-08-21)

- **R1 (HIGH, security)**: git-инструменты (`git_commit/checkout/push/pull/log`) интерполировали модельные `message`/`branch`/`remote`/`limit` в `/bin/zsh -c` без экранирования — инъекция произвольного шелла под видом одобренной операции. Фикс: `shellQuoted`/`sanitizedNumber`, извлечённые билдеры команд + интеграционный тест на реальном git-репо (side-effect файл не создаётся).
- **R2 (MED)**: grep обрезался ровно на 100-м совпадении без предупреждения (ранний return обходил логику Round 28). Фикс: single-exit с флагами + предупреждение о лимите совпадений.
- **R3 (MED)**: glob сверял паттерн только с именем файла — любой паттерн с `/` (`src/*.swift`, `**/*.swift`) всегда возвращал «(no matches)». Фикс: полноценный glob→regex (`*` не пересекает `/`, `**` — да), матч по пути от корня, сортировка, лимит 500 + предупреждение; попутно исправлен скрытый symlink-mismatch (`/var` vs `/private/var`).
- **R4 (HIGH)**: `/api/send` отвечал устаревшими chatId/providerId/modelId — ответ строился из значений, снятых ДО асинхронных мутаций main-потока (для нового чата возвращался пустой/чужой id). Фикс: `resolveSendTargets` (@MainActor) возвращает состояние после мутаций; semaphore-паттерн как в остальных хендлерах; при таймауте 30s — честная ошибка вместо устаревших данных.
- **R5 (LOW)**: фикс Round 28 P4 выставил SSE-таймауты в `sharedSession`, но `connect()` продолжал использовать `URLSession.shared` — правка не имела эффекта. Теперь используется настроенная сессия.

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
