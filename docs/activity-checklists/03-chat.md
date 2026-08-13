# Активити: Chat Composer и Message Feed

Источники: `ChatPanelView.swift`, `InputViews.swift`, `InputControls.swift`,
`MessageRowView.swift`, attachment components.

| # | Действие | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | Text input/Enter | Отправляет непустой текст | PASS |
| 2 | Send button | Send idle, Stop while loading | PASS |
| 3 | Readiness reason | Объясняет отсутствие provider/model/connection | PASS |
| 4 | Provider menu | Выбирает provider и запускает cascade | PASS |
| 5 | Model menu | Показывает models выбранного provider | PASS; MiMo-Auto default fixed |
| 6 | Variant menu | Показывает доступный effort/variant или disabled reason | PASS |
| 7 | Access menu | Меняет permissions и Plan mode | PASS |
| 8 | Parameters | Save/reset temperature/tokens/topP/system prompt | PASS |
| 9 | Plus menu | File/photo/@/#/command attachments | PASS |
| 10 | Paste/drop | Импортирует files/images и preview | PASS, native QA |
| 11 | Queue | Сохраняет FIFO messages during generation | PASS |
| 12 | Streaming | Показывает SSE/deltas/finished state | PASS |
| 13 | Stop | Отменяет task/SSE/server and preserves partial content | PASS |
| 14 | Edit/resend/retry | Возвращает текст и повторяет отправку | PASS |
| 15 | Copy chat/message | Кладет transcript/text в clipboard | PASS, native QA |
| 16 | Markdown/tool calls | Рендерит formatting, tools, reasoning | PASS |
| 17 | Plan questions | Показывает wizard and submits answer | PASS |
| 18 | Failed send | Создает/сохраняет local session, user message and error | PASS, regression test |

## User story

As a user, my first message is retained as a visible user story in the project
even when its provider request fails.

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
