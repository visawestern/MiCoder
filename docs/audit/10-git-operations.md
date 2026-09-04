# Activity 10 — Git Operations

Источники: `Sources/Views/Components/GitPremiumDialogs.swift`, `Sources/Services/GitRepository.swift`, `Sources/Services/GitRefreshScheduler.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Git repo detection | `repositoryRoot` finds .git | Определение git-репозитория | 95/100 | PASS |
| 2 | Git status display | `vcsChanges` from `workingTreeChanges` | Список изменений | 95/100 | PASS |
| 3 | Branch display & switching | `checkoutGitBranch` / `gitBranches` | Отображение и переключение веток | 95/100 | PASS |
| 4 | Commit changes | `commitGitChanges` with user message | Коммит с сообщением | 95/100 | PASS |
| 5 | Push changes | `pushGitChanges` + upstream setup | Push в remote | 95/100 | PASS |
| 6 | Auto git refresh | `GitRefreshCoalescer` dedup | Автообновление статуса | 95/100 | PASS |
| 7 | Auto-commit toggle | BottomPanelView toggle | Опциональный авто-коммит | 90/100 | PASS |
| 8 | Git publish/PR flow | `GitPublishFlowLogic` + `GitHubCLIService` | Publish + PR | 90/100 | PASS |
| 9 | Commit dialog | Auto-generated message + custom input | Диалог коммита | 95/100 | PASS |
| 10 | Review+Push dialog | Comment + auto-commit+push | Review+Push | 90/100 | PASS |
| 11 | GitHub publish wizard | Repo name, public/private, create | Создание репозитория | 90/100 | PASS |
| 12 | PR dialog | Title + body for pull request | Создание PR | 90/100 | PASS |

## User Story

As a user, I can detect git repos, view and switch branches, commit with messages, push/pull, auto-refresh status, publish to GitHub, and create pull requests.
