# Activity 31 — Host-Side Project Auto-Context

Дата аудита: 2026-09-06
Код: `MiCoder/Sources/Services/ProjectContextGatherLogic.swift`, `ChatPanelView.swift:659-667`, `ProjectFileSearchLogic.swift`, `ProjectFileIndexStore.swift`

## Обнаруженные кнопки/действия/состояния

| # | Поведение | Текущее качество |
|---|---|---|
| 1 | Перед отправкой host ищет файлы по тексту запроса в file index | WORKS (sendDirectly:663-667) |
| 2 | Найденные файлы (max 5, max 4000 chars) добавляются в MODEL-BOUND текст | WORKS |
| 3 | Отображаемый bubble показывает сырой пользовательский текст без context-блока | WORKS (комментарий + код подтвердают) |
| 4 | Отсутствующий/stale index не блокирует отправку (yield "") | WORKS |
| 5 | Excerpt: max 2 строки/файл, 160 chars/строка | WORKS |
| 6 | Context-блок применяется ко ВСЕМ маршрутам (web/auto-free/direct) — modelText общий | WORKS |

## User Stories

### US-AC-01: Авто-контекст проекта
**User story:** Как пользователь, я хочу, чтобы модель получала релевантный контекст проекта автоматически, без ручного указания файлов.
**Ожидаемое поведение:** `<project-context>` prepended к model text; ранжирование через ProjectFileSearchLogic; бюджеты 5 файлов/4000 chars; пустой query/index → без блока; отображение не меняется.
**Тест:** `ProjectContextGatherLogicTests` (71 строка тестов, commit 10a8932). GREEN.
**Ограничение:** качество зависит от свежести file index (indexing activity 15/28); при stale index — просто без блока, never blocking.

## Заметки архитектуры
- Чистая логика (enum, testable), UI-отделение корректно.
- Нет скрытых очередей: один синхронный поиск на send, бюджет ограничен.
- Истинность: block идёт ТОЛЬКО в modelText; проверено, что user bubble (messageStore.append) получает `text` (не modelText) — ChatPanelView:686 использует text.
