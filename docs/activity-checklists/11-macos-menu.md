# Чеклист: Системное меню macOS (MiCoderApp.swift)

Источник: `MiCoder/Sources/App/MiCoderApp.swift`. Ручная сверка кода:
2026-08-06; `swift test` — 1716/1716 PASS. Проверка реального responder chain
и системного меню остаётся задачей live-QA.

| № | Команда | Shortcut | Ожидаемое поведение | Качество |
|---|---|---|---|---|
| 1 | Cut | ⌘X | Передать действие текущему `NSText` responder. | ⚠️ Требует live-QA focus. |
| 2 | Copy | ⌘C | Передать действие текущему `NSText` responder. | ⚠️ Требует live-QA focus. |
| 3 | Paste | ⌘V | Вызвать `ChatPasteCoordinator`; текст/файлы/изображения маршрутизируются в composer. | ✅ |
| 4 | Select All | ⌘A | Передать `selectAll` активному responder; команда явно возвращена после замены pasteboard group. | ⚠️ Требует live-QA focus. |
| 5 | New Task | ⌘N | Создать задачу в выбранном workspace. | ✅ |
| 6 | Search Tasks… | ⌘K | Открыть Search Palette. | ✅ |
| 7 | Undo Last File Change | ⌥⌘Z | Выполнить project-local undo, иначе legacy undo; disabled без выбранной сессии. | ✅ |
| 8 | Размеры окна | — | Default 1200×750, min 900×600. | ⚠️ Требует live-QA менеджера окон. |

## Цепочная проверка PASS

Все внутренние пункты ✅ вручную прослежены от `CommandGroup`/`CommandMenu`
до paste coordinator/AppState undo/new/search и повторно покрыты полным
`swift test`. Responder chain и window manager остаются live-QA. Детали:
[`12-chain-verification-2026-08-06.md`](12-chain-verification-2026-08-06.md).

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
