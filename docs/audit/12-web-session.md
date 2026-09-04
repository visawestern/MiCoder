# Activity 12 — Web Session Management

Источники: `Sources/Services/WebSessionManager.swift`, `Sources/Services/WebRemoteChatStore.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Cookie persistence | `WebSessionManager` cookies.json + expiry | Сохранение кукисов | 90/100 | PARTIAL |
| 2 | LocalStorage restore | `bridge.setLocalStorage` | Восстановление localStorage | 90/100 | PARTIAL |
| 3 | Named sessions | Independent logins per provider | Независимые сессии | 90/100 | PARTIAL |
| 4 | Session switching | Active session persisted per provider | Переключение сессий | 90/100 | PARTIAL |
| 5 | Cookie restore on send | `restore` → `bridge.setCookies` | Восстановление перед отправкой | 90/100 | PARTIAL |
| 6 | Remote chat UUID routing | Per-project/chat/session mapping | Привязка к UUID | 90/100 | PARTIAL |
| 7 | Legacy key migration | Old session keys migrated | Миграция ключей | 90/100 | PARTIAL |

## User Story

As a user, I can capture, name, preserve and switch between independent web login sessions. Each project/chat/provider conversation uses the correct cookies without mixing history.
