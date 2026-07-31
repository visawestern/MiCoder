# Devil's Advocate — Round 8: "Sending a message does nothing" (2026-07-31)

**Reporter:** user on Intel MacBook (x86_64, macOS 26.0, Xcode 26.4.1, Swift 6.3.1)
**Symptom:** «посылаю сообщение — ни один провайдер не работает, не открывает чат,
ничего, и никакой ошибки обдумывания»
**Method:** manual chain-of-cause verification of the ENTIRE send chain
(button → `sendMessage()` → `sendDirectly()` → 5 provider branches), then TDD
(red tests → green), then a second devil's-advocate pass over the edge cases.

---

## 0. Executive verdict

The "nothing happens" symptom is a **cluster of 6 defects** in the send chain,
not one bug. The most damaging one — **P1** — is a UX dead-end: when no provider
is ready, the send button is disabled **silently**, so the user gets zero
feedback (no error, no hint, no "thinking" state). The helpful error strings
already existed in `SendReadinessLogic` but were never displayed because a
disabled button never invokes `onSend`.

All six problems are fixed and pinned by regression tests
(`MiCoder/Tests/SendChainRegressionTests.swift`, 19 tests).

---

## 1. The chain (verified line-by-line)

```
SendStopButton (.disabled(!canSend))              InputControls.swift:444
  → sendMessage()                                 ChatPanelView.swift:322
    → SendReadinessLogic.connectionValidationError  (message shown only if button enabled!)
    → SendReadinessLogic.sendValidationError
    → Task { sendDirectly() }                     ChatPanelView.swift:401
      → SendRouteResolver.route(...)              SendRouteResolver.swift:22
        → .openAICompatible  → DirectChatClient.send     (120 s timeout)
        → .web              → runWebChatTurn             (WKWebView)
        → .acp              → ACPClient.sendChatCompletion
        → .mimoServe        → createSession + sendMessage + SSE
        → .none             → FALLS THROUGH into serve ✗ (P3)
      → assistant bubble placeholder (isStreaming) with NO text ✗ (P4)
```

---

## 2. Problems found (devil's-advocate pass)

| ID | Sev | Problem | Fix |
|----|-----|---------|-----|
| P1 | 🔴 | Send button disabled with **zero feedback**. `canSend` requires model + provider + ready connection; on a fresh app (no server/providers) the button is gray and clicking does nothing — no error, no hint. The exact reason exists in `SendReadinessLogic` but is never shown. | New `SendReadinessReason.reason(...)` pure function + UI: red icon, tooltip, and an inline error line above the toolbar. |
| P2 | 🔴 | Web path swallows failures. `try? await bridge.navigate(...)` / `setCookies(...)` silently dropped; `.loggedOut`, `.iterationLimitReached`, `.captchaDetected` mapped to `.status` → written to transient `streamingText` → wiped by `finishWebTurn()` → empty assistant bubble, no error. | New `WebChatTurnMutation` maps every event to a bubble mutation; navigation/cookie errors surface into the message; `finishWebTurn()` never wipes content. |
| P3 | 🟠 | `SendRouteResolver.route == .none` has **no branch** in `sendDirectly` — falls through into the serve branch (`createSession` on a dead server). Web route with a deleted config did the same. | New `SendRouteGuard.errorMessage(for:serverConnected:)` + `webConfigMissingMessage(configID:)`; `sendDirectly` now handles both explicitly with a clear message. |
| P4 | 🟠 | No visible waiting/thinking state. OpenAI-compatible path showed an empty streaming bubble for up to 120 s; web path showed nothing while the page loaded. | `SendStatusText.waitingForResponse/thinkingPlaceholder` shown in the bubble while awaiting; web path seeds "Thinking…" after navigation. |
| P5 | 🟡 | `MessageQueue.processNext()` only runs when `isLoading` flips false; a stuck `isLoading` silently drops queued messages. | Not fixed in code (low incidence); mitigated by P1/P2/P4 (no more invisible hangs). Documented. |
| P6 | 🟡 | `SSEClient` timeouts are `TimeInterval(Int.max)`; `MimoServeClient` request timeout 300 s. A half-dead server can hold a send for 5 min. | Not changed (would risk aborting real long generations). Documented. |

