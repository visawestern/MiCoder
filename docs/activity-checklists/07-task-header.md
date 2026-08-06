# Чеклист: Заголовок задачи (TaskHeaderView.swift)

Источник: `MiCoder/Sources/Views/TaskHeaderView.swift`. Ручная сверка кода:
2026-08-06; `swift test` — 1716/1716 PASS. ✅ обозначает проверенную
проводку/автотесты; системный clipboard требует отдельного живого QA.

| № | Контрол / действие | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | Условный показ заголовка | Полный заголовок показывается только при выбранной сессии. | ✅ |
| 2 | Название задачи | Показать title выбранной сессии в одну строку. | ✅ |
| 3 | Бейдж workspace | Показать имя выбранного workspace, если он есть. | ✅ |
| 4 | Бейдж ветки | Показать ветку workspace; fallback — `main`. | ✅ |
| 5 | Левый sidebar toggle | Показать/скрыть sidebar с анимацией; есть accessibility help. | ✅ |
| 6 | Copy entire chat | Отправить `.copyEntireChat`; на 1.5 s сменить значок и tooltip на «Copied». | ✅ |
| 7 | Terminal | Переключить нижнюю панель терминала. | ✅ |
| 8 | Правая Git/goal-панель | Переключить `showGoal`; иконка и tooltip задаются `TaskHeaderLayout`. | ✅ |
| 9 | Compact header без сессии | Оставить доступными sidebar toggle и правую панель в компактном заголовке. | ✅ |

## Риск live-QA

- ⚠️ Проверить фактическое содержимое буфера после Copy и усечение очень длинного title.

## Цепочная проверка PASS

Все внутренние пункты ✅ вручную прослежены до `NotificationCenter`/AppState и
view state; полный `swift test` повторно прошёл. System clipboard остаётся
live-QA. Детали: [`12-chain-verification-2026-08-06.md`](12-chain-verification-2026-08-06.md).

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
