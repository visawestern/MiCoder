# Activity 29 — Architecture Analysis

Источники: Полный обзор кодовой базы

## Critical Architecture Defects

### ARCH-01: God Object — AppState (CRITICAL)

**File:** `MiCoder/Sources/App/MiCoderApp.swift` (2265 lines)

`AppState` is simultaneously responsible for:
- Server connection management
- Provider management (selection, loading, testing)
- Model selection and variant management
- Sidebar state (workspaces, sessions, navigation)
- Navigation history (with NSLock)
- Git operations (status, branches, commit, push)
- Web browser management (pool, sessions, cookies)
- Session lifecycle (creation, selection, archiving)
- Database orchestration
- Settings persistence
- Notification dispatch
- Input dropdown context
- Project file index watching
- Status bar state

**Violation:** Single Responsibility Principle. Every feature adds more coupling.

**Impact:** Any change risks unintended side effects across unrelated features. Testing requires mocking the entire app state.

**Recommendation:** Decompose into domain-specific state objects (ProviderState, SidebarState, GitState, BrowserState, SessionState) with a thin coordinator.

---

### ARCH-02: Global Mutable Singleton (CRITICAL)

**File:** `MiCoder/Sources/App/MiCoderApp.swift:9`

```swift
var __miCoderAppState: AppState?
```

- No synchronization
- Set in `onAppear`, read from API server and background tasks
- Any thread can read/write without coordination

**Impact:** Data races, undefined behavior in concurrent access.

**Recommendation:** Use actor isolation or `@MainActor` property wrapper with proper synchronization.

---

### ARCH-03: `lastAccessedAt` Data Race (HIGH)

**File:** `MiCoder/Sources/Services/ProjectDatabaseManager.swift:106,218,316`

- `lastAccessedAt` is mutated by `touch()` from both the pool queue and direct method calls
- The `queue` DispatchQueue is created but never used (dead code)

**Impact:** Data race on `lastAccessedAt` property.

**Recommendation:** Remove dead queue, protect `lastAccessedAt` with pool queue or lock.

---

### ARCH-04: `hasAPIKey` Broken After Keychain Migration (HIGH)

**File:** `MiCoder/Sources/Services/SendReadinessLogic.swift:26`

After Keychain migration:
- `provider.apiKey` is cleared to `""` (line 1004 in MiCoderApp.swift)
- `hasAPIKey` checks `$0.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty`
- Result: migrated providers appear as "no API key"

**Impact:** Providers migrated to Keychain appear as not having an API key.

**Recommendation:** Check Keychain directly or use `requiresAPIKey` flag as the source of truth.

---

### ARCH-05: SQL Injection Surface (MEDIUM)

**File:** `MiCoder/Sources/Services/ProjectDatabaseManager.swift:499-506`

```swift
private func addColumnIfMissing(table: String, column: String, definition: String) throws {
    let existingColumns = try SQLiteSafeQuery.rows(
        db.prepare("PRAGMA table_info(\(table))")
    )
    try db.execute("ALTER TABLE \(table) ADD COLUMN \(column) \(definition)")
}
```

String interpolation in SQL. Currently safe (callers pass literals), but the function signature accepts any String.

**Recommendation:** Validate table/column names against allowlist or use parameterized queries.

---

### ARCH-06: Symlink Path Traversal (MEDIUM)

**File:** `MiCoder/Sources/Services/WebToolProtocolEmulator.swift:390-398`

`isPathInsideRoot` doesn't resolve symlinks. A symlink inside project root could point to `/etc/passwd`.

**Recommendation:** Use `FileManager.default.realPathForURL` before path comparison.

---

### ARCH-07: Silent Error Swallowing (MEDIUM)

**File:** Multiple locations in `AppState+Database.swift`, `DatabaseBridge.swift`

15+ sites use `try?` to silently swallow errors:
- `archiveOldSessions`, `deleteArchivedSessions`, `deleteSessionsOlderThan`
- `resetStorage`, `resetDatabase`, `vacuumDatabase`, `vacuumProject`
- `loadProjects`, `upsertProject`, `markProjectAsOpened`

**Impact:** Failures are invisible to users and developers.

**Recommendation:** Add structured error logging and user-facing error messages for critical operations.

---

### ARCH-08: Dead DispatchQueue (LOW)

**File:** `MiCoder/Sources/Services/ProjectDatabaseManager.swift:218`

```swift
self.queue = DispatchQueue(label: "com.mimo.projectdb.\(projectPath.hashValue)", qos: .userInitiated)
```

Created but never used. All operations go through `self.db` (SQLite.Connection).

**Recommendation:** Remove dead code.

---

### ARCH-09: DRY Violation in Part Conversion (LOW)

**File:** `MiCoder/Sources/Services/DatabaseBridge.swift:382-440`

`convertPartRecord` and `convertProjectPartRecord` are 100% identical implementations.

**Recommendation:** Extract shared conversion logic.

---

## SDLC Analysis

### Current SDLC Flow

```
Intent → Specification → Code → Review → Tests → Release → Validation
```

### Bottleneck Analysis

| Stage | Current State | AI Impact | Agentic SDLC |
|---|---|---|---|
| Code | Manual coding | AI accelerates 10x | AI generates code |
| Review | Manual code review | AI assists | AI reviews autonomously |
| Tests | Manual test writing | AI generates tests | AI generates + runs tests |
| Release | Manual release | Manual | AI automates |
| Validation | Post-release monitoring | Manual | AI monitors + validates |

### Key Insight

AI in IDE shifts bottleneck from Code to Review + Tests. Full Agentic SDLC should form a closed loop:
```
Intent → Specification → Code → Review → Tests → Release → Validation
```

The critical loop is **Intent correctness + independent Validation**, not code generation speed.

### Current Gaps

1. **Specification → Code:** No automated spec validation before coding
2. **Code → Review:** No automated review gate (relying on manual review)
3. **Tests → Release:** No automated test-gated release
4. **Release → Validation:** No automated post-release monitoring
5. **Validation → Intent:** No feedback loop from production to requirements
