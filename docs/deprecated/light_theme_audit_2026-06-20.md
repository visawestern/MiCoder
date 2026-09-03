# Sci-Fi Light theme audit

Date: 2026-06-20  
Theme: **Sci-Fi Light** (`AppTheme.lightGlass`)

## Automated token checks

| Check | Status |
|-------|--------|
| `surface != background` | PASS (`LightThemeContrastTests`) |
| `textPrimary` on `background` ≥ 4.5:1 | PASS |
| `textMuted` on `surface` ≥ 3:1 | PASS |
| `border` darker than `background` | PASS |
| `codeBg` separated from `background` | PASS |
| Dark theme regression | PASS |

## Token fixes applied

- Darkened `textMuted` / `textSecondary` on light palette
- Stronger `border`, `inputBorder`, `separator`
- Added `subtleFill`, `shadow` tokens
- Plus menu popover border overlay

## Manual screen matrix (L1–L16)

| # | Screen | Status | Notes |
|---|--------|--------|-------|
| L1 | Empty chat | PASS | Input card uses `input` + `inputBorder`; logo PNG visible |
| L2 | Chat transcript | PASS | Bubbles use `surface` + border; reasoning blocks use `codeBg` |
| L3 | Bottom input bar | PASS | Toolbar icons use `textSecondary` / `brand`; provider menu added |
| L4 | Sidebar | PASS | Row hover `surfaceHover`; muted labels updated |
| L5 | Task header | PASS | Chips use `subtleFill` + border |
| L6 | Right panel Git/Progress | PASS | Tabs and diff rows bordered |
| L7 | Terminal panel | PASS | Tab bar separator token |
| L8 | Status bar | PASS | Connection text `textSecondary` |
| L9 | Settings General | PASS | Theme picker rows on `surface` |
| L10 | Settings Code preview | PASS | Preview blocks use `codeBg` |
| L11 | Settings Model | PASS | 3-column provider panel; model cards bordered |
| L12 | Settings Skills/MCP/Plugins/Commands | PASS | Real loaders + empty states |
| L13 | Settings Indexing/Usage/Onboard | PASS | Stat cards on `surface` |
| L14 | Modals/sheets | PASS | Remote connection sheet background/border |
| L15 | Menus/popovers | PASS | Provider/model menus; plus menu border |
| L16 | Disabled gates | PASS | Plan/variant disabled items remain visible in menus |

**FAIL count: 0**

## Sign-off

Light theme tokens and provider-gated UI meet readability criteria. Re-run manual pass after major UI changes.
