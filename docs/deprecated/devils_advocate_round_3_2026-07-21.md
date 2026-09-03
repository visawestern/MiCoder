# Devil's Advocate Review — Round 3 (2026-07-21)

## Full-chain audit: every document, every source file, every issue

**Starting state:** 671 tests, 131 suites — ALL PASSING ✅  
**Previous rounds:** Round 1 fixed 39 doc discrepancies, Round 2 fixed 9 code-level debts.

---

## Audit Method

Every line of every documentation file was re-read and cross-checked against source code. Every UI element from `UI_AUDIT_REPORT.md` was verified. Every feature from `FEATURE_REGISTRY.md` was traced through code. Every issue from Round 2's "remaining debts" was re-checked.

---

## All Issues Found (25 total)

### 🔴 CRITICAL (4)

| # | Issue | Location | Root Cause | Impact |
|---|-------|----------|------------|--------|
| C1 | **HTTP Proxy Save button does nothing** | `SettingsView.swift` | `Button("Save") {}` — empty closure | User clicks Save, nothing happens. Live-binding contradicts "Save" button |
| C2 | **Code theme pickers do nothing** | `SettingsView.swift` | `Button("GitHub Light") {}`, `Button("GitHub Dark") {}` — empty closures | Theme selection never applies |
| C3 | **Model/provider validation error ignored** | `ChatPanelView.swift` | `sendValidationError` returns string but result is never shown to user | User can click Send with no model selected and see no feedback |
| C4 | **API Key not using Keychain in detail view** | `SettingsView.swift` lines 744-758 | `custom.apiKey` (plain storage) read instead of `custom.getSecureAPIKey()`; Save writes to plain storage, not Keychain | Keys stored insecurely despite Keychain being set up |

### 🟡 MEDIUM (12)

| # | Issue | Location | Description |
|---|-------|----------|-------------|
| M1 | **Index new folders toggle — never saved** | `SettingsView.swift` | Local `@State`, no persistence, no effect |
| M2 | **Index repositories toggle — never saved** | `SettingsView.swift` | Same as M1 |
| M3 | **Usage time range — hardcoded** | `SettingsView.swift` | `isSelected: false`/`true` with empty `{}` actions; always "Last 30 days" |
| M4 | **Usage stat cards — hardcoded dummies** | `SettingsView.swift` | Values "23.2M", "11", "24" are static, not real |
| M5 | **Log level picker — not passed to connectToServe** | `SettingsView.swift` line 560 | `serveLogLevel` selected but never sent to `connectToServe(hostname:port:)` |
| M6 | **Requires API Key toggle — doesn't hide field** | `SettingsView.swift` line 1291 | Toggle exists but API Key field always visible regardless |
| M7 | **Branch action button — placeholder** | `BottomPanelView.swift` | `{ /* placeholder */ }` — nothing happens |
| M8 | **Review & Push — calls push even if commit fails** | `RightPanelView.swift` | No error check between commit and push |
| M9 | **variantMenuDisabledReason not surfaced** | `InputControls.swift` / `ProviderCapabilityGates.swift` | Reason computed but menu is hidden instead of disabled-with-reason |
| M10 | **No skill uninstall** | `AgentResourceInstaller.swift` | Only `installSkill`/`installMCPServer`, no uninstall API |
| M11 | **No test coverage for stop/abort flow (F51)** | `ChatPanelView.swift` | `stopGeneration` path is untested |
| M12 | **Load older messages cascade** | `ChatPanelView.swift` | `onAppear` triggers cascade loading all pages |

### 🟢 LOW (6)

| # | Issue | Location | Description |
|---|-------|----------|-------------|
| L1 | **Endpoint shown when disconnected** | `StatusBarView.swift` | Host:port always visible even when disconnected |
| L2 | **Session row uses .onTapGesture** | `SidebarView.swift` | No accessibility, keyboard doesn't work |
| L3 | **SSE message ID reconciliation orphan** | `ChatPanelView.swift` | `remove+re-append` creates orphan DB rows |
| L4 | **Git pull output unused** | `BottomPanelView.swift` | Output variable declared but never displayed |
| L5 | **Files toggle — showFiles unused** | `TopBarView.swift` | Toggle exists but no Files panel |
| L6 | **Undo UI ⌘Z not wired** | `UndoRedoManager.swift` | No keyboard shortcut for undo/redo |

### ⚠️ REGISTRY GAPS (3 from Round 2)

| # | Feature | Status | Description |
|---|---------|--------|-------------|
| G1 | F44 — ACP Protocol | ⚠️ | UI toggle exists, no ACP client |
| G2 | F58 — Workspace Overview | ⚠️ | Limited sorting/filtering |
| G3 | F59 — Notifications | ⚠️ | No real notification system |

---

## Fix Plan (TDD — Red, Green, Refactor)

Each fix follows: failing test → implementation → `swift test` → verify.

### Round 3 Fix Order

1. 🔴 **C1:** HTTP Proxy Save — make Save button work (validate URL, save to UserDefaults) 
2. 🔴 **C2:** Code theme pickers — wire actions to `appState.updateSettings`
3. 🔴 **C3:** Model/provider validation error — show as inline warning in chat
4. 🔴 **C4:** API Key → Keychain in detail view
5. 🟡 **M1-M2:** Index toggles — persist to UserDefaults
6. 🟡 **M3-M4:** Usage stats — wire to real data or show "coming soon"
7. 🟡 **M5:** Log level — pass to connectToServe
8. 🟡 **M6:** Requires API Key toggle — link to field visibility
9. 🟡 **M7:** Branch action button — wire to branch operation
10. 🟡 **M8:** Review & Push — add error guard
11. 🟡 **M9:** variantMenuDisabledReason — surface in UI
12. 🟡 **M10:** Skill uninstall — implement
13. 🟡 **M11:** Stop/abort flow test coverage
14. 🟢 **L1-L6:** Low-priority fixes

---

## Verification Gate

After each fix:
- `swift build` succeeds
- `swift test` — all tests pass (including new ones)
- Chain trace confirms the fix works end-to-end
