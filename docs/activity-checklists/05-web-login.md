# Активити: Web Provider Login и Discovery

Источник: `WebProvidersSection.swift`, `WebModelDiscovery.swift`,
`WebProviderConnectivity.swift`, `WKWebViewBrowserBridge.swift`.

| # | Действие | Ожидаемое поведение | Качество |
|---|---|---|---|
| 1 | Add Kimi/Qwen/ChatGPT | Создает config без guessed model | PASS |
| 2 | Login | Открывает embedded WebView | PARTIAL, live WebKit |
| 3 | Capture session | Сохраняет cookies after login | PARTIAL, live WebKit |
| 4 | MiMo Auto status/logo | Объясняет, что модели выбираются общим chat flow | PASS |
| 5 | Auto model discovery | После login получает только live models | PASS by code, live QA |
| 6 | Qwen multi-selector read | Merges model option surfaces, not first three only | PASS by code, live QA |
| 7 | ChatGPT stale cleanup | Не использует catalog/feature labels as models | PASS by code, live QA |
| 8 | Refresh models | Replaces stale discovery and normalizes selected model | PASS by code |
| 9 | Refresh effort | Reads effort selector and persists levels | PASS by code, live QA |
| 10 | Remove provider | Removes config and session option | PASS |

## User story

As a user, I log in once and the app discovers the current web model list;
I do not manually maintain a second browser-side model list.

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
