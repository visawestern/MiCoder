# Проверка web-провайдера: E2E-цепочка — 2026-08-06

## Результат

Внутренняя цепочка web-provider проверена и исправлена. После исправления
полный `swift test` завершился успешно: **1716 тестов, 234 suite, 0 failures**.

| Цепочка | Что проверено | Результат |
|---|---|---|
| Модели | Catalog selector → открыть model dropdown → прочитать UI → parser → `discoveredModels` → `WebProviderStore` | ✅ Исправлено: отправка больше не читает закрытый dropdown напрямую, а вызывает `WebModelDiscovery.discover`. |
| Сессия | Login cookies → `WebSessionManager` → persistent `WKWebView` → восстановление cookies → navigation → ожидание chat input | ✅ Логика и negative paths проверены; настоящая авторизованная сессия требует live-QA. |
| Сообщение | Composer → `runWebChatTurn` → browser bridge type/click → polling response → assistant bubble | ✅ Проверено scripted browser E2E (`WebChatDriverTests`), включая streaming/final/error. |
| Agentic tools | Ответ web-модели → `tool` block / informal alias → validation → `ProjectWebToolExecutor` → `tool_result` → следующий browser message | ✅ Проверены read/write/edit/list/grep, tool-result round-trip, iteration limit и aliases. |
| Файловая безопасность | path → `isPathInsideRoot` → executor | ✅ Выход за project root отклоняется до запуска executor. |
| Изменения и shell | write/edit/run command → access gate → undo/history либо approval result | ✅ Изменения защищены access level; `run_command` выполняется только на full access. |
| Сбой сессии | captcha/logout/limit → visible event → assistant message / restart | ✅ Проверены captcha, logout, prompt splitting и restart с carry-over. |

## Исправление

В [ChatPanelView.swift](/Users/apple/projects/micoder-987719cf/MiCoder/Sources/Views/ChatPanelView.swift)
поток отправки web-сообщения теперь использует `WebModelDiscovery.discover`,
который раскрывает динамический dropdown до чтения. Раньше этот путь мог
сохранить пустой список моделей, хотя модельный список был доступен после
клика.

## Реальный live-web сценарий

Не выполнен: в текущем сеансе нет выбранного авторизованного web-провайдера,
а отправка сообщения в сторонний аккаунт — внешний side effect. Для финальной
проверки нужно: войти в Kimi, Qwen или ChatGPT в приложении, выбрать его и
разрешить отправку безвредного тестового запроса с чтением файла test-project.

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
