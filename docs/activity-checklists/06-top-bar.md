# Чеклист: Верхняя панель (TopBarView.swift)

Источник: `MiCoder/Sources/Views/TopBarView.swift`. Ручная сверка кода и
проводки проведена 2026-08-06; `swift test` — 1716/1716 PASS. Нативное окно
не было доступно этому сеансу, поэтому «✅» означает проверенную проводку и
автотесты, а не заявленный клик в живом macOS-сеансе.

| № | Контрол / действие | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | Имя проекта и значок folder | При выбранном проекте показать его имя. | ✅ |
| 2 | Бейдж текущей Git-ветки | Показать `appState.gitBranch` с моноширинным шрифтом. | ✅ |
| 3 | Бренд MiCoder | При отсутствии проекта показать название приложения. | ✅ |
| 4 | Бейдж цели | Показать краткую метку только для валидной цели сессии; tooltip содержит полный текст цели. | ✅ |
| 5 | Goal | Переключить правую Git/Progress-панель через `showGoal`; активное состояние визуально выделено. | ✅ |
| 6 | Terminal | Показать или скрыть нижнюю панель через `showTerminal`; активное состояние визуально выделено. | ✅ |

## Риск live-QA

- ⚠️ Нужна проверка визуальной ширины длинного имени проекта и длинного текста цели в реальном окне.

## Цепочная проверка PASS

Все пункты ✅ вручную прослежены через `TopBarView` до derived session goal и
`showGoal`/`showTerminal`; полный `swift test` повторно прошёл. Детали:
[`12-chain-verification-2026-08-06.md`](12-chain-verification-2026-08-06.md).

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
