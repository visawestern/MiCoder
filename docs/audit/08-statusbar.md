# Activity 08 — Status Bar

Источники: `Sources/Views/StatusBarView.swift`, `Sources/Services/StatusBarModelLogic.swift`, `Sources/Services/ProviderConnectionStatusLogic.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Connection dot | Green/red circle | `appState.selectedProviderConnected` | 95/100 | PASS |
| 2 | Connected/Disconnected text | Label | Connection state | 95/100 | PASS |
| 3 | Model name | CPU icon + text | `appState.effectiveSelectedModel()` | 95/100 | PASS |
| 4 | Streaming indicator | ProgressView + "Generating…" | When streaming | 95/100 | PASS |
| 5 | Loading indicator | ProgressView + "Processing…" | When loading | 95/100 | PASS |
| 6 | Idle state | "Idle" text | Neither streaming nor loading | 95/100 | PASS |
| 7 | Endpoint label | Network icon + URL | `ProviderConnectionStatusLogic.endpointLabel` | 90/100 | PASS |

## User Story

As a user, I see the current connection status, active model, and streaming/loading state in the status bar. The endpoint label shows the active provider URL.
