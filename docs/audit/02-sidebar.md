# Activity 02 — Sidebar

Источники: `Sources/Views/SidebarView.swift`, `Sources/Services/SidebarWorkspaceLogic.swift`, `Sources/Services/SidebarExpansionLogic.swift`, `Sources/Services/SidebarSessionLimitLogic.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Back navigation | Chevron left → `appState.navigateBack()` | Назад по истории workspace | 95/100 | PASS |
| 2 | Forward navigation | Chevron right → `appState.navigateForward()` | Вперёд по истории workspace | 95/100 | PASS |
| 3 | Toggle sidebar | Sidebar icon → `appState.sidebarVisible.toggle()` | Показ/скрытие sidebar | 95/100 | PASS |
| 4 | New task | Cmd+N → `appState.startNewTask(in:)` | Новая сессия в workspace | 95/100 | PASS |
| 5 | New project | Cmd+Shift+P → `appState.showProjectCreation = true` | NewProjectSheet | 95/100 | PASS |
| 6 | Open project | Cmd+O → `NSOpenPanel` → `appState.addWorkspace(path:)` | Открытие папки | 95/100 | PASS |
| 7 | Grouping pill | `SidebarGroupingPill` → `appState.sidebarGroupingMode` | Переключение Project/Group | 90/100 | PASS |
| 8 | Expand/collapse all | Chevron → `appState.workspacesSectionExpanded.toggle()` | Все workspace | 95/100 | PASS |
| 9 | Workspaces overview | Expand icon → `appState.showWorkspacesOverview = true` | Overview sheet | 95/100 | PASS |
| 10 | Archive button | Archivebox → `appState.showArchivePopover.toggle()` | Archived projects popover | 90/100 | PASS |
| 11 | Sort menu | Menu → `appState.workspaceSortOrder` | Сортировка по name/recent/count | 95/100 | PASS |
| 12 | Filter menu | Menu → `appState.workspaceFilterPreset` | Фильтрация | 95/100 | PASS |
| 13 | Search toggle | Magnifying glass → `appState.showWorkspaceSearchField` | Поиск по workspace | 95/100 | PASS |
| 14 | View mode toggle | Grid/List icon → `workspaceViewMode` toggle | Переключение вида | 95/100 | PASS |
| 15 | Workspace grid | 2-column `LazyVGrid` → `appState.selectWorkspace(workspace)` | Выбор workspace | 95/100 | PASS |
| 16 | Workspace select | Click group → `appState.selectWorkspace(workspace)` | Выбор + показ сессий | 95/100 | PASS |
| 17 | Session select | Click → `appState.selectSession(session)` | Открытие сессии в чате | 95/100 | PASS |
| 18 | Session hover: new task | Plus icon (hover) → `appState.startNewTask(in:)` | Новая сессия | 95/100 | PASS |
| 19 | Session hover: context menu | Ellipsis → Show in Finder / New task | Контекстное меню | 90/100 | PASS |
| 20 | Search palette | TextField → filter sessions/files | Поиск + выбор результата | 95/100 | PASS |
| 21 | Notifications | Bell → `showNotifications = true` | NotificationsSheet | 90/100 | PASS |
| 22 | Mark all read | Button → `notificationService.markAllAsRead()` | Сброс unreadCount | 90/100 | PASS |
| 23 | User avatar | Circle with initials | Display only | 95/100 | PASS |
| 24 | Settings gear | Gear → `appState.openSettings()` | Settings overlay | 95/100 | PASS |
| 25 | Archive restore | Restore button → `ProjectRegistryLogic.restore` | Восстановление проекта | 90/100 | PASS |
| 26 | Session limit (12) | `SidebarSessionLimitLogic` | max 12 recent sessions | 95/100 | PASS |
| 27 | Workspace hover actions | + and ... buttons on hover | New task + context menu | 90/100 | PASS |

## User Story

As a user, I can see all my workspaces in the left sidebar, expand/collapse them, see sessions under each workspace (max 12), search/filter/sort workspaces, switch between list and grid view, navigate back/forward between workspaces, and manage archived projects.

## Bugs Found & Fixed

| ID | Описание | Severity | Статус |
|---|---|---|---|
| FIX-02 | `isNavigatingHistory` race affected sidebar navigation | CRITICAL | FIXED |

## Regression Status

После исправлений: build GREEN, 2288/2288 tests GREEN.
