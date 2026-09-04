# Activity 16 — Database

Источники: `Sources/Services/DatabaseManager.swift`, `Sources/Services/DatabaseBridge.swift`, `Sources/Services/ProjectDatabaseManager.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | SQLite init | `DatabaseManager` creates tables | Создание таблиц при первом запуске | 95/100 | PASS |
| 2 | Schema migrations | `schema_version` + `runMigrationsIfNeeded` | Автоматическое обновление | 95/100 | PASS |
| 3 | FTS5 full-text search | `messages_fts` with BM25 | Поиск по сообщениям | 95/100 | PASS |
| 4 | Database VACUUM | Weekly auto-VACUUM | Компактификация | 95/100 | PASS |
| 5 | Project/Session CRUD | `DatabaseBridge` CRUD | Персистентность сессий | 95/100 | PASS |
| 6 | Undo/Redo stack | `UndoRedoManager` | Откат операций | 95/100 | PASS |
| 7 | WAL journal mode | `PRAGMA journal_mode=WAL` | Конкурентный доступ | 95/100 | PASS |
| 8 | Per-project DB | `ProjectDatabaseManager.open` | Отдельная БД на проект | 95/100 | PASS |
| 9 | Unassigned sessions bucket | `unassigned.db` | Сессии без проекта | 95/100 | PASS |
| 10 | Connection pool with eviction | LRU pool, idle 600s | Пул соединений | 95/100 | PASS |
| 11 | Integrity check | `PRAGMA integrity_quick_check` | Проверка целостности | 95/100 | PASS |
| 12 | `upsertProject` | Creates or updates project | Обновление существующих записей | 95/100 | FIXED |
| 13 | `updateProject` | Updates name/branch/remote | Новый метод | 95/100 | ADDED |
| 14 | `convertPartRecord` DRY | Duplicate implementations | Нарушение DRY | 80/100 | DOCUMENTED |
| 15 | Dead DispatchQueue | Created but never used | Мёртвый код | 70/100 | DOCUMENTED |
| 16 | `lastAccessedAt` race | Pool queue vs direct access | Гонка данных | 70/100 | DOCUMENTED |

## Bugs Found & Fixed

| ID | Описание | Severity | Статус |
|---|---|---|---|
| FIX-03 | `upsertProject` never updated existing records | HIGH | FIXED |
| FIX-04 | Missing `updateProject` method in DatabaseManager | HIGH | FIXED |

## User Story

As a user, my project data is stored in per-project SQLite databases with WAL journaling, automatic migrations, integrity checks, and connection pooling. Each project has its own isolated database.
