# Активити: Web Chat Driver

Источник: `WebChatDriver.swift`, `ChatPanelView.runWebChatTurn`.

| # | Действие | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | Select web provider | Uses `web:<id>` route | PASS |
| 2 | Inject model | Selects the chosen discovered model in page | PASS by code, live QA |
| 3 | Inject effort | Selects vendor effort when selector exists | PASS by code, live QA |
| 4 | Send prompt | Types and clicks vendor send | PASS by code, live QA |
| 5 | Await response | Polls stop button and stable response | PASS |
| 6 | Tool call loop | Executes read/write/edit/list/grep/run_command gate | PASS |
| 7 | Captcha/logout | Emits visible interruption event | PASS |
| 8 | Session limit | Restarts with carry-over seed | PASS |
| 9 | Chunking | Splits oversized prompt safely | PASS |
| 10 | Error event | Emits error and persists failed turn through caller | PASS by code |

## User story

As a user, web model and effort choices made in the shared composer are applied
to the authenticated browser before the message is sent.

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
