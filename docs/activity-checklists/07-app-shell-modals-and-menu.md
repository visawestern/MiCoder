# Чеклист: Оболочка приложения, модальные потоки и меню macOS

Источники: `MiCoder/Sources/Views/ContentView.swift` и
`MiCoder/Sources/App/MiCoderApp.swift`. Это отдельная экранная поверхность,
которая собирает все панели и маршрутизирует системные действия. Статусы ниже
подтверждены трассировкой `Button`/gesture до обработчика и существующими
unit-тестами; действия, требующие настоящего сервера, Keychain, Finder или
GitHub, отмечены как условные и должны быть повторены в живом сеансе.

| № | Пользовательское действие | Триггер | Ожидаемое поведение | Текущее качество |
|---|---|---|---|---|
| 1 | Запуск приложения | Открытие окна | Окно создаётся с default 1200×750, минимумом 900×600 и корневым `ContentView`; при старте загружаются custom providers, подключение к серверу, сессии и модели. | ✅ Локальная проводка полная; серверная часть зависит от доступности `mimo serve`. |
| 2 | Показ/скрытие левой панели | Кнопки в Sidebar/TaskHeader или клавиатурные потоки | `sidebarVisible` меняет состав `HStack`; основной чат остаётся доступным. | ✅ |
| 3 | Изменение ширины сайдбара | Перетащить разделитель | Ширина ограничена 200…420 pt и сохраняется в `@AppStorage`. | ✅ `SidebarResizeLogicTests`; ручной drag нужен в живом окне. |
| 4 | Сброс ширины сайдбара | Двойной клик разделителя | Ширина возвращается к 260 pt. | ✅ Логика и gesture присутствуют. |
| 5 | Открыть/закрыть Settings | Gear/open settings, фон, Escape, close | Настройки показываются как overlay; клик по затемнению и Escape закрывают его, не меняя другие панели. | ✅ `SettingsOutsideDismissTests`. |
| 6 | Открыть поиск | ⌘K или пункт Find → Search Tasks… | Показать `SearchPaletteView` в sheet. | ✅ `SearchPaletteLogicTests`. |
| 7 | Создать проект | Sidebar → New Project | Показать `NewProjectSheet` в sheet. | ✅ Проводка до `showProjectCreation`. |
| 8 | Открыть remote connection | Контрол ввода/рабочего пространства | Показать `RemoteConnectionSheet` в sheet. | ✅ Проводка до `showRemoteConnection`; подключение требует доступного хоста. |
| 9 | Открыть Git-действие от slash-команды | `/commit`, `/review`, `/pr`, `/publish` | Один `GitActionSheet` выбирает соответствующий реальный диалог и очищает `pendingGitAction` при закрытии. | ✅ `E08SlashCommandDispatchTests`; GitHub/remote сценарии условны. |
| 10 | Восстановить повреждённую БД проекта | Alert → Restore from backup | Найти последний auto-backup, восстановить его и показать точный результат либо ошибку. | ✅ `E04ProjectOpenIntegrityTests`; требуется реальный повреждённый fixture для ручной проверки. |
| 11 | Игнорировать предупреждение о БД | Alert → Ignore | Закрыть предупреждение без записи в проект. | ✅ |
| 12 | Cut / Copy / Select All | ⌘X / ⌘C / ⌘A | Делегировать стандартное действие текущему `NSText` responder. | ✅ Нативная проводка. |
| 13 | Paste | ⌘V | Передать в `ChatPasteCoordinator`; текст, файлы и изображения обрабатываются маршрутизатором ввода. | ✅ `ClipboardPasteTests`, `PasteRoutingDecisionTests`. |
| 14 | Новая задача | ⌘N или меню File | Вызвать `startNewTask` в выбранном workspace и запросить фокус ввода. | ✅ `NewTaskFocusTests`. |
| 15 | Undo последнего изменения файла | ⌥⌘Z, Actions → Undo Last File Change | При активной сессии сначала использовать project-local undo, иначе legacy global undo; меню disabled без сессии. | ✅ `E09E10ToolUndoHistoryTests`; ручная проверка требует обратимой операции с файлом. |

## Обнаруженные ограничения

- ⚠️ Первый запуск выполняет несколько асинхронных запросов параллельно. При недоступном
  сервере сам интерфейс должен оставаться рабочим, но отправка сообщений будет заблокирована
  с объяснением причины; этот сетевой сценарий не подтверждается статическим чтением кода.
- ⚠️ В этом окружении отсутствует интерактивный macOS-сеанс приложения, поэтому нельзя
  честно отметить нативные листы, Finder, Keychain, удалённый Git и drag-resize как
  «кликнутые вручную». Они вынесены в последующий live-QA цикл, а не выданы за проверенные.

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
