# Round 62 — storage/settings export and cleanup audit findings

`ProjectHistoryExporter` exports/imports one project’s sessions, messages, parts, and request history as a schema-versioned JSON bundle. It does not export the global project registry, provider/settings preferences, or other app configuration, so it does not satisfy STO-27’s registry+settings export/import story.

`ProjectStorageAdmin` only computes per-project DB sizes, bulk archive candidates, and quota status. No chunked project-delete implementation or UI consumer was found in the inspected source. The next trace must inspect Settings/Storage views and AppState reset/delete entry points before writing red regressions.


`StorageSettingsView` has per-project backup export/import buttons, archive/restore, vacuum, typed-name delete confirmation, and explicit reset alerts. `exportProjectBackup`/`importProjectBackup` call `ProjectBackupLogic`, while `deleteProject` auto-backs up, preserves the backup globally, logs, then synchronously removes the project’s entire `.micoder` directory with `FileManager.removeItem`. It never deletes user files, but it has no chunking/progress/cancellation and does not export registry/settings state. The active workspace is cleared after deletion.


`ProjectBackupLogic` exports only `<project>/.micoder` via macOS `ditto`; it is a project-data ZIP and cannot carry global registry/settings. `AppSettings` is Codable with injected UserDefaults load/save, so a versioned app backup can safely encode it. The registry is separately Codable/persisted by `ProjectRegistryLogic`; the next fix can define a pure `AppConfigurationBackupLogic` with schema version, settings, registry entries, and replace/merge semantics before wiring save/open panels.
