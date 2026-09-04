# Activity 03 — Chat Panel

Источники: `Sources/Views/ChatPanelView.swift`, `Sources/Views/Components/MessageRowView.swift`, `Sources/Views/Components/MarkdownTextView.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Empty state | `EmptyChatStateView` when no messages | Centered logo + title + input | 95/100 | PASS |
| 2 | Message list | `ScrollView` + `LazyVStack` | Scrollable message list | 95/100 | PASS |
| 3 | Auto-scroll | Scroll anchor → bottom | Автоскролл при новых сообщениях | 95/100 | PASS |
| 4 | Scroll-to-bottom button | Floating chevron-down | Появляется при скролле вверх | 95/100 | PASS |
| 5 | Load older messages | Button at top / auto-trigger | Пагинация сообщений | 90/100 | PASS |
| 6 | Work time separator | `WorkedTimeSeparator` | Between messages >5s apart | 90/100 | PASS |
| 7 | Message text input | TextField → `messageText` binding | Ввод текста | 95/100 | PASS |
| 8 | Send message | Send button / Enter → `sendMessage()` | Отправка сообщения | 95/100 | PASS |
| 9 | Stop generation | Stop button → `stopGeneration()` | Остановка генерации | 95/100 | PASS |
| 10 | File picker | `.fileImporter` → `showFilePicker` | Выбор файла | 90/100 | PASS |
| 11 | Attachment preview | `ComposerAttachmentPreview` | Превью вложений | 90/100 | PASS |
| 12 | Plan question card | `PlanQuestionCardView` → `submitQuestionAnswers` | Ответ на вопрос агента | 90/100 | PASS |
| 13 | Plus menu | `PlusMenuView` → attachment/photo/mention/command | Меню вложений | 95/100 | PASS |
| 14 | Command palette | `InputCommandDropdownView` → `/ @ # $` | Выпадающее меню команд | 95/100 | PASS |
| 15 | Draft persistence | Auto-save debounced 0.5s | Черновик сохраняется | 90/100 | PASS |
| 16 | Message queue | `MessageQueue` when loading | Очередь сообщений | 90/100 | PASS |
| 17 | Markdown rendering | `MarkdownTextView` | Bold/italic/code/tables/lists | 95/100 | PASS |
| 18 | Code blocks | Code block with language header + copy | Копирование кода | 95/100 | PASS |
| 19 | Thinking spoiler | Expandable reasoning | Сворачивается после завершения | 90/100 | PASS |
| 20 | Tool call display | `ToolCallPresentationLogic` | Name/args/result/status | 95/100 | PASS |
| 21 | Tool inspector | `SplitToolInspectorView` | Детали tool call | 90/100 | PASS |
| 22 | Image display | `TappableChatImage` | Inline images, full-size on click | 90/100 | PASS |
| 23 | Copy message | Button → NSPasteboard | Копирование текста | 90/100 | PASS |
| 24 | Edit message | `.editMessage` notification → draft | Загрузка в composer | 90/100 | PASS |
| 25 | Resend message | `.resendMessage` notification | Повторная отправка | 90/100 | PASS |
| 26 | Retry message | `.retryMessage` notification | Поиск предыдущего user msg | 90/100 | PASS |
| 27 | Copy entire chat | `.copyEntireChat` → `ChatCopyLogic` | Полная переписка | 90/100 | PASS |
| 28 | System-reminder strip | `MessageContentSanitizerLogic` | Удаление system-reminder | 95/100 | PASS |

## Send Routes

| Route | Behavior | Статус |
|---|---|---|
| `.openAICompatible` | Direct API via `DirectChatClient` | PASS |
| `.autoFree` | `MiCoderAutoFreeStore.streamChat` | PASS |
| `.web` | `runWebChatTurn` — WKWebView automation | PARTIAL |
| `.acp` | `ACPClient.sendChatCompletion` | PASS |
| `.mimoServe` | Standard Serve with SSE streaming | PASS |

## User Story

As a user, I can type, send, stream, stop, retry, edit, attach, and copy messages while keeping provider/model/effort selections coherent. Messages render with Markdown, code blocks, thinking spoilers, and tool call displays.

## Bugs Found & Fixed

No new bugs found in this activity during this audit round.
