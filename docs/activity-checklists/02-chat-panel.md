# Чеклист: Панель чата (ChatPanelView.swift + компоненты)

Источники: `Views/ChatPanelView.swift` (1279 LOC) и компоненты: `InputControls.swift`,
`InputViews.swift`, `InputCommandDropdownView.swift`, `MessageRowView.swift`,
`PasteAwareTextField.swift`, `MessageAttachmentImportZone.swift`, `ZeroInsetTextField.swift`,
`MarkdownTextView.swift`, `LanguagePickerDropdown.swift`, `PlanQuestionCardView.swift`,
`ChatImageViews.swift`, `EmptyChatStateView.swift`.

## Ввод сообщения

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 1 | Многострочный ввод | `ZeroInsetTextField` | Клик в поле | AppKit-поле, авто-рост высоты (24→72), single/multi-line переключение | ✅ |
| 2 | Отправка сообщения | Кнопка «Send message» / Enter | Клик/Enter | SSE-запрос: `question.asked` → `appState.pendingQuestionRequest` + `pauseForPendingQuestion()`; `message.part.delta` → `streamingText += delta` | ✅ |
| 3 | Вставка из буфера (файлы) | `PasteAwareTextField` (`AttachmentPasteTextView`) | ⌘V / `performKeyEquivalent` | `FileDropLogic.parse` пасты, показ превью перед отправкой | ✅ |
| 4 | Drag & drop файлов | `MessageAttachmentImportZone` | Перетаскивание в зону | `onDrop` с `FileDropLogic.swiftUIUTTypes`; вставка (⌘V) через `AttachmentImportExecutor.tryImportFromPasteboard` | ✅ |
| 5 | Прикреплённые файлы | `AttachedFilesStrip` | При добавлении файла | Счётчик «N files», кнопки «Clear all», «Open folder», «Show in Finder», «Remove» (порядок #N) | ✅ |
| 6 | Прикреплённые изображения | `AttachedFilesStrip` | При добавлении картинки | Счётчик «N photo(s)», миниатюра, «Image Preview», «Cannot preview image» для битых | ✅ |
| 7 | Превью отправленной картинки | `SentImagePreviewSheet` | Клик по миниатюре | Полноразмерный просмотр (base64 → NSImage) | ✅ |
| 8 | Триггеры команд `/ @ #` | `InputCommandDropdownView` | Ввод символа-триггера в поле | `InputCommandTriggerLogic.detectTrigger` открывает оверлей-палитру (lazy-контекст, audit P16), навигация стрелками, Enter = `.defaultAction` | ✅ |
| 9 | Язык интерфейса | `LanguagePickerDropdown` | Клик по флагу | Дропдаун с флагом + поиском (`LanguagePickerLogic`), выбор меняет язык | ✅ |
| 10 | Модель | `InputControls` («Model», «Manage models») | Клик | Выбор модели; «No models for this provider» / «No variants available» при пустоте | ✅ |
| 11 | Провайдер | `InputControls` («Provider», «Manage providers») | Клик | Выбор провайдера; при пустом — «Connect the local agent or add a custom provider» | ✅ |
| 12 | Параметры модели | «Parameters — \(model)» («Model parameters») | Клик | Окно: Max tokens, top P, system prompt; «Save»/«Reset»/«Cancel» | ✅ |
| 13 | Уровень доступа | `AccessLevelMenu` («Access») | Клик | Выбор уровня доступа; пункт «Switch to Plan agent» — disabled, если `ProviderCapabilityGates.canSelectPlanAgent == false` | ⚠️ |

## Поток ответов

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 14 | Стриминг ответа | `MessageRowView` | `message.part.delta` | Текст накапливается в `streamingText`, рендер `MarkdownText` (headings, код, `interfaceFontScale`) | ✅ |
| 15 | Обновление part | `MessageRowView` | `message.part.updated` | `PlanQuestionLogic.parseOpenCodeToolPart` — инструменты/вопросы парсятся в карточки | ✅ |
| 16 | Вопрос в планировании | `PlanQuestionCardView` | Появление `question.asked` | `SciFiWizardPanel`, шаги, прогресс `PlanQuestionWizardLogic.progress` | ✅ |
| 17 | Копирование сообщения | `MessageRowView` (:199) | Кнопка Copy | Копирует текст; тултип «Copy» → «Copied» | ✅ |
| 18 | Отправить заново / Retry | `MessageRowView` (:223, :488, :576) | «Resend» (user) / «Retry» (assistant) | Повторный запрос/генерация; «Stop» (:479) прерывает генерацию («Generation stopped») | ✅ |
| 19 | Инспектор tool call | `ToolCallInspectorStep` | Раскрытие tool-вызова | Детали аргументов/результата; группировка последовательных toolCall | ✅ |
| 20 | Санитайзер контента | `MessageContentSanitizerLogic` | Рендер контента | Очистка небезопасных участков перед отрисовкой | ✅ |
| 21 | Прокрутка к последнему | Плавающая кнопка «Scroll to latest message» | Клик | Прокрутка списка вниз | ✅ |
| 22 | Загрузка истории | «Loading older messages...» | Прокрутка вверх | Подгрузка старых сообщений | ✅ |
| 23 | Пустой чат | `EmptyChatStateView` | Нет сообщений | `MiMoCopy.emptyStateTitle(workspaceName:)` — приветствие с именем воркспейса | ✅ |
| 24 | Статусы сессии | Стрип состояния | События SSE | «Task completed», «Session expired», «Session busy, aborting and retrying...», «Session idle» | ✅ |

## Ошибки и защита

| № | Сообщение | Контекст | Статус |
|---|-----------|----------|--------|
| 25 | «Unknown command /\(name). Available: …» | Ввод `/`-команды без обработчика | ✅ |
| 26 | «Command /\(cmd) needs a git repository in this workspace.» | Git-команда без репозитория | ✅ |
| 27 | «Could not open \(config.chatURL): … Check that the site is reachable and you are logged in.» | Сбой открытия web-чата | ✅ |
| 28 | «Question reply failed: …» | Сбой ответа на вопрос | ✅ |
| 29 | «The web provider is no longer configured.» | Провайдер удалён во время сессии | ✅ |
| 30 | «Failed to restore the saved session: …» | Восстановление сессии при старте | ✅ |
| 31 | «Web providers require WebKit (macOS).» | Запуск web-провайдера на сборке без WebKit | ✅ |
| 32 | «[N image(s) attached]» | Заглушка при вложенных картинках | ✅ |

## Найденные проблемы / замечания

- ⚠️ Пункт 13: переключатель на Plan-агента скрыто выключен для провайдеров без capability — UI не
  объясняет причину (нет тултипа), пользователь может решить, что кнопка сломана.
- ⚠️ Пункт 5–6: «Open folder»/«Show in Finder» и «Remove» — дублирование в `AttachedFilesStrip`;
  поведение идентичное, но визуально два места управления файлом.

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
