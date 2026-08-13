# Активити: Project и Session Persistence

Источник: `NewProjectSheet.swift`, `AppState`, `DatabaseBridge`, `ChatPanelView`.

| # | Действие | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | Project name/path | Validates both fields and trims name | PASS |
| 2 | Choose folder | NSOpenPanel selects one directory | PARTIAL, native QA |
| 3 | Create project | Creates DB/project/workspace and selects it | PASS |
| 4 | First message | Creates local session if none exists | PASS by code |
| 5 | User message save | Persists message before/alongside request | PASS by code |
| 6 | Request failure | Persists user message and error assistant message | PASS, regression test |
| 7 | Session reload | Loads saved messages when selected | PASS |
| 8 | Project routing | Keeps sessions/messages in owning DB | PASS |
| 9 | Archive | Hides session without deleting history | PASS |

## User story

As a user, creating a project never produces a disappearing chat: even a failed
first request leaves a recoverable session and visible error message.

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
