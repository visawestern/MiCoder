# Activity 14 — Web Tool Protocol & Access Gates

Источники: `Sources/Services/WebToolProtocolEmulator.swift`, `Sources/Services/ProjectWebToolExecutor.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Tool protocol emulation | `WebToolProtocolEmulator` systemPreamble/parseToolCalls/formatToolResult | Эмуляция tool-протокола | 95/100 | PASS |
| 2 | Strict + informal syntax | Both JSON and XML format parsing | Парсинг обоих форматов | 95/100 | PASS |
| 3 | Tool validation | `validate` checks path boundaries | Валидация путей | 90/100 | PARTIAL |
| 4 | Access level gate | `WebToolAccessGate` gates run_command | Гейт по AccessLevel | 95/100 | PASS |
| 5 | read_file/write_file/edit_file | `ProjectWebToolExecutor` | Исполнение на диске | 95/100 | PASS |
| 6 | list_dir/grep/run_command | `ProjectWebToolExecutor` | Чтение/поиск/выполнение | 95/100 | PASS |
| 7 | Destructive tool classification | `requiresApproval` covers all mutations | Классификация инструментов | 95/100 | PASS |
| 8 | Approval interruption | Blocked mutation explained in chat | Видимое объяснение блокировки | 90/100 | PARTIAL |
| 9 | Iteration limit | `config.maxToolIterations` | Лимит итераций | 95/100 | PASS |

## Known Issues

| ID | Описание | Severity |
|---|---|---|
| ARCH-06 | Symlink path traversal in tool validation — `isPathInsideRoot` doesn't resolve symlinks | MEDIUM |
| ARCH-05 | `addColumnIfMissing` uses string interpolation for SQL (internal only) | MEDIUM |

## User Story

As a user, web-agent tools are validated against project boundaries and access levels. Destructive operations require approval, and the tool protocol supports both JSON and XML formats.
