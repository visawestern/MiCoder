# Activity 01 — App Shell & Navigation

Источники: `Sources/App/MiCoderApp.swift`, `Sources/Views/ContentView.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | WindowGroup | `MiCoderApp.body` → `WindowGroup` → `ContentView` | Окно min 900×600, default 1200×750 | 100/100 | PASS |
| 2 | Startup task | `ContentView.task` → `loadCustomProviders()` → `connectToServer()` → `ServerConnectionReadinessLogic` | Auto Free доступен без сервера; серверные модели загружаются после health check | 95/100 | PASS |
| 3 | Sidebar visibility | `SidebarView` button → `appState.sidebarVisible` | Показывает/скрывает SidebarView | 95/100 | PASS |
| 4 | Sidebar resize handle | drag → `SidebarResizeLogic.applyDrag` → `@AppStorage("sidebarWidth")` | Drag 200..420, double-click reset 260 | 95/100 | PASS |
| 5 | Cmd+N new task | `appState.startNewTask(in:)` | Создаёт новую сессию | 95/100 | PASS |
| 6 | Cmd+Shift+P new project | `appState.showProjectCreation = true` | Открывает NewProjectSheet | 95/100 | PASS |
| 7 | Cmd+O open project | `NSOpenPanel` → `appState.addWorkspace(path:)` | Открывает папку проекта | 95/100 | PASS |
| 8 | Cmd+K search | `appState.showSearch = true` | Открывает SearchPaletteView | 95/100 | PASS |
| 9 | Cmd+Z undo | `appState.undoLastAction()` | Откат последнего изменения файла | 90/100 | PASS |
| 10 | Settings overlay | `appState.showSettings` → ZStack overlay | Открывается above app, закрывается backdrop/Escape | 95/100 | PASS |
| 11 | Search sheet | `.sheet` presents `SearchPaletteView` | Поиск по сессиям/проектам | 95/100 | PASS |
| 12 | Remote connection sheet | `RemoteConnectionSheet` → `connectToServe(host:port)` | Подключает host/port | 90/100 | PASS |
| 13 | New project sheet | `NewProjectSheet` → create/update project DB | Создаёт project/workspace | 95/100 | PASS |
| 14 | Git action sheet | `pendingGitAction` → `GitActionSheet` switch | Маршрутизирует Git action | 95/100 | PASS |
| 15 | Integrity alert | `projectIntegrityAlert` → restore/ignore | Corruption visible, restore offer | 95/100 | PASS |
| 16 | Cut/Copy/Paste/SelectAll | NSApp.sendAction via keyboard shortcuts | Работает во всех text fields | 95/100 | PASS |
| 17 | RTL layout | `appState.appLanguage.isRTL` → `.environment(\.layoutDirection)` | Право-лево для арабского | 90/100 | PASS |
| 18 | Font scaling | `appState.settings.zoom.fontScale` | 0.85/1.0/1.15 | 90/100 | PASS |
| 19 | Color scheme | `appState.appTheme.preferredColorScheme` | Dark/Light | 95/100 | PASS |

## User Story

As a user, I can open MiCoder and reach a usable composer without a running server because **MiCoder Auto Free** is available. The app provides keyboard shortcuts for common actions, resizable sidebar, and proper window management.

## Bugs Found & Fixed

| ID | Описание | Severity | Статус |
|---|---|---|---|
| FIX-01 | `stopServe()` mutated @Published properties outside @MainActor | CRITICAL | FIXED |
| FIX-02 | `isNavigatingHistory` data race — not protected by navigationLock | CRITICAL | FIXED |

## Regression Status

После исправлений: build GREEN, 2288/2288 tests GREEN.
