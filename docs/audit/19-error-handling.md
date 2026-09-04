# Activity 19 — Error Handling & Recovery

Источники: `Sources/Services/SendReadinessLogic.swift`, `Sources/Services/ProviderResponseValidationLogic.swift`, `Sources/Services/SessionBusyRetryLogic.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Session busy recovery | `sessionBusy` → abort → retry 500ms | Retry при 409 | 90/100 | PARTIAL |
| 2 | Server disconnected error | Route-aware connection error | Понятное сообщение | 90/100 | PARTIAL |
| 3 | Send validation errors | `sendValidationError` reports blockers | Объяснение блокировки | 95/100 | PASS |
| 4 | Readiness reason | `SendReadinessReason.reason` | Причина блокировки send | 95/100 | PASS |
| 5 | Connection validation | `connectionValidationError` | Проверка подключения | 95/100 | PASS |
| 6 | Empty response rejection | Blank completions rejected | Ошибка при пустом ответе | 95/100 | PASS |
| 7 | Provider response validation | `ProviderResponseValidationLogic` | Валидация ответа | 95/100 | PASS |
| 8 | Failed first send persistence | `SendPersistenceLogic` | Сохранение при ошибке | 95/100 | PASS |
| 9 | Bounded retry | Max retries before abort | Лимит повторных попыток | 95/100 | PASS |

## User Story

As a user, when sending fails, I see clear error messages explaining why. The system retries on server busy (409), rejects empty responses, and persists failed first sends in the project database.
