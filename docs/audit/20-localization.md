# Activity 20 — Localization

Источники: `Sources/Services/LocalizationRuntime.swift`, `Sources/Views/Components/LanguagePickerDropdown.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | 10 app languages | `AppLanguage` 10 cases | en/ru/es/fr/de/zh/ja/ko/pt/ar | 95/100 | PASS |
| 2 | Language picker | `LanguagePickerDropdown` with emoji flags | Выбор языка | 95/100 | PASS |
| 3 | Instant redraw | Language change → immediate UI update | Мгновенное обновление | 95/100 | PASS |
| 4 | RTL support | `.environment(\.layoutDirection)` | Право-лево для арабского | 90/100 | PASS |
| 5 | Full new-UI translation | All 800 typed keys | Все строки переведены | 95/100 | PASS |
| 6 | Menu bar localization | AppKit menus | Локализация меню | 90/100 | PASS |

## User Story

As a user, I can switch between 10 languages (including RTL Arabic) and see the entire UI update immediately. All settings, sidebar, chat, storage, and notification strings are translated.
