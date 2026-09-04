# Activity 27 — Session Management

Источники: `Sources/Services/SendPersistenceLogic.swift`, `Sources/Services/SessionSendLogic.swift`, `Sources/Services/SelectionRestoreLogic.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Session creation | `shouldCreateNewSession` → `createSession` | Создание при первом сообщении | 95/100 | PASS |
| 2 | Session persistence | Loaded from local DB or server | Персистентность между запусками | 95/100 | PASS |
| 3 | Session archiving | `archiveSession` sets isArchived | Архивация старых сессий | 95/100 | PASS |
| 4 | Send selections restore | `restoreSelections` from last message | Восстановление provider/model | 95/100 | PASS |
| 5 | Failed first send persistence | `recordRejectedSend` | Сохранение при ошибке | 95/100 | PASS |
| 6 | Session reuse | Reuse existing session for new messages | Переиспользование сессий | 95/100 | PASS |

## User Story

As a user, my sessions are created on first message, persisted across launches, and my provider/model selections are restored per session.
