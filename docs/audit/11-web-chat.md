# Activity 11 — Web Chat (Browser Automation)

Источники: `Sources/Services/WebChatDriver.swift`, `Sources/Services/WKWebViewBrowserBridge.swift`, `Sources/Services/WebBrowserTransportLogic.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Browser send | `runWebChatTurn` → WKWebView | Отправка через браузер | 90/100 | PARTIAL |
| 2 | Model injection | `WebChatDriver.runTurn` | Инжекция модели в UI | 90/100 | PARTIAL |
| 3 | Effort injection | `WebChatDriver.runTurn` | Инжекция усилия | 90/100 | PARTIAL |
| 4 | Send verification | `SendSubmissionPolicy` | Верификация по chat-id в URL | 90/100 | PARTIAL |
| 5 | Cookie/session persistence | `WebSessionManager` cookies.json | Сохранение сессии | 90/100 | PARTIAL |
| 6 | Browser isolation | WKWebView keyed by project/chat/provider | Изоляция экземпляров | 95/100 | PASS |
| 7 | Stop browser | Click through WKWebView bridge | Остановка в браузере | 90/100 | PARTIAL |
| 8 | Response capture | `readText` skips hidden/empty wrappers | Захват ответа модели | 90/100 | PARTIAL |
| 9 | Remote chat binding | `bindWebRemoteChat` | Привязка к UUID чата | 90/100 | PARTIAL |
| 10 | Tool protocol emulation | `WebToolProtocolEmulator` | Эмуляция tool-протокола | 95/100 | PASS |
| 11 | SmartSend fallback | Direct API or smart element detection | Fallback перед driver | 90/100 | PARTIAL |
| 12 | Catalog refresh | On injection failure | Обновление каталога моделей | 90/100 | PARTIAL |
| 13 | Iteration limit | `maxToolIterations` | Лимит итераций агентного цикла | 95/100 | PASS |
| 14 | Anti-ban delay | Jitter + humanized typing | Задержки между действиями | 90/100 | PARTIAL |

## User Story

As a user, I can use web-based AI providers (Kimi, Qwen, ChatGPT) through an embedded browser. The system handles model/effort injection, send verification, session persistence, and captcha detection.

## Known Limitations

- PARTIAL: Native WebKit runtime behavior unverified on macOS
- PARTAL: Live vendor DOM selectors may drift
- PARTIAL: Third-party captcha behavior unverified
