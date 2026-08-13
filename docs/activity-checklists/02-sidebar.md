# Активити: Sidebar и Workspace

Источник: `SidebarView.swift`.

| # | Действие | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | Back/Forward | Переход по истории workspace, границы disabled | PASS |
| 2 | Toggle sidebar | Меняет `sidebarVisible` | PASS |
| 3 | Expand/collapse Workspaces | Переключает секцию | PASS |
| 4 | Overview | Открывает обзор workspace | PASS |
| 5 | Archive popover | Показывает архив и Restore | PASS |
| 6 | Workspace search | Фильтрует workspace | PASS |
| 7 | Sort menu | Сортирует name/recent/task count | PASS |
| 8 | Filter menu | All/has sessions/empty/archived | PASS |
| 9 | List/grid | Меняет режим отображения | PASS |
| 10 | Workspace row | Выбирает workspace и его sessions | PASS |
| 11 | Session row | Открывает session/chat | PASS |
| 12 | New task | Создает новую задачу и фокусирует input | PASS |
| 13 | New project | Открывает NewProjectSheet | PASS |
| 14 | Context menu | Open session, new task, Finder, changes, storage | PASS, native QA |
| 15 | Notifications | Открывает sheet, mark all read | PASS |
| 16 | Settings | Открывает settings | PASS |
| 17 | User footer | Показывает initials/name | PASS, display-only |

## User story

As a user, I can select a workspace or session and start a task without losing
the selected project context.

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
