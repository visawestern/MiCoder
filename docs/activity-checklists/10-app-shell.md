# Чеклист: Оболочка приложения и модальные маршруты (ContentView.swift)

Источник: `MiCoder/Sources/Views/ContentView.swift`. Ручная сверка кода:
2026-08-06; `swift test` — 1716/1716 PASS.

| № | Действие / состояние | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | Начальная загрузка | Загрузить custom providers, подключиться к серверу и параллельно запросить sessions/models. | ⚠️ Сеть зависит от доступного сервера. |
| 2 | Компоновка панелей | Собрать sidebar, top bar, условный task header, chat, terminal, status и правую панель согласно AppState. | ✅ |
| 3 | Theme / RTL | Применить выбранную схему, font scale и RTL для языков с RTL. | ✅ |
| 4 | Resize sidebar | Drag ограничен 200…420 pt и сохраняется; двойной клик сбрасывает к 260. | ✅ |
| 5 | Settings overlay | Открыть поверх приложения; закрыть кликом на backdrop, Escape или кнопкой внутри Settings. | ✅ |
| 6 | Search sheet | Показать `SearchPaletteView` по `showSearch`. | ✅ |
| 7 | Remote connection sheet | Показать `RemoteConnectionSheet` по `showRemoteConnection`. | ✅ |
| 8 | New project sheet | Показать `NewProjectSheet` по `showProjectCreation`. | ✅ |
| 9 | Git action sheet | Маршрутизировать commit/review/publish/PR из `pendingGitAction` в соответствующий реальный диалог и очистить trigger по закрытию. | ✅ |
| 10 | Corrupt DB alert: Restore | Восстановить последний backup и сообщить точный результат/ошибку. | ✅ |
| 11 | Corrupt DB alert: Ignore | Закрыть alert, очистив pending integrity warning. | ✅ |

## Риск live-QA

- ⚠️ Drag-resize, переходы overlay и одновременные сетевые загрузки требуют прогона в настоящем окне с сервером.

## Цепочная проверка PASS

Все внутренние пункты ✅ вручную прослежены от `ContentView` state до
sheet/alert/panel routing и сервисов; полный `swift test` повторно прошёл.
Сеть и нативная анимация остаются live-QA. Детали:
[`12-chain-verification-2026-08-06.md`](12-chain-verification-2026-08-06.md).

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
