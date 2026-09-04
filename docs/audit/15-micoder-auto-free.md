# Activity 15 — MiCoder Auto Free Provider

Источники: `Sources/Services/MiCoderAutoFreeProvider.swift`, `Sources/Services/MiCoderAutoFreeFailoverLogic.swift`, `Sources/Services/MiCoderAutoFreeContentLogic.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Built-in route | `micoder-auto-free` ID | Бесплатный провайдер | 95/100 | PASS |
| 2 | Big Pickle model | OpenCode Zen `big-pickle` | Основная бесплатная модель | 95/100 | PASS |
| 3 | Anonymous discovery | GET /models без API key | Обнаружение бесплатных моделей | 95/100 | PASS |
| 4 | Failover state machine | 5 failures → next trusted model | Переключение при ошибках | 95/100 | PASS |
| 5 | Rate-limit notification | 429/rate-limit → red error | Уведомление о rate limit | 95/100 | PASS |
| 6 | System prompt editor | TextEditor + Save | Пользовательский промпт | 95/100 | PASS |
| 7 | Model lock toggle | Toggle switch | Блокировка выбора модели | 90/100 | PASS |
| 8 | Refresh catalog | Button → re-read /models | Обновление каталога | 95/100 | PASS |
| 9 | Attachment payload | image_url data URLs + text files | Вложения в запросе | 90/100 | PARTIAL |
| 10 | Conversation history | Prior turns prepended | История в запросе | 90/100 | PARTIAL |
| 11 | Eligibility check | Trusted temporary free IDs | Проверка доступности | 95/100 | PASS |
| 12 | No API key gate | Anonymous route | Без ключа | 95/100 | PASS |

## User Story

As a user, MiCoder Auto Free provides built-in free AI models without API keys. The system discovers available models, handles failover when models fail, and shows clear status in settings.
