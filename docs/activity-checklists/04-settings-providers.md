# Активити: Settings и Providers

Источники: `SettingsView.swift`, `ProvidersSettingsView.swift`, provider services.

| # | Действие | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | General tab | Theme/language/zoom persistence | PASS |
| 2 | Providers tab | Unified provider/model management | PASS |
| 3 | Add provider | Saves type/url/key/capabilities | PASS |
| 4 | Test connection | Reports endpoint result | PASS, live endpoint QA |
| 5 | Provider cards | Select/edit/remove enabled providers | PASS |
| 6 | MiMo-Auto card | Shows built-in non-removable free provider | PASS |
| 7 | Model refresh | Loads server/custom/local models | PASS |
| 8 | Skills/MCP/Plugins/Commands | Browse/install/enable/remove or list resources | PASS/PARTIAL per CSV |
| 9 | Storage | Archive/delete/VACUUM/backup/relink | PASS, native picker QA |
| 10 | Usage | Shows stored token usage and filters | PARTIAL for cost/project aggregation |

## User story

As a user, the provider selector has one canonical model source and never
replaces my explicit provider/model preference with a temporary fallback.

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
