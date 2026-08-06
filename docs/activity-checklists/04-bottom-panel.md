# Чеклист: Нижняя панель (BottomPanelView.swift)

Источник: `Views/BottomPanelView.swift` (805 LOC). Табы: 0 = Terminal, 1 = Git. Закрытие панели — кнопка close.

## Таб «Terminal» (индекс 0)

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 1 | Запуск терминала | Таб Terminal | Выбор таба | Интерактивный терминал на `/bin/zsh`, строка приглашения `$ \(trimmed)` | ✅ |
| 2 | Ввод команды | Строка ввода | Enter | Исполнение в zsh; отображение «exit code: \(exitCode)» | ✅ |
| 3 | Остановка | «Stop (⌃C)» | Кнопка / ⌃C | Прерывание текущего процесса | ✅ |
| 4 | Очистка экрана | «clear — Clear screen» | Команда `clear` | Очистка вывода терминала | ✅ |
| 5 | Пауза | «sleep [seconds] — Pause execution» | Команда `sleep N` | Приостановка выполнения на N секунд; таймер «\(elapsed)s / \(remain)s» | ✅ |
| 6 | Справка | «help» / «?» | Команда | Список встроенных спец-команд | ✅ |
| 7 | Флаги строки | «-b», «-c» и др. | Ввод флагов | Передача флагов в оболочку/команду | ✅ |
| 8 | Безопасная пауза | «, safeSeconds))s remaining» | Команда sleep с лимитом | Ограничение времени ожидания (safeSeconds) | ✅ |

## Таб «Git» (индекс 1)

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 9 | Состояние изменений | Список «Changes» | Открытие таба | Файлы со статусами M/A/D/R, строки `+N`/`-N` + итоги `totals`; при пустоте «No changes» | ✅ |
| 10 | Создание ветки | «Create New Branch» | Кнопка | Диалог «Branch name», «Created and switched to \(branchName)», сбои «Branch creation failed»/«Checkout failed» | ✅ |
| 11 | Коммит | «Commit» | Кнопка | «Committed successfully»; авто-коммит «Auto-commit from MiCoder» | ✅ |
| 12 | Push / Pull | «Push» / «Pull» (arrow.up.circle / arrow.down.circle) | Кнопки | «Pushed successfully» / «Pull complete»; сбои «Push failed»/«Pull failed»/«Commit failed» | ✅ |
| 13 | Обновление git-состояния | «Failed to refresh git: \(error)» | Кнопка обновления | Отображение ошибки при недоступности Git | ✅ |
| 14 | Сворачивание панели | Кнопка close | Клик | Панель закрывается (в `ContentView` `showTerminal = false`) | ✅ |

## Найденные проблемы / замечания

- ⚠️ Git-функционал продублирован в нижней панели и в правой панели — два места управления одним
  репозиторием; состояние синхронизируется, но визуально разнесено (по дизайну: план).
- ⚠️ Спец-команды терминала (п.4–6) — это встроенные хелперы, а не команды zsh; для пользователя
  разница не объясняется в UI, только в `help`.

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
