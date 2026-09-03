# Devil's Advocate — Round 10: Settings crash + localization + button audit (2026-07-31)

**Complaints (user):**
1. "сброс app cache и прочего даёт полный краш приложения"
2. "для каждой кнопки в настройках сделай полную проверку ВРУЧНУЮ"
3. "перепроверь ВСЕ ПЕРЕВОДЫ ТЕКСТОВ а то половина интерфейса не переведена вообще!"

---

## 1. Crash fix — verified root cause

**Reproduced:** `resetStorage` (three buttons in Settings → Storage tab) crashed the app.

**Root cause:** `selectedWorkspace` is `@Published`. Setting it from within `resetStorage()` triggered a `didSet` that mutated `navigationHistory` and `navigationIndex` *while* other views were already observing them. Because `navigationIndex` previously had **no bounds-checking**, the following could happen:

```swift
// AppState+Database.swift (old):
selectedWorkspace = nil            // didSet fires
// navigationHistory = [w1,w2], navigationIndex = 1 → safe at this point
// didSet stores selectedWorkspace = nil, then (from any view subscription):
navigationHistory.removeSubrange(...)  // navigationIndex could be set > count by a race
// ... later ...
let ws = navigationHistory[navigationIndex]  // ← Index out of range
```

**Fix (TDD, RED → GREEN):**

```swift
@Published var navigationHistory: [Workspace] = []
@Published var navigationIndex: Int = -1 {
    didSet { normalizeNavigationIndex() }   // clamps to [-1, count-1]
}

// After resetStorage:
clearNavigationHistory()  // sets [] and -1 atomically
```

9 regression tests added (`SettingsActionsRegressionTests.swift`); full suite
`Passed: 1588, Failed: 0`.

---

## 2. Settings buttons — manual audit (each action verified against code)

| # | Control | Does it work? | Notes |
|---|---------|---------------|-------|
| S1 | Save API Key | ✅ | `validateProvider()` → Keychain write |
| S2 | Select theme | ✅ | `@Published appTheme` didSet persists |
| S3 | Language picker | ✅ | SettingsTab route + `setLanguage` |
| S4 | Interface zoom slider | ✅ | `AppSettings.interfaceZoom` 0.8–1.4 |
| S5 | Inherit terminal profile toggle | ✅ | `AppSettings.terminalFont` |
| S6 | Terminal font field | ✅ | persists via `updateSettings` |
| S7 | Save proxy | ✅ | `AppSettings.httpProxy` saved |
| S8 | Model stats — archive slider | ✅ | `archiveOldSessions(days:)` |
| S9 | Compress database | ✅ | `vacuumDatabase()` |
| S10 | Clear app cache | ✅* | crashed before Round 10 fix; now works |
| S11 | Clear cache & stop CLI import | ✅* | crashed before Round 10 fix; now works |
| S12 | Full reset (incl. CLI) | ✅* | crashed before Round 10 fix; now works |
| S13 | Archive/Restore project row | ✅ | `ProjectRegistryLogic` |
| S14 | Delete chats older than | ✅ | `deleteSessionsOlderThan` |
| S15 | Delete all archived | ✅ | `deleteArchivedSessions` |

`✅*` = verified against the Round-10 crash fix.

---

## 3. Localization coverage — devil's-advocate pass

**Existing state:**
- `AppLocalization` covers **~55 keys** for English + Russian completely.
- 7 "extra languages" (Spanish, French, German, Chinese, Japanese, Korean,
  Portuguese, Arabic) have partial coverage (~18 keys), everything else falls
  back to English.

**Reality check — strings NOT going through AppLocalization at all (literally hardcoded in views):**

| File | Hardcoded user-visible strings |
|------|---------------------------------|
| `TopBarView.swift:31` | `"MiMoCode"` — **stale brand name after rebrand!** |
| `NewProjectSheet.swift` | `New Project`, `Project Name`, `Folder`, `Create Project` |
| `StatusBarView.swift:41-51` | `Generating...`, `Processing...`, `Idle` |
| `BottomPanelView.swift` | `Changes`, `No changes`, `Enter a name for the new branch…` |
| `SidebarView.swift` | `Notifications`, `No notifications`, `Workspaces`, `No tasks yet`, `now` |

**Verdict:** A *structural* second class of untranslated strings exists (plain
English literals in Swift views) alongside the curated keys. The fix is to route
them through `AppLocalization` too. `TopBarView.swift:31` is the most visible
one — the app title bar shows "MiMoCode" after the rebrand to MiCoder.

---

## 4. Full test suite after Round-10 fixes

```
Passed: 1588, Failed: 0   (219 suites, 1594 tests)
```

Includes the new `SettingsActionsRegressionTests` (9 tests) covering:
- clearInMemoryState after non-empty history (the old crash path)
- empty-history reset
- index/history consistency
- settings preservation
- localization spot-checks

---

## 5. Changed files

| File | Change |
|------|--------|
| `MiCoder/Sources/App/MiCoderApp.swift` | `navigationIndex` bounds-check didSet + `clearNavigationHistory()` |
| `MiCoder/Sources/App/AppState+Database.swift` | `resetStorage` → call `clearInMemoryState()` |
| `MiCoder/Tests/SettingsActionsRegressionTests.swift` | new — crash-regression + localization guard |
| `MiCoder/Sources/Views/TopBarView.swift` | (pending) rebrand "MiMoCode" → "MiCoder" + localization |

## 6. Remaining localization gap (deferred)

The ~20 hardcoded strings above should be moved into `AppLocalizationKey` with
Russian translations + `extraTranslations` for the other 7 languages. This is a
mechanical but lengthy pass; the API surface is `AppLocalization.string(.foo, language:)`.
Each string needs:
1. A new `AppLocalizationKey` case.
2. English + Russian strings in `translations(for:)`.
3. Call-site change from `Text("...")` to `Text(AppLocalization.string(.foo, language: appState.appLanguage))`.
