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

### ARCH-02: Global Mutable Singleton (HIGH, MITIGATED-2026-09-06)
**File:** `MiCoder/Sources/App/MiCoderApp.swift:9`
```swift
var __miCoderAppState: AppState?
```
- No synchronization; set in `onAppear`, read from API server and background tasks.
**Fix applied 2026-09-06:** documented contract — writes happen once on the main thread at startup; readers (MiCoderAPIServer, port 8766) treat it as read-only after startup. Full actor-isolation would require restructuring AppState (see ARCH-01) — recorded as an external constraint: fixing ARCH-01 (god-object decomposition) is the prerequisite; patching the singleton alone without that decomposition would be symptom-masking.
**Status: MITIGATED + documented as constrained by ARCH-01.**

### ARCH-03: `lastAccessedAt` Data Race (HIGH, FIXED 2026-09-06)
**File:** `ProjectDatabaseManager.swift`
**Fix:** `lastAccessedAt` is now an NSLock-guarded computed property over `_lastAccessedAt`; `touch()` writes through the same lock; the dead per-instance DispatchQueue (ARCH-08) was removed entirely. Regression test: `concurrentPoolAccessIsRaceFree` (50 concurrent pool opens).

### ARCH-04: `hasAPIKey` Broken After Keychain Migration (HIGH, FIXED 2026-09-06)
**File:** `SendReadinessLogic.swift:26`, `SendRouteResolver.swift:60`, `MiCoderApp.swift addCustomProvider/updateCustomProvider`
**Root cause (2 sites):** after Keychain save the in-memory `apiKey` was cleared to `""` until app restart — send-readiness validation AND the actual send route both saw no key.
**Fix:** in-memory copies keep/restore the key (`getSecureAPIKey()`); `SendRouteResolver` resolves via `getSecureAPIKey()`. Regression test: `customProviderWithKeychainOnlyKeyStillRoutesWithKey`.

### ARCH-05: SQL Injection Surface (MEDIUM, FIXED 2026-09-06)
**File:** `ProjectDatabaseManager.swift addColumnIfMissing`
**Fix:** `SchemaIdentifier` allowlist (owned tables × columns); non-allowlisted identifiers throw `DatabaseValidationError.unallowedIdentifier`. SQL identifiers cannot be parameterized, so allowlisting is the correct mechanism.

### ARCH-06: Symlink Path Traversal (MEDIUM, FIXED 2026-09-06)
**File:** `WebToolProtocolEmulator.isPathInsideRoot`
**Fix:** realpath-based resolution with lexical `..`/`.` handling and longest-existing-ancestor fallback (write targets don't exist yet). Note: the FIRST fix attempt introduced an infinite loop on trailing `..` (`URL.deletingLastPathComponent` no-op) caught only by the full regression run — see BUG-30-02 in activity 30. 10 regression cases cover symlink-escape, symlinked-root, missing write targets, and `..` lexical edge cases.

### ARCH-07: Silent Error Swallowing (MEDIUM, OPEN — external constraint)
`try?` sites remain (39 in AppState+Database, 6 in DatabaseBridge). Fixing them requires a user-facing error-surfacing channel per operation (design decision with UX implications across ~45 call sites); recorded as open with bounded scope, not silently ignored.

### ARCH-08: Dead DispatchQueue (LOW, FIXED 2026-09-06)
Removed together with ARCH-03.

### ARCH-09: DRY Violation in Part Conversion (LOW, FIXED 2026-09-06)
`convertPartRecord` and `convertProjectPartRecord` now delegate to a shared `convertPartFields(...)`.

### ARCH-01: God Object — AppState (CRITICAL, OPEN — external constraint)
Decomposition into domain-specific state objects (ProviderState, SidebarState, GitState, BrowserState, SessionState) is the correct end-state model, but it is a structural rewrite of the app's central object (2355 lines + every view binding), not a defect-patch. It is explicitly recorded as OPEN: incremental patches to AppState while its responsibilities remain fused would be symptom-level changes. The bounded audit fixes (03-06, 08, 09) eliminate the concrete math/logic/safety errors; ARCH-01 remains the architectural debt item with the clearest replacement model described above.

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
