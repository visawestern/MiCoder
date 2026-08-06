# Ручная цепочная проверка заявленных PASS — 2026-08-06

## Метод

Это не визуальный smoke-test: в репозитории нет Xcode UI-test, Playwright или
другого интерфейсного harness для native SwiftUI. Поэтому вручную проверена
каждая заявленная `✅` цепочка в форме **контрол → handler/state → сервис или
рендер-результат**, после чего повторно выполнен полный `swift test`.

Результат запуска: **1716 тестов, 234 suite, 0 failures**. Два live-набора
(`Live API Integration`, `Live Clipboard Probe`) помечены XCTest как skipped;
они требуют внешнего сервера/интерактивного macOS-сеанса. Ни один пункт,
который требует их для результата, не получает здесь статус «100%».

| Activity-файл | ✅-пункты, проверенные вручную | Цепочка | Исполненное доказательство | Итог |
|---|---|---|---|---|
| `01-sidebar.md` | 1–19 | `SidebarView`/context menu → `AppState` navigation, workspace/session actions, `NotificationService` | `Sidebar Session Parity`, `Sidebar Workspace Logic`, `Sidebar resize logic`, `Search palette`, `Notification Service` | PASS |
| `02-chat-panel.md` | 1–32, кроме внешних условий | composer/dropdown/row → paste routing, send/stop/SSE, message store/renderer | `Message Sending`, `Send chain — no silent no-op`, `Clipboard Paste`, `File Drop`, `Attachment Import Executor`, `Plan question`, `ToolCallPresentationLogic`, `Chat Scroll Behavior` | PASS; живой provider/WebKit остаётся live-QA |
| `03-right-panel.md` | 1–12 | Git buttons → `AppState` → `GitRepository`/dialogs → status/progress | `AppState git integration`, `Git repository operations`, `Git Push Upstream`, `Git Publish Flow Logic`, `RightPanelProgressDisplay logic` | PASS; remote/GitHub остаётся live-QA |
| `04-bottom-panel.md` | 1–14 | tab/action → terminal executor или Git action → output/status | `TERM-01`, `TERM-02`, `TERM-03`, `TERM-04`, `Git repository operations`, `Git refresh logic` | PASS; настоящий shell/repo остаётся live-QA |
| `05-settings.md` | 1–45, за исключением ⚠️ | settings controls → `AppState`/registry/storage/provider services → persistence | `SET-02`…`SET-08`, `AppState Settings Integration`, `Settings Persistence Parity`, `Settings actions — crash regression`, `Project registry admin`, `Project backup export/import`, `E11 MCP health check`, `E23/E24` | PASS; Keychain/file picker/network health — live-QA |
| `06-top-bar.md` | 1–6 | `TopBarButton` → `showGoal`/`showTerminal`; derived goal badge → SwiftUI render | `RTP-01: Right panel visibility`, `Slash command execution + session goal`; ручная трассировка `TopBarView` | PASS |
| `07-task-header.md` | 1–9 | header controls → `NotificationCenter.copyEntireChat`/AppState booleans → view state | `Task Header`, `Chat copy`, `Sidebar Toggle Parity`; ручная трассировка `TaskHeaderView` | PASS; фактический system clipboard — live-QA |
| `08-status-bar.md` | 1–6 | AppState connection/model/loading flags → conditional status rendering | `Status Bar`; ручная трассировка всех ветвей `StatusBarView.body` | PASS |
| `09-new-project.md` | 1–8, кроме picker | form submit/button → trim/guard → `AppState.createNewProject` → dismiss | `New Task Input Focus`, project/session persistence tests; ручная трассировка `NewProjectSheet` | PASS; `NSOpenPanel` — live-QA |
| `10-app-shell.md` | 1–11, кроме сетевых условий | ContentView state → panel/sheet/alert routing → AppState/services | `Settings Outside Dismiss`, `Sidebar resize logic`, `Search palette`, `E04 integrity`, `E08 slash commands dispatch real side effects`, `SET-08 Remote Connection` | PASS; server/drag animation — live-QA |
| `11-macos-menu.md` | 1–8, кроме responder/window live-QA | `CommandGroup`/`CommandMenu` → NSText responder, paste coordinator, AppState undo/new/search | `Clipboard Paste`, `Paste Routing Integration`, `New Task Input Focus`, `E09/E10 tool undo history` | PASS; native menu focus/window manager — live-QA |

## Вердикт

- Все ранее заявленные как `✅` внутренние цепочки вручную прослежены и повторно
  прошли релевантные тесты в полном прогоне.
- `⚠️` остаются только там, где фактический результат зависит от внешней
  инфраструктуры или отсутствующего native UI-harness; они не маскируются под
  ручную проверку.
- Ошибок в проверяемых внутренних цепочках в этом цикле не найдено; исправлений
  кода не требуется.

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
