# Активити: App Shell

Источник: `ContentView.swift`, `MiCoderApp.swift`.

| # | Контрол/действие | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | WindowGroup | Открывает окно с min 900x600 и default 1200x750 | PASS |
| 2 | Startup task | Загружает providers, подключается к serve, грузит sessions/models | PASS, network QA |
| 3 | Sidebar visibility | Показывает/скрывает SidebarView | PASS |
| 4 | Sidebar resize handle | Drag 200..420, double-click reset 260, persistence | PASS |
| 5 | TopBarView | Собирает header controls | PASS |
| 6 | ChatPanelView | Показывает empty state или message feed | PASS |
| 7 | BottomPanelView | Показывает terminal/Git по `showTerminal` | PASS |
| 8 | RightPanelView | Показывает plan/Git по `showGoal` | PASS |
| 9 | Settings overlay | Открывается, закрывается backdrop/Escape/close | PASS |
| 10 | Search sheet | Открывает SearchPaletteView | PASS |
| 11 | Remote connection sheet | Подключает host/port | PASS, network QA |
| 12 | New project sheet | Создает project/workspace | PASS |
| 13 | Git action sheet | Маршрутизирует commit/review/publish/PR | PASS |
| 14 | Integrity alert restore/ignore | Restore backup или очищает warning | PASS |

## User story

As a user, I can open MiCoder and reach a usable composer without a running
MiMo Serve because the free MiMo-Auto route is selected by default.

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
