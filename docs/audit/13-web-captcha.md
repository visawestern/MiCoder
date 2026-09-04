# Activity 13 — Web Captcha Handling

Источники: `Sources/Views/Components/WebCaptchaSolverView.swift`, `Sources/Services/WebCaptchaPresentationLogic.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Captcha detection | Pre-send and mid-response | Обнаружение captcha | 90/100 | PARTIAL |
| 2 | Captcha screenshot | Скриншот captcha | Отображение в чате | 90/100 | PARTIAL |
| 3 | Interactive solver | Same-WKWebView solver sheet | Интерактивное решение | 90/100 | PARTIAL |
| 4 | Resume after solve | Bounded resume/abort | Возобновление после решения | 90/100 | PARTIAL |
| 5 | Terminal solver dismissal | Dismiss solver visibility | Скрытие solver | 90/100 | PARTIAL |

## User Story

As a user, when a captcha appears during web chat, I see it displayed in the chat and can solve it interactively in the same browser view. After solving, the conversation resumes automatically.
