# Round 53 settings audit findings

## Confirmed defects fixed in this round

1. `LocalProviderRow.selectModel` was an empty no-op and `isSelected` returned `config.models.contains(model)`, making every catalog chip appear selected. The row had no callback to AppState. `LocalModelSelectionLogic` now scopes visual selection to active provider and selected model, validates catalog membership, and the row selects the provider then model through AppState. The parent reloads the persisted local config after refresh to avoid stale-catalog rejection.

2. `AddProviderSheet` and `AppState.testProvider` constructed `"\(url)/models"` from raw input. Whitespace, trailing slashes, missing scheme, or query/fragment values could save malformed endpoints or probe a wrong path. `ProviderEndpointLogic` now validates HTTP(S) host URLs, removes trailing slashes, and builds `/models` safely. Add/test buttons use the normalized value, the form shows invalid URL guidance, and saved name/key/URL values are trimmed.

3. `AddProviderSheet` only reset `requiresAPIKey` when switching to OpenCode Zen; switching away left the previous false value, so a provider that requires a key could be saved as optional. `ProviderEndpointLogic.defaultRequiresAPIKey` is applied on every type change, with no-key defaults for Ollama, ACP and OpenCode Zen.

4. `PluginsSettingsView` displayed enabled/disabled status but had no action despite its subtitle promising enable/disable management. The row now exposes an Enable/Disable button, persists through the existing `PluginEntry.togglePlugin`, and reloads `AgentResourcesLoader` state. `PluginToggleLogic` makes the disabled-ID mutation testable.

## Source-traced settings chains

- General theme/language/zoom/terminal/proxy/input-dropdown controls mutate AppState settings; settings has didSet persistence. Direct nested bindings were not changed without a reproducible failure.
- Skills and MCP use the shared catalog installer and registry managers. Installed rows expose enable/disable and destructive remove with confirmation. MCP health uses cache plus max-three concurrent probes; runtime probes remain macOS/external-runtime limited.
- Commands expose create/edit/delete and enable/disable; `CommandFileManager` persistence is already covered by tests.
- Storage has separate confirmations for delete-old, delete-archived, reset, and typed project deletion. Archive/restore/relink/delete mutations call the Round 50 project-registry refresh hook; native panels and database/backup runtime remain macOS-only.
- Usage filters and aggregation are pure logic/UI consumers; cost/project aggregation remains documented PARTIAL.

## Evidence status

SET-11 targeted harness: 3/3 passed after red compile failure.
SET-12 targeted harness: 3/3 passed after red compile failure.
SET-13 targeted harness: 3/3 passed after red compile failure.
Modified macOS settings source parser check: passed.
Full Foundation harness and source checks remain to be run after the complete Round 53 patch.
