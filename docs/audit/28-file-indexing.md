# Activity 28 — File Indexing

Источники: `Sources/Services/ProjectFileScanner.swift`, `Sources/Services/ProjectFileIndexLogic.swift`, `Sources/Services/ProjectFileIndexWatcher.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Project file scan | `ProjectFileScanner` recursive, SHA-256, excludes, 5MB cap | Сканирование файлов | 95/100 | PASS |
| 2 | @-mention file search | `ProjectFilesCacheLogic` 30s TTL cache | Поиск файлов через @ | 95/100 | PASS |
| 3 | Persistent file index | `file_index.json` + bounded metadata | Персистентный индекс | 90/100 | PARTIAL |
| 4 | FSEvents dynamic reindexing | CoreServices FSEvents watcher | Автообновление | 90/100 | PARTIAL |
| 5 | File content search | UTF-8 searchable text, binary exclusion | Поиск по содержимому | 90/100 | PARTIAL |
| 6 | Gitignore support | `matchesGitignore` for *.ext patterns | Поддержка .gitignore | 85/100 | PARTIAL |

## Known Issues

| ID | Описание | Severity |
|---|---|---|
| PERF-01 | File scanner reads entire files into memory for hashing | LOW |

## User Story

As a user, project files are indexed with sensible excludes, searchable via @-mentions, and automatically updated when files change on disk.
