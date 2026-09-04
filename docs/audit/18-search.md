# Activity 18 — Search

Источники: `Sources/Services/SearchPaletteLogic.swift`, `Sources/Services/ProjectFileIndexLogic.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Search palette UI | `SearchPaletteView` sheet | Поиск по сессиям | 95/100 | PASS |
| 2 | FTS5 search logic | `matchingSessions` uses FTS5 + title fallback | Полноценный поиск | 95/100 | PASS |
| 3 | Search result opens session | `selectSession` + dismiss sheet | Открытие сессии из результата | 95/100 | PASS |
| 4 | @-mention file search | `ProjectFilesCacheLogic` 30s TTL cache | Поиск файлов через @ | 95/100 | PASS |
| 5 | Persistent file index | `file_index.json` + bounded metadata | Персистентный индекс | 90/100 | PARTIAL |
| 6 | File content search | UTF-8 searchable text, binary exclusion | Поиск по содержимому | 90/100 | PARTIAL |

## User Story

As a user, I can search across sessions and messages using FTS5 full-text search, find files from the project index using @-mentions, and browse project files with content search.
