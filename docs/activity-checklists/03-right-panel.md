# Чеклист: Правая панель — Git/прогресс (RightPanelView.swift)

Источник: `Views/RightPanelView.swift` (462 LOC) + `Views/Components/GitPremiumDialogs.swift` (548 LOC).

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 1 | Инициализация Git | Секция `GitToolsSection` | Кнопка init | «Initializing Git repository...» → «Git repository initialized successfully»; при сбое «Failed to initialize Git: …» | ✅ |
| 2 | Создание ветки | «Create New Branch» | Кнопка | Диалог: «Branch name», пояснение «Enter a name for the new branch. Current branch: \(branch)»; подтверждение «Created and switched to \(branchName)»; сбой «Branch creation failed: …» | ✅ |
| 3 | Переключение ветки | Checkout | Кнопка | «Switched to \(branch)»; сбой «Checkout failed: …» | ✅ |
| 4 | Коммит | «Commit» | Кнопка | «Committed successfully»; сбой «Commit failed: …»; автоматический коммит использует сообщение «Auto-commit from MiCoder» | ✅ |
| 5 | Push | «Push» | Кнопка | «Pushed successfully»; сбой «Push failed: …»; при отказе после коммита «Commit failed — push cancelled.» | ✅ |
| 6 | Pull | «Pull» | Кнопка | «Pull complete»; сбой «Pull failed: …» | ✅ |
| 7 | Обновление состояния | arrow.clockwise / arrow.triangle.2.circlepath | Кнопка | «Failed to refresh git: \(error)» при ошибке | ✅ |
| 8 | Список изменений | Файлы со статусами | Открытие панели | Строки `+N`/`-N` на файл и итоги `sessionGitTotals` (additions/deletions) | ✅ |
| 9 | Нет воркспейса | `workspaceName` передаётся пустым | — | «Error: no workspace selected» при действии | ✅ |
| 10 | Прогресс | `ProgressSection` | Долгие операции | Индикатор прогресса выполнения | ✅ |
| 11 | Платные функции Git | `PremiumDialogChrome` (`GitPremiumDialogs`) | Действие, требующее Premium | Модалка: градиент brand→violet→cyan, иконка, title/subtitle, action-row | ✅ |
| 12 | Публикация репозитория | «GitPublishFlowLogic.suggestedRepoName(from:)» | Кнопка publish | Подсказка имени репо из имени воркспейса | ✅ |

## Найденные проблемы / замечания

- ⚠️ Коммит с последующим push может завершиться «Commit failed — push cancelled.» — сообщение
  описывает отменённый push, но формулировку легко принять за сбой коммита (логистическая
  формулировка, см. `docs/FEATURE_SPREADSHEET.csv` на предмет user-story).
- ⚠️ При пустом воркспейсе действия показывают ошибку по месту, но панель при этом открыта —
  визуально не объясняется, что нужно создать/выбрать проект.

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
