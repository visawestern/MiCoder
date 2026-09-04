# Activity 22 — Security

Источники: `Sources/Services/KeychainManager.swift`, `Sources/Services/AccessLevelPermissionLogic.swift`, `Sources/Services/MessageContentSanitizerLogic.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Keychain API key storage | `KeychainManager` save/get/delete | Безопасное хранение ключей | 95/100 | PASS |
| 2 | Access level permissions | `AccessLevelPermissionLogic` maps level→permissions | Ограничение по уровню | 95/100 | PASS |
| 3 | Message sanitization | `MessageContentSanitizerLogic` strips system-reminder | Фильтрация system messages | 95/100 | PASS |
| 4 | Data retention (VACUUM) | Weekly VACUUM | Очистка старых данных | 95/100 | PASS |
| 5 | Privacy mode | NOT IMPLEMENTED | FUTURE | N/A | FUTURE |
| 6 | DB encryption | NOT IMPLEMENTED (FileVault covers) | FUTURE | N/A | FUTURE |

## Known Issues

| ID | Описание | Severity |
|---|---|---|
| ARCH-06 | Symlink path traversal in tool validation doesn't resolve symlinks | MEDIUM |

## User Story

As a user, API keys are stored securely in macOS Keychain, tool access is restricted by chosen level, and system messages are filtered from my view.
