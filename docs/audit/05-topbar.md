# Activity 05 — Top Bar

Источники: `Sources/Views/TopBarView.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Sidebar toggle | Sidebar icon → `appState.sidebarVisible.toggle()` | Показ/скрытие sidebar | 95/100 | PASS |
| 2 | Session title | Text display | Заголовок текущей сессии | 95/100 | PASS |
| 3 | Workspace badge | Folder + name chip | Текущий workspace | 95/100 | PASS |
| 4 | Branch badge | Command icon + branch name | Текущая git ветка | 90/100 | PASS |
| 5 | MiCoder fallback | Text when no project | "MiCoder" | 95/100 | PASS |
| 6 | Session goal badge | Text chip from `/goal` | Результат /goal | 90/100 | PASS |
| 7 | Shell action notice | Icon + text, auto-dismiss | Уведомление о shell action | 90/100 | PASS |
| 8 | Copy entire chat | Doc icon → `NotificationCenter.post(.copyEntireChat)` | Копирование переписки | 95/100 | PASS |
| 9 | Goal panel toggle | Flag button → `appState.showGoal.toggle()` | Правая панель | 95/100 | PASS |
| 10 | Terminal panel toggle | Terminal button → `appState.showTerminal.toggle()` | Нижняя панель | 95/100 | PASS |

## User Story

As a user, I see a unified header with session title, workspace badge, branch badge, and goal badge. I can toggle the sidebar, terminal panel, and goal panel, and copy the entire chat.
