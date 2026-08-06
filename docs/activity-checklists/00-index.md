# Activity Checklist — MiCoder (macOS SwiftUI)

Папка с по-экрановыми чеклистами действий/кнопок MiCoder. Составлено **вручную по коду**
(`MiCoder/Sources/Views/**`), без живого UI-сеанса. Последняя ручная сверка
проводки: **2026-08-06**; полный `swift test`: **1716/1716 PASS**, 234 suite.

## Методология и ограничения

- Источник истины — исходники Views/Components; поведение сверяется с тестами
  (`MiCoder/Tests/**`, `swift test` ~1713 тестов).
- «Проверено» здесь означает: элемент присутствует в коде, проводка на действие/обработчик
  прослеживается до конечной логики. Интерактивный UI-прогон в этом окружении невозможен
  (нет живого сеанса) — это явное ограничение метода.
- Проверка от 2026-08-05: `swift test` собрался; при полном параллельном прогоне один
  time-sensitive тест автодетекта провайдеров превысил свой лимит (4.78 s вместо <2.5 s),
  а немедленный изолированный прогон `E23E24AutoDetectConfirmationTests` прошёл 20/20.
  Это воспроизводимый риск тестовой изоляции/планировщика, не доказательство сбоя UI.

## Легенда статусов

| Статус | Значение |
|--------|----------|
| ✅ | Элемент есть в коде, действие/состояние прослеживается до логики |
| ⚠️ | Элемент есть, но есть оговорка (краевой случай, UX-дыра, зависимость от конфигурации) |
| ❌ | Элемент отсутствует / поведение не реализовано / заведомая ошибка |

## Инвентарь экранов

| Файл-источник | Размер (LOC) | Чеклист |
|---|---|---|
| `Views/SidebarView.swift` | 959 | `01-sidebar.md` |
| `Views/ChatPanelView.swift` + компоненты ввода/сообщений | 1279 + (InputViews 778, MessageRowView 730, InputControls, InputCommandDropdownView, PasteAwareTextField 391, MessageAttachmentImportZone, ZeroInsetTextField, MarkdownTextView 279, LanguagePickerDropdown, PlanQuestionCardView, ChatImageViews, EmptyChatStateView) | `02-chat-panel.md` |
| `Views/RightPanelView.swift` | 462 | `03-right-panel.md` |
| `Views/BottomPanelView.swift` | 805 | `04-bottom-panel.md` |
| `Views/SettingsView.swift` | 2960 | `05-settings.md` |
| `Views/TopBarView.swift` | верхняя панель | `06-top-bar.md` |
| `Views/TaskHeaderView.swift` | заголовок выбранной задачи | `07-task-header.md` |
| `Views/StatusBarView.swift` | строка состояния | `08-status-bar.md` |
| `Views/NewProjectSheet.swift` | создание проекта | `09-new-project.md` |
| `Views/ContentView.swift` | корневая компоновка и модальные маршруты | `10-app-shell.md` |
| `App/MiCoderApp.swift` | окно и системное меню macOS | `11-macos-menu.md` |

## Сквозные риски (не экранные)

- ✅ Полный `swift test` в текущем чистом прогоне прошёл: 1716 тестов в 234 suite.
- ⚠️ `docs/FEATURE_SPREADSHEET.csv` APP-05 (`Rebrand to MiCoder`) = PARTIAL «3 user-facing 'MiMo'
  strings remain» — **устарело**: Round 23 их починил, спредшит будет обновлён на следующем шаге.
- ⚠️ Web-провайдеры требуют WebKit — на неподдерживающих сборках показано
  «Web providers require WebKit (macOS).» (защита по дизайну).

## Повторная цепочная проверка

Все строки со статусом ✅ повторно вручную прослежены до конечного состояния
и подтверждены полным запуском тестов 2026-08-06. Детальная матрица
«контрол → handler → сервис/результат → тест» находится в
[`12-chain-verification-2026-08-06.md`](12-chain-verification-2026-08-06.md).

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
