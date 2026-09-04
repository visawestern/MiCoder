# Activity 06 — Bottom Panel (Terminal & Git)

Источники: `Sources/Views/BottomPanelView.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Terminal tab | Tab button (tag 0) | Переключение на TerminalView | 95/100 | PASS |
| 2 | Git tab | Tab button (tag 1) | Переключение на GitPanelView | 95/100 | PASS |
| 3 | Close panel | X button → `appState.showTerminal = false` | Закрытие панели | 95/100 | PASS |
| 4 | Command input | TextField with `$ ` prefix | Ввод команды | 95/100 | PASS |
| 5 | Execute command | Enter → `startAsyncExecution(command:)` | Запуск через `/bin/zsh` | 95/100 | PASS |
| 6 | Stop execution | Stop button / ⌃C → `stopExecution()` | Остановка процесса | 95/100 | PASS |
| 7 | Built-in `clear` | Command | Очистка вывода | 95/100 | PASS |
| 8 | Built-in `help` | Command | Справка по командам | 95/100 | PASS |
| 9 | Built-in `sleep [s]` | Command | Неблокирующий sleep с countdown | 90/100 | PASS |
| 10 | Command timeout | Auto-kill 30s | Таймаут 30 секунд | 95/100 | PASS |
| 11 | Streaming output | `Pipe.readabilityHandler` | Реалтайм stdout/stderr | 95/100 | PASS |
| 12 | Line pruning | Auto max 500 lines | Обрезка длинного вывода | 95/100 | PASS |
| 13 | Welcome message | On appear | Локализованное приветствие | 90/100 | PASS |
| 14 | Git branch dropdown | `BranchHeader` → `checkoutBranch(branch)` | Переключение ветки | 95/100 | PASS |
| 15 | Git commit button | `GitActionButton` → `pendingGitAction` | Открытие CommitDialogView | 95/100 | PASS |
| 16 | Git push button | `GitActionButton` → `GitRepository.push(in:)` | Push в remote | 95/100 | PASS |
| 17 | Git pull button | `GitActionButton` → `GitRepository.run(["pull"])` | Pull из remote | 95/100 | PASS |
| 18 | New branch | Alert dialog → `GitRepository.run(["checkout", "-b", name])` | Новая ветка | 90/100 | PASS |
| 19 | Changes list | `ChangesList` with `ChangeRow` | Список изменений | 95/100 | PASS |
| 20 | Status badge | Status color per change | A/D/R/M/?, +count, -count | 95/100 | PASS |

## User Story

As a user, I can run terminal commands with streaming output, 30s timeout, and built-in helpers (clear/help/sleep). I can also manage git branches, commits, pushes, pulls, and see working tree changes.
