# Activity 17 — Storage, Backup & Restore

Источники: `Sources/Views/Settings/StorageSettingsView.swift`, `Sources/Services/ProjectStorageAdmin.swift`, `Sources/Services/ProjectAutoBackupLogic.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Per-project database | `<project>/.micoder/project.db` | Отдельная БД на проект | 95/100 | PASS |
| 2 | Project history export/import | `ProjectHistoryExporter` | Экспорт/импорт в JSON | 90/100 | PASS |
| 3 | File scanner | Recursive, excludes, 5MB cap | Сканирование файлов | 95/100 | PASS |
| 4 | File index delta | Hash+mtime computation | Дельта индекса | 90/100 | PARTIAL |
| 5 | FSEvents dynamic reindexing | CoreServices FSEvents watcher | Автообновление индекса | 90/100 | PARTIAL |
| 6 | Storage reset | `StorageResetScope.appCacheOnly` | Сброс кэша | 95/100 | PASS |
| 7 | Storage admin panel | Projects admin in Settings | Управление хранилищем | 95/100 | PASS |
| 8 | Typed-name delete | Confirmation with typed name | Безопасное удаление | 95/100 | PASS |
| 9 | Per-project VACUUM | Vacuum button per project | Компактификация | 95/100 | PASS |
| 10 | Project backup export/import | `.zip` via `/usr/bin/ditto` | Бэкап/восстановление | 90/100 | PASS |
| 11 | Orphaned project relink | NSOpenPanel → relink | Перелинковка | 90/100 | PASS |
| 12 | Bulk archive inactive | Archive all projects not opened in N days | Массовая архивация | 90/100 | PASS |
| 13 | Storage quota warning | Non-blocking warning >2GB | Предупреждение | 90/100 | PASS |
| 14 | Storage audit log | `~/.micoder/logs/storage-audit.log` | Логирование операций | 95/100 | PASS |
| 15 | Registry dedup | Deduplication at startup | Дедупликация | 95/100 | PASS |
| 16 | Per-project integrity check | PRAGMA integrity_quick_check at open | Проверка при открытии | 95/100 | PASS |
| 17 | Auto-backup before destructive | Backup before reset/VACUUM/delete | Бэкап перед удалением | 95/100 | PASS |
| 18 | Read-only path fallback | `~/.micoder/projects/<hash>/project.db` | Фолбэк для read-only | 95/100 | PASS |
| 19 | Registry+Settings export/import | Versioned bundle | Экспорт/импорт конфигурации | 90/100 | PARTIAL |
| 20 | Chunked big-project delete | Bounded chunks + progress | Постепенное удаление | 90/100 | PARTIAL |

## User Story

As a user, I can manage per-project storage with backup/restore, VACUUM, archive, and delete operations. The system auto-backs up before destructive operations, handles orphaned projects, and shows storage statistics.
