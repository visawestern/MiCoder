# Активити: Header, Status и macOS Menu

Источники: `TopBarView.swift`, `StatusBarView.swift`, `MiCoderApp.swift`.

| # | Действие | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | Sidebar toggle | Shows/hides sidebar | PASS |
| 2 | Goal toggle | Shows/hides right panel | PASS |
| 3 | Terminal toggle | Shows/hides bottom panel | PASS |
| 4 | Copy chat | Sends copy notification and feedback state | PASS, clipboard QA |
| 5 | Session title/workspace/branch | Shows current context | PASS |
| 6 | Goal badge | Shows session goal and full tooltip | PASS |
| 7 | Connection status | Connected/disconnected indicator | PASS |
| 8 | Model status | Shows effective selected model | PASS |
| 9 | Idle/loading/streaming | Shows correct state priority | PASS |
| 10 | Cmd+N | Starts new task | PASS |
| 11 | Cmd+K | Opens search | PASS |
| 12 | Cmd+Option+Z | Runs project undo when session exists | PASS |
| 13 | Cmd+X/C/V/A | Routes responder actions/paste | PARTIAL, native focus QA |

## User story

As a user, the shell always tells me which provider/model and connection state
will receive my next message.

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