**Bonus fix:** `.gitignore` still ignored the old bundle name `MiMoMacOS.app/`
instead of `MiCoder.app/` — the freshly built bundle was untracked.

---

## 3. TDD evidence

### Round 1 — RED (18 failing assertions on 16 tests)
`SendChainRegressionTests.swift` written first against stub implementations
(stubs returned nil / .none / ""). Run:
```
✘ Test run with 16 tests in 1 suite failed with 18 issues
```
Every P1–P4 assertion failed exactly as expected.

### Round 1 — GREEN
Real implementations wired into `sendDirectly()` + both input cards:
```
✔ Test run with 16 tests in 1 suite passed
✔ Test run with 1575 tests in 216 suites passed
```

### Round 2 (edge cases) — RED → GREEN
3 new tests for: blank model answer (`.answer("")` produced an empty finished
bubble), waiting text with empty model id (double-space bug), deleted web
config falling into serve.
```
✘ 3 tests failed (4 issues)  →  ✔ 19 tests passed
✔ Test run with 1578 tests in 216 suites passed
```

---

## 4. Files changed

| File | Change |
|------|--------|
| `MiCoder/Tests/SendChainRegressionTests.swift` | **new** — 19 red/green regression tests (P1–P4 + Round-2 edges) |
| `MiCoder/Sources/Services/SendReadinessLogic.swift` | `SendReadinessReason.reason(...)` |
| `MiCoder/Sources/Services/SendRouteResolver.swift` | `SendRouteGuard.errorMessage` + `webConfigMissingMessage` |
| `MiCoder/Sources/Services/WebChatEventPresenter.swift` | `WebChatTurnMutation` (status/answer/error/captcha → bubble mutation; blank answer surfaced) |
| `MiCoder/Sources/Services/SessionSendLogic.swift` | `SendStatusText` (waiting/thinking, graceful empty-model handling) |
| `MiCoder/Sources/Views/ChatPanelView.swift` | `.none` guard; web-config-missing guard; web navigation/cookie errors surfaced; status persists into bubble; thinking placeholder on both paths |
| `MiCoder/Sources/Views/Components/InputControls.swift` | send button: red icon + `.help(reason)` |
| `MiCoder/Sources/Views/Components/InputViews.swift` | both input cards show the readiness reason line above the toolbar |
| `MiCoder/Tests/ProjectDatabaseManagerTests.swift` | made pool-identity test resistant to cross-suite `evictAll()` races (was flaky) |
| `.gitignore` | ignore `MiCoder.app/` (stale `MiMoMacOS.app/`) |
| `MiCoder/Resources/Info.plist` | fixed executable/id to `MiCoder` (from previous session) |

---

## 5. Final state

- `swift build` — clean.
- `swift test` — **1578 tests in 216 suites, all passing**.
- The "nothing happens" scenario now shows **exactly why**:
  - no provider/model → red hint "Select a model before sending." /
    "No provider is ready. Connect a local agent, add a custom provider…"
  - provider answering → "Waiting for … to respond…" / "Thinking… (model)"
  - web session expired / captcha / iteration limit → visible in the bubble
  - deleted web config / dead server → explicit message, never a silent fall-through

## 6. Remaining risks (accepted, documented)

- **P5** message-queue processing depends on `isLoading` flipping to false; a
  provider that never returns AND never throws would still hold the send. The
  120 s `DirectChatClient` timeout and the web driver's 2 min poll cap bound
  this in practice.
- **P6** the serve `sendMessage` request timeout is 300 s; long generations
  legitimately need it, but a half-dead server can appear frozen for 5 min.
  Consider a user-facing "still working…" heartbeat in a future round.
