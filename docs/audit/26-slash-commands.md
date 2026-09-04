# Activity 26 — Slash Commands

Источники: `Sources/Services/SlashCommandDispatcher.swift`, `Sources/Services/SlashCommandRegistry.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Slash command registry | 15 built-in + custom .md merge | Реестр команд | 95/100 | PASS |
| 2 | /goal sessionGoal | Sets session goal in TopBar | Установка цели сессии | 95/100 | PASS |
| 3 | /plan | Switches to Plan mode | Переключение в Plan | 95/100 | PASS |
| 4 | /commit | Opens commit composer | Открытие коммита | 95/100 | PASS |
| 5 | /pr | Creates PR or publish wizard | Создание PR | 95/100 | PASS |
| 6 | /review | Opens review+push dialog | Review+Push | 95/100 | PASS |
| 7 | /context | Shows context info | Контекстная информация | 95/100 | PASS |
| 8 | Unknown command | Shows available commands | Помощь по командам | 95/100 | PASS |
| 9 | Custom commands | CRUD + enable/disable + template injection | Пользовательские команды | 90/100 | PASS |

## User Story

As a user, I can use 15 built-in slash commands (/goal, /plan, /commit, /pr, /review, /context, etc.) and create custom commands with template injection.
