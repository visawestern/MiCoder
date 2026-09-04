# Activity 07 — Right Panel (Git Tools & Progress)

Источники: `Sources/Views/RightPanelView.swift`

## Control and Action Inventory

| # | Контрол/действие | Trigger → handler → state → result | Ожидаемое поведение | Качество | Статус |
|---|---|---|---|---|---|
| 1 | Refresh git | Arrow icon → `appState.scheduleGitRefresh()` | Обновление git статуса | 95/100 | PASS |
| 2 | Git status message | Text box | Статус git | 95/100 | PASS |
| 3 | Changes list | Scrollable | `appState.vcsChanges` | 95/100 | PASS |
| 4 | Branch dropdown | Menu → `checkout(branch)` | Переключение ветки | 95/100 | PASS |
| 5 | Commit button | Primary button → `CommitDialogView` sheet | Коммит (gate: hasChanges) | 95/100 | PASS |
| 6 | Review+Push button | Primary button → `ReviewPushDialogView` sheet | Review+Push (gate: hasRemote) | 90/100 | PASS |
| 7 | Publish to GitHub | Primary button → `GitHubPublishWizardView` sheet | Publish (no remote) | 90/100 | PASS |
| 8 | Initialize Git | Primary button → `GitInitDialogView` sheet | Init git (no .git) | 90/100 | PASS |
| 9 | Step list | In-progress/waiting/completed | `appState.currentSteps` | 95/100 | PASS |
| 10 | Progress counter | "3/5" text | `TaskProgress.formatted` | 90/100 | PASS |
| 11 | Completed steps | Strikethrough + checkmark | Визуальное завершение | 90/100 | PASS |
| 12 | In-progress step | Warning color + spinner | Текущий шаг | 90/100 | PASS |
| 13 | Collapsed waiting | "+2 waiting" summary | Скрытые шаги | 90/100 | PASS |
| 14 | Placeholder | "No steps yet" | When empty | 95/100 | PASS |

## User Story

As a user, I can see git status, branches, changes, and perform commit/push/pull/publish/PR actions from the right panel. I can also see execution progress with step-by-step status.
