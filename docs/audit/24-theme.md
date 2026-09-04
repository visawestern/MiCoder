# Activity 24 — Theme & Typography

Источники: `Sources/Theme/MiMoColors.swift`, `Sources/Theme/InterfaceTypography.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Dark/Light theme | `appTheme` stored, sets colors | Переключение темы | 95/100 | PASS |
| 2 | Font scaling | `fontScale` via `interfaceFontScale` | Масштабирование шрифта | 95/100 | PASS |
| 3 | Code preview themes | Light: GitHub/One/Solarized; Dark: GitHub/One/Solarized/Dracula | Выбор темы кода | 90/100 | PASS |

## User Story

As a user, I can switch between dark/light/system themes, adjust font scaling, and choose code preview themes.
