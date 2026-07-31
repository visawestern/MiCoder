# Devil's Advocate — Round 9: Web model discovery (2026-07-31)

**Question:** "почему модели из web (для всех веб моделей) пишутся старые или
захардкоженные а не определяются из веб страницы динамически?"

**Method:** devil's-advocate read of every web-provider file, plus RED tests
pinning each defect.

---

## 0. Executive verdict

Discovery **existed** (`WebModelListParser` + a call site in `runWebChatTurn`)
but was effectively **inactive in normal use**. Four independent defects meant
the picker showed hardcoded `vendor.defaultModels` far more often than real
page data. All four are now fixed and pinned by
`MiCoder/Tests/WebModelDiscoveryTests.swift` (8 tests, all green).

---

## 1. The four defects (each verified)

| ID | Defect | Why it caused hardcoded/stale models | Fix |
|----|--------|--------------------------------------|-----|
| **A** | Discovery ran **only on send** (inside `runWebChatTurn`), never on connect/login. Until the first message was sent, `discoveredModels` was empty → UI fell back to defaults. | Picker showed `k2/k2-thinking/k1.5` etc. until you'd sent at least one message. | `WebModelDiscovery.canRefresh` + `refreshModels(for:)` invoked from `WebProvidersSection.persistCookies` right after login — before the first send. |
| **B** | The dropdown selector was **hardcoded in the view** (`"button[class*='model'], div[class*='model-select'], …"`), ignoring the per-vendor selectors in `web_providers_catalog.json`. | A site redesign (or a vendor with a non-generic selector, e.g. ChatGPT's `data-testid='model-switcher'`) made discovery find nothing. | Selector now comes from `WebProviderCatalog.loadBundled().selectors(for: vendor.id)`. The view uses the catalog selector only. |
| **C** | A **failed discovery silently fell back** to `vendor.defaultModels` — no signal that the real list hadn't been read. | Stale defaults looked like a live list; nothing told the user the page failed to parse. | `WebProviderConnectivity.modelsOrError(for:discoveryAttempted:)` returns `.models` (real), `.fallbackDefaults` (only before first attempt) or `.discoveryFailed(message)` (after a failed attempt). |
| **D** | The dropdown was **never opened** before reading. Most model pickers are dynamic: the list is only populated after the dropdown is clicked, so `readText` of a closed menu returned empty/near-empty text. | Discovery returned `{}` even on a healthy page → falls back to defaults. | `WebModelDiscovery.discover` clicks the dropdown **before** reading; empty read returns nil (not a valid empty list). |

---

## 2. What stayed the same (correctly)

- `WebModelListParser` was already pure and correct — it just wasn't being used.
- `WebProviderConfig.discoveredModels` was already the storage for real models.
- The existing `WebModelListParserTests` still pass unchanged (8/8).

---

## 3. Files changed

| File | Change |
|------|--------|
| `MiCoder/Tests/WebModelDiscoveryTests.swift` | **new** — 8 red/green tests for A..D |
| `MiCoder/Sources/Services/WebModelDiscovery.swift` | **new** — `WebProviderCatalog`, `WebModelDiscovery`, `modelsOrError` |
| `MiCoder/Sources/Views/ChatPanelView.swift` | dropdown selector now from the catalog (B); removed the hardcoded selector literal |
| `MiCoder/Sources/Views/Components/WebProvidersSection.swift` | discovery runs right after cookies are captured (A) |

---

## 4. Test result

```
✔ Test run with 1586 tests in 217 suites passed
```

(The added web-discovery suite is included and all green; the full suite count
grew from 1578 → 1586.)

## 5. How to verify the fix manually

1. Settings → Web providers → **Log in** to a provider.
2. After the session is captured, the model picker should show the **real**
   model list from the page (e.g. `k2-0711-preview`, `k2-thinking-pro` if
   that's what the site exposes — not the hardcoded `k2/k2-thinking/k1.5`).
3. If the page can't be read (site redesign, captcha, not logged in), the UI
   must **say so** (via `discoveryFailed`) instead of silently showing the
   old defaults.
