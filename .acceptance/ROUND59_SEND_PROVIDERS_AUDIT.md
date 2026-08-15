# Round 59 — Activity 14 Send Providers Audit Findings

## Confirmed defects fixed

1. `SendReadinessLogic.connectionValidationError` returned success as soon as MiMo Serve was connected, before checking the selected route. An expired web provider, unavailable direct route, or unknown provider could therefore pass preflight. `SendProviderReadinessLogic` now checks route identity first and only uses Serve health for known Serve provider IDs.
2. Model preflight and several composer consumers used legacy `AppState.selectedModel`; web and Auto Free may store the routed model in `effectiveSelectedModel()`. ChatPanel, centered and bottom composers, model menus, parameter controls, capability gates, route construction, and API metadata now use effective-model precedence.
3. The centered and bottom composer readiness paths did not pass web connectivity or server provider IDs, so disabled-state UI could disagree with the actual send path. Both now pass route-specific readiness inputs.
4. External API state/send acknowledgements reported the blank legacy model for web/Auto Free. `SendAPIResponseLogic` now reports the effective model.
5. Direct OpenAI-compatible parsing accepted whitespace-only assistant content as a successful response. The shared response contract rejects blank content; DirectChatClient emits a typed empty-response error.
6. ACP send mapped a missing/blank content field to a finished empty assistant bubble. ChatPanel now throws an explicit ACP empty-response error.
7. `runWebChatTurn` unconditionally journaled `send_completed` after `WebChatDriver.runTurn`, including error, logout, captcha, iteration-limit, injection-failure, and blank-final outcomes. `WebSendCompletionLogic` plus `WebChatCompletionSignal` now allow completion journaling only after a verified visible `.final` event, including after the bounded refresh/retry.
8. `refreshProviderConnectivity` treated Serve health as connectivity for every provider. It now short-circuits only for provider IDs in the Serve catalog; web/local/custom paths probe their own state. Custom whitespace-only API keys fail closed, and web config reads use the same defaults store as status.

## Source-traced chains with no additional confirmed defect

MiCoder Auto Free carries effective model, history, attachments, system prompt, live catalog refresh, locked-model behavior, five-failure failover, and visible switch notifications through `MiCoderAutoFreeStore.streamChat`. Web routing creates one local project/chat/provider mapping, verifies the remote host and UUID, restores cookies/localStorage, injects exact model and supported effort before typing, retries one same-page catalog refresh, gates mutations for approval, and records browser action metadata. Local/custom routes build OpenAI-compatible requests with model, history, attachments, parameters, and typed transport/HTTP/decode errors. ACP and Serve preserve provider-specific messages and session IDs.

## Verification planned

The Foundation harness currently passes 189 tests. Modified production files still require Swift parser validation, adversarial source checks, canonical Activity 14 documentation, registry/report updates, diff hygiene, and commit/push. SwiftUI/AppKit/WebKit, real provider accounts, network responses, clipboard, and macOS SQLite remain UNVERIFIED in the Linux sandbox.
