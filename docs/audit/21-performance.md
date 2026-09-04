# Activity 21 — Performance

Источники: `Sources/Services/MessageResponseMergeLogic.swift`, `Sources/Services/MessageHistoryPaginationLogic.swift`, `Sources/Services/GitRefreshScheduler.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Message feed hysteresis | `MessageStore` pruning | Плавный список сообщений | 95/100 | PASS |
| 2 | Incremental message merge | `mergeLatestMessages` only updates changed | Без полного ре-рендера | 95/100 | PASS |
| 3 | Lazy loading / pagination | `MessageHistoryPaginationLogic` initialLimit 50, page 30 | Постраничная загрузка | 95/100 | PASS |
| 4 | Git refresh coalescing | `GitRefreshCoalescer` dedup by key | Дедупликация обновлений | 95/100 | PASS |

## User Story

As a user, the message list remains smooth with many messages through incremental merging, lazy loading, and coalesced git refreshes.
