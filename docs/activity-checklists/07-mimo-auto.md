# Активити: MiMo-Auto Provider

Источники: `MiMoAutoProvider.swift`, `MiMoAutoClient.swift`, `SendRouteResolver.swift`.

| # | Действие | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | Provider option | Built-in `mimo-auto` always appears and cannot be removed | PASS |
| 2 | Free default | Fresh state selects provider and model `mimo-auto` | PASS, targeted test |
| 3 | Model refresh | Keeps free fallback on API failure | PASS |
| 4 | Model selector | Lists provider models and persists selection | PASS |
| 5 | API key | Optional free mode; validates supplied key | PASS, network QA |
| 6 | Send route | Resolves to `.mimoAuto`, not serve | PASS |
| 7 | Stream | Sends direct API request and renders deltas | PASS by code, network QA |
| 8 | Failed request | Leaves user/assistant error in local session | PASS, regression test |

## User story

As a new user, I can type and send immediately through Xiaomi MiMo-Auto's free
default model without first starting MiMo Serve or choosing a model manually.

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
