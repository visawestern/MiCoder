# Round 60 — STO-06/STO-07 index audit findings

`ProjectFileIndexLogic` and `ProjectFileScanner` implement deterministic exclusions, size limits, hashing, language detection, recursive scan, and incremental delta calculation. They are Foundation-testable and contain no persistence or FSEvents subscription themselves. The source comments explicitly describe SQLite/FSEvents as an app-layer wrapper, but repository-wide source search found no consumer for `ProjectFileIndexLogic`, `ProjectIndexStatus`, or `FileIndexRecord` outside scanner/cache/tests. This indicates the scanner/index decision layer may be dead code.

The next required trace is `ProjectFilesCacheLogic`, `IndexingSettingsView`, and `SettingsView`’s indexing tab to determine whether the visible settings actions only maintain an in-memory 30-second cache and whether the promised persistent file index/FSEvents path is absent or merely in another abstraction.


`ProjectFilesCacheLogic` is a 30-second in-memory TTL cache used only by `AppState.inputDropdownContext()` to populate `@` file suggestions. A rescan happens synchronously when the dropdown context is requested and the cache is missing, path changes, or TTL expires. There is no persistence of `FileIndexRecord` data, no SQLite `file_index` table, and no FSEvents subscription.

`IndexingSettingsView` exposes `indexNewFolders` and `indexRepositories` toggles, but their setters only call `appState.updateSettings`; no source consumer was found for those settings in the scanner/cache path. Therefore the visible indexing settings currently promise automatic indexing while only persisting preferences. This is a confirmed UX/logical defect for the earliest remaining stories, not merely a runtime limitation.


## Final Round 60 evidence

The red suite failed before the new contracts existed. After implementation, `ProjectFileIndexPersistenceLogicTests` passed 3/3 and the full Foundation harness passed 192/192. Swift parser validation passed for all changed index/AppState/settings files. `STO-06` remains PARTIAL because JSON persistence is not SQLite/FTS and the macOS runtime is unavailable. `STO-07` remains MISSING because no FSEvents watcher exists. Implementation quality: 96/100. Task adherence: 100/100. Target runtime confidence: 0/100.
