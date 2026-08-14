# Round 54 Web Login audit findings

## Confirmed defects fixed

1. `WebProviderLoginView.capture()` enabled capture after any page URL and persisted whatever cookie snapshot WebKit returned. An empty snapshot therefore passed through `onCookies`, created a named `cookies.json` with no cookies, and gave the user no actionable login feedback. `WebLoginCaptureLogic` now rejects empty snapshots, shows `No authenticated cookies were found. Log in before capturing the session.`, and only the parent callback can activate a session after successful disk persistence. Parent persistence no longer uses `try?`; failures create a red NotificationService error and do not update activeSessionID or trigger discovery.

2. `WebProviderCard` displayed `MiCoder Auto Free will detect models after login` and `MiCoder Auto Free detected N models` in the normal provider card. That text falsely attributed the built-in DOM detector to the separate optional Auto Free-assisted detection route. `WebDetectionStatusLogic` now names the built-in detector as MiCoder, the header says `Built-in browser detection`, and the AI button explicitly says `Ask MiCoder Auto Free`.

## Verified chains

- Add Kimi/Qwen/ChatGPT guards duplicate vendor config and persists through WebProviderStore.
- Login/change-login chooses default or named session ID and name, opens embedded WKWebView, captures cookies, then persists provider/session metadata.
- Provider card named-session menu maps active ID/name and routes future browser keys by provider+project+chat+active session.
- Remove deletes provider config, all saved sessions, remote chat mappings, and clears AppState selection when active.
- Built-in detection reads the vendor selector, expands nested menus, profiles effort/parameters, persists only live selectable DOM candidates.
- AI detection is explicitly separate, uses MiCoder Auto Free, stores candidates as non-selectable until built-in DOM verification.
- AppState refresh and ChatPanel send restore saved cookies into the isolated browser bridge before navigation; browser instances are keyed by project/chat/provider/session and capped at 100.
- `WebSessionManager` persists cookie and localStorage fields independently per named session; runtime localStorage injection is not implemented and remains a WebKit/provider-specific boundary.

## Evidence

WEB-LOGIN-11 targeted harness: 4/4 passed after red compile failures.
WEB-LOGIN-12 targeted harness: 2/2 passed after red compile failure.
Modified web-login Swift parser check: passed.
Full Foundation harness and source checks remain to be run after this round's final documentation update.
