# Activity Checklist — MiCoder (macOS SwiftUI)

Папка с по-экрановыми чеклистами действий/кнопок MiCoder. Составлено **вручную по коду**
(`MiCoder/Sources/Views/**`), без живого UI-сеанса.

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
| `Views/TopBarView.swift`, `TaskHeaderView.swift`, `StatusBarView.swift`, `NewProjectSheet.swift` | 4 файла | `06-topbar-taskheader-statusbar-newproject.md` |
| `Views/ContentView.swift`, `App/MiCoderApp.swift` | оболочка, меню, модальные маршруты | `07-app-shell-modals-and-menu.md` |
| `Views/ContentView.swift`, `App/MiCoderApp.swift` | корневой экран, модальные маршруты и меню macOS | `07-app-shell-modals-and-menu.md` |

## Сквозные риски (не экранные)

- ⚠️ Полный `swift test` нестабилен из-за deadline-проверки
  `E23E24AutoDetectConfirmationTests`; отдельный повтор прошёл 20/20. Перед релизом стоит
  повторить полный прогон в чистом процессе и устранить зависимость этого теста от нагрузки.
- ⚠️ `docs/FEATURE_SPREADSHEET.csv` APP-05 (`Rebrand to MiCoder`) = PARTIAL «3 user-facing 'MiMo'
  strings remain» — **устарело**: Round 23 их починил, спредшит будет обновлён на следующем шаге.
- ⚠️ Web-провайдеры требуют WebKit — на неподдерживающих сборках показано
  «Web providers require WebKit (macOS).» (защита по дизайну).

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
