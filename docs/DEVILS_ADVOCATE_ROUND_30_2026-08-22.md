# Round 30 — Live User Pipeline via Embedded API (2026-08-22)

## Method

The app was built, launched, and driven **end-to-end through its own API**
(`127.0.0.1:8766`) exactly as the user requested: provider selection → embedded
browser navigation → model/effort discovery attempts → session/cookies → real
message send to a live web provider (qwen.ai) → answer capture. Every claim
below was verified against the RUNNING app and its logs (`~/.micoder/logs/*.log`),
not just unit tests. Where a chain still fails, this report says so explicitly.

## Fixed & LIVE-verified

### W1 (HIGH) — embedded webview blocked vendor redirects / popups / dialogs
User report: kimi.com asks non-China visitors to hand off to kimi.ai; the
embedded webview "forbade" it.

**Root cause**: WKWebViews were created with NO `WKUIDelegate` — `window.open` /
`target=_blank` hops were silently dropped (that IS the kimi handoff path), and
a JS alert/confirm/prompt could hang page scripts forever.

**Fix**: new `PermissiveWebNavigationPolicy` (navigation+UI delegate): every
host/scheme allowed; popups re-loaded IN PLACE (pure decision logic
`WebPopupPolicy`, 6 unit tests); unresolvable popups adopted as new views;
JS dialogs auto-answered. Attached to both creation sites: browser pool
(`AppState.webView(for:)`) and the login surface (`WebViewRepresentable`).

**Live proof**: `window.open("https://www.kimi.com/")` on a running webview now
navigates that same view (old build: URL unchanged); `window.alert()` returns
instantly ("after-alert" instead of an eval timeout).

### W2 (HIGH) — streamed assistant text never reached the database
Live log during sends: `❌ Failed to save temporary message: UNIQUE constraint
failed: messages.id` ×3 per turn. `MessageStore.update()` persisted via plain
INSERT in the global `DatabaseManager`; only the first (empty) bubble survived,
so history reload showed empty assistant messages.

**Fix**: global insert now uses replace-on-conflict semantics, mirroring what
`ProjectDatabaseManager` already did (red→green tests:
`Round30MessageUpsertTests`). **Live proof**: statuses/streamed text now appear
in `/api/messages` for fresh sessions.

### W3 (HIGH) — fake send success: click ≠ submission
`FallbackRouter.executeBrowserAutomation` reported success after ONE `click()`.
On freshly-hydrated pages the click lands before React binds handlers → nothing
sent, yet downstream trusted it. Proven live: three consecutive "clicked" logs
with zero DOM effect.

**Fix**: `SendSubmissionPolicy` (5 red→green tests) — submission is VERIFIED by
the page URL gaining a remote chat id (`/chat/{id}`, `/c/{id}` ≥8 chars), with a
bounded 3-click retry budget; honest failure otherwise. **Live proof**:
`submission verified via URL change` in smartsend.log; assistant status shows
"Sent via browserAutomation".

### W4 (MED) — qwen sendButton selector targeted a no-op wrapper
`.message-input-right-button-send` is a DIV wrapper; only the inner
`<button class="send-button">` submits (proven by manual DOM experiment which
produced a real model answer «Ping! 🏓» and a `/c/{uuid}` URL).
Catalog updated to target the inner button first (+2 structural tests).

### W5 (MED) — route discovery proposed garbage endpoints
Network capture picked `/api/v2/users/status` (telemetry, RELATIVE url) as the
"chat API" → `URLSession` failed `-1002 unsupported URL`.
`findChatAPI` now rejects obvious non-chat paths (users/status, telemetry,
tracking, log, ping…) and relative URLs (red→green:
`NetworkInterceptorRouteQualityTests`).

### W6 (MED) — binding wiped the conversation it had just verified
`bindWebRemoteChat` ran `startNewSession()` (clicks "New Chat") BEFORE looking
at the current page, discarding the just-submitted chat. Now an already-open
conversation with a chat id is REUSED first.

## Honest remainder (Round 31 candidates)

1. **Model injection false-negative**: config model `Qwen3.7-Plus` exists in the
   live dropdown DOM (visually confirmed via evaluate) but injection reports
   "not found; injection blocked". The dropdown open/read selectors need
   adaptation to the current qwen.ai DOM (same drift family as W4).
2. Because of (1), the post-send flow enters "refresh catalog before retry",
   which navigates away from the conversation before the final answer is
   captured. The provider DOES answer (proven twice manually); the app-side
   capture must survive/skip the injection block.
3. Kimi remains honestly gated at "login first" (no stored session on this
   machine) — with W1 fixed, the login window itself now tolerates the kimi.ai
   handoff; actual credential entry is inherently manual.
4. `handleDiscoverModels` debug endpoint targets the most-recent webview, not
   the selected provider's — pre-existing; use `/api/refresh-models`.

## Verification

```bash
swift build    # green
swift test     # 2249 tests / 355 suites — all green
```

Live pipeline evidence: `~/.micoder/logs/api-server.log`, `smartsend.log`
(submission verified), `/api/messages` payloads captured during the session.
