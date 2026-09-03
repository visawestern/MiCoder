# Provider cascade API probe

Date: 2026-06-20  
Source: `MimoServeClient` routes, unit-test fixtures, optional live run with `MIMO_LIVE_TESTS=1`.

## Endpoints used by the macOS app

| Method | Path | Client | Purpose |
|--------|------|--------|---------|
| GET | `/config/providers` | `MimoServeClient.providers()` | Server provider list + per-model metadata |
| GET | `/global/config` | `MimoServeClient.globalConfig()` | Global defaults; app reads `permission` today |
| PATCH | `/global/config` | `MimoServeClient.updateGlobalConfig()` | Push `permission` (access level) |
| POST | `/session/{id}/message` | `MimoServeClient.sendMessage()` | Chat send; body includes `agent`, optional `model`, `variant` |

No dedicated MCP/skills/plugins HTTP routes are wired in `MimoServeClient`. Agent resources are loaded from filesystem paths (see below).

## `GET /config/providers` schema (observed)

Wrapper: `{ "providers": [ … ] }` → `[MimoProviderResponse]`.

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Provider key used in send body `model.providerID` |
| `name` | string | Display name |
| `models` | object map | Keys = model IDs; values = `MimoProviderModel` |

### `MimoProviderModel`

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Model ID |
| `name` | string? | Display |
| `status` | string? | e.g. `active` |
| `providerID` | string? | Redundant provider hint on nested model |
| `capabilities` | object? | See capabilities table |
| `variants` | object map? | Keys = variant IDs (`low`, `medium`, `high`); values `{ reasoningEffort }` |
| `limit` | object? | `{ context, output }` token limits |
| `cost` | object? | `{ input, output }` |

### `capabilities` (per model)

| Field | Type | UI gate |
|-------|------|---------|
| `reasoning` | bool? | Variant / thinking menu |
| `toolcall` | bool? | Tools, MCP, plus-menu command hooks |
| `plan` | bool? | Plan agent mode (fallback: reasoning) |

When `capabilities` is absent, gates treat toolcall/plan as **allowed** (optimistic); reasoning variants require explicit `reasoning: true`.

## `GET /global/config` schema (observed)

Decoded as `MimoConfigResponse`:

| Field | Type | App usage |
|-------|------|-----------|
| `providers` | array? | Not used on read today |
| `model` | string? | Default model (not synced to toolbar yet) |
| `theme` | string? | Unused |
| `permission` | object? | `edit`, `bash`, `webfetch`, `external_directory` → access level |

No MCP/skills section in the Swift decoder; those configs live on disk for MiMo Agent.

## Send body contract

```json
{
  "parts": [ … ],
  "agent": "build|plan|compose",
  "model": { "providerID": "…", "modelID": "…" },
  "variant": "high",
  "messageID": "msg_…"
}
```

**Bug (fixed):** Previously `model` was omitted when `providerID` could not be resolved (custom models). App now requires explicit `selectedProviderID` and blocks send if unresolved.

Send without `model` block: server may use global default; app always sends nested `model` when a model is selected.

## Custom providers (local)

| Concern | Contract |
|---------|----------|
| Storage | `UserDefaults` key `com.mimocode.customProviders` |
| Server sync | **Not pushed** via API; MiMo Serve reads `mimocode.json` on disk (out of scope for macOS client push) |
| Synthetic `providerID` | Custom provider UUID `id` field used directly as `model.providerID` in send body |
| Models | Fetched from `{baseURL}/models` OpenAI-compatible list; merged into provider-scoped picker |

## Model ID collisions

If the same `modelID` exists on two server providers, resolution uses **explicit** `selectedProviderID`, not first-match scan.

## MCP / skills / plugins / commands (filesystem)

| Resource | Probe paths |
|----------|-------------|
| MCP | `~/.mimocode/mcp.json`, `~/.cursor/mcp.json` |
| Skills | `~/.cursor/skills/*/SKILL.md`, `~/.mimocode/skills/*/SKILL.md` |
| Plugins | `~/.mimocode/plugins/*/plugin.json` |
| Commands | `~/.mimocode/commands/*.md`, `~/.cursor/commands/*.md` |

Empty directories → honest empty state in Settings (no fabricated entries).

## Live test

```bash
MIMO_LIVE_TESTS=1 swift test --filter LiveIntegrationTests
```

Requires MiMo Serve on configured host/port (tests default `127.0.0.1:8080`).

## Sign-off

Probe documents provider→model→capabilities→send chain and filesystem agent resources. Implementation uses explicit provider selection + capability gates per hybrid plan.
