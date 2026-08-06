# Чеклист: Настройки (SettingsView.swift)

Источник: `Views/SettingsView.swift` (2960 LOC). Окно min 800×600, `SettingsSidebar` 220pt + `SettingsContent`. Ручная сверка проводки 2026-08-06; `swift test` — 1716/1716 PASS. Нативные Keychain, file picker и web-login не были кликнуты в живом сеансе и отмечены ниже как live-QA.
Табы — `SettingsTab.visibleCases` (10 шт., `.modelSettings` скрыт и слит в Providers).

## Общее

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 1 | Открытие настроек | Кнопка «Settings» / «Open Settings» | Клик | Полноэкранное окно настроек | ✅ |
| 2 | Переключение табов | Сайдбар 220pt | Клик по пункту | Смена содержимого; глубокие ссылки на скрытый `.modelSettings` всё ещё работают (back-compat) | ✅ |

## General

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 3 | Статистика использования | «App usage» (calendar, bubble.left) | Открытие таба | «Active days», «N msg», счётчики активных/архивированных сессий | ✅ |
| 4 | Авто-архив | «Auto-archive» | Переключатель | «Archive inactive > N days»; «Archive after:» 7/14/30/90/180 дней | ✅ |
| 5 | Архивация сейчас | «Archive now» | Кнопка | Батч-архив по правилу «Bulk-archive projects not opened in the selected number of days (plan Раздел 8 п.25)» | ✅ |
| 6 | Удаление старых чатов | «Delete chats older than:» | Кнопка | Диалог «Delete old chats?» | ✅ |
| 7 | Удаление всех архивированных | «Delete all archived chats» | Кнопка | Диалог «Delete archived chats?» | ✅ |
| 8 | Очистка кэша | «Clear app cache?» | Кнопка | Подтверждение и очистка | ✅ |
| 9 | Сжатие БД | «Compress database (VACUUM)» | Кнопка | VACUUM базы приложения; «Database size» показывает размер | ✅ |
| 10 | Сжатие БД проекта | «Compress this project's database (VACUUM)» | Кнопка | VACUUM базы выбранного проекта | ✅ |
| 11 | Удаление проекта | «Delete project permanently?» | Кнопка | Требует «Delete project (requires typing its name)» + «type repo name to delete» | ✅ |
| 12 | Удаление записи | «Delete record (requires typing its name)» | Кнопка | Подтверждение вводом имени | ✅ |

## Code preview

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 13 | Размер шрифта кода | «Code font size» (slider) | Слайдер | «Adjust the default font size used by code previews»; подпись `\(appState.settings.codeFontSize)` | ✅ |
| 14 | Тёмная тема кода | «Dark code theme» | Переключатель | Переключение темы превью кода | ✅ |

## Providers (включая бывший Model settings)

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 15 | Добавление провайдера | «Add Provider» / «Add provider» | Кнопка | Форма: имя («e.g., My OpenRouter»), «Base URL», «API Key» (placeholder «sk-...»), «API endpoint URL», «Context Length»; «Confirm and add» | ✅ |
| 16 | Список провайдеров | Карточки «Configured N» | Открытие таба | Провайдеры с числом моделей «N models» / «N available», кнопки «Manage models» | ✅ |
| 17 | Скрытые модели | «No models for this provider» | Пустой провайдер | Предупреждение о необходимости добавить модели | ✅ |
| 18 | Web-провайдеры | `WebProvidersSection` | Открытие секции | Kimi/Qwen/ChatGPT: ToS-предупреждение, кнопки Add/Configured, embedded web login с захватом cookie; защита «Web providers require WebKit (macOS).» | ✅ |
| 19 | Удалённое подключение | «Remote connection» | Кнопка | Форма «Connect to a local agent instance on another host»: «Host» (placeholder «localhost:11434 or 192.168.1.10:4096»), «Port», «Connect»/«Connecting…»; подтверждение «is this really your local server?» | ✅ |
| 20 | Параметры кастомных моделей | «om-...», «oc/deepseek», «gpt-4» и т.д. | Редактирование | «Context»/«1M», «Cost» «per 1K tokens» | ✅ |
| 20a | Автодетект локального провайдера | Поле host:port → Auto-detect → Confirm/Cancel | Запускает ограниченный по времени probe, показывает найденный тип/модели, не добавляет конфигурацию до подтверждения; Cancel не меняет список. | ⚠️ Логика подтверждена изолированно: 20/20 тестов. В полном параллельном `swift test` deadline-тест один раз превысил 2.5 s (4.78 s), поэтому таймаут требует повторного live-QA. |

## Skills

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 21 | Библиотека навыков | Таб Skills (wand.and.stars) | Открытие | «Browse the library and install skills in one click, or manage local skills under ~/.micoder/skills.»; поиск, «Installed N», `InstalledSkillRow` (OnChanged → reloadSkills) | ✅ |
| 22 | Установка навыка | Кнопка Install | Клик | Установка в `~/.micoder/skills` из каталога | ✅ |

## MCP Servers

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 23 | Библиотека MCP | Таб MCP Servers (server.rack) | Открытие | «Browse the library and install MCP servers in one click. Configurations are saved to ~/.micoder/mcp.json.»; `.micoder/mcp.json` | ✅ |

## Commands / Plugins

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 24 | Кастомные команды | Таб Commands (terminal) | Открытие | Список `/command`; «Add .md files to ~/.micoder/commands» | ✅ |
| 25 | Плагины | Таб Plugins (puzzlepiece) | Открытие | Управление плагинами | ✅ |

## Indexing

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 26 | Авто-индексация репозиториев | Таб Indexing (checkmark.circle) | Переключатель | «Automatically index repositories to speed up Grep searches. All data is stored locally.» | ✅ |
| 27 | Авто-индексация новых папок | Тот же таб | Переключатель | «Automatically index any new folders with fewer than 50,000 files.» | ✅ |

## Storage

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 28 | Размеры баз | Таб Storage (externaldrive) | Открытие | Размеры в «%.1fM» / «%.1fk» на проект/приложение; кнопки «Archive now»/«Compress» | ✅ |
| 29 | Полная панель хранения | «Open full storage panel» (из сайдбара) | Клик | Разворачивает Storage-таб | ✅ |

## Usage

| № | Действие | Где | Триггер | Ожидаемое поведение | Статус |
|---|----------|-----|---------|----------------------|--------|
| 30 | Статистика расходов | Таб Usage (chart.bar) | Открытие | «App usage», график «by usage», токены `\(promptTokens)↑ \(completionTokens)↓`, стоимость «per 1K» | ✅ |
| 31 | Фильтр периода | Выбор дней | Клик | Диапазоны 3/7/30/90/180/365 дней; «1 year» | ✅ |

## Полный административный охват

| № | Действие | Где | Ожидаемое поведение | Статус |
|---|---|---|---|---|
| 32 | Theme и интерфейсный масштаб | General | Выбрать тему и один из уровней zoom; состояние сохраняется в settings. | ✅ |
| 33 | Темы code preview | Code preview | Выбрать light/dark syntax theme и размер шрифта. | ✅ |
| 34 | Проверить подключение нового provider | Add Provider | Test connection показывает результат, не добавляя provider до Confirm and add. | ⚠️ Нужен доступный endpoint. |
| 35 | Сохранить/заменить API key | Provider detail | Записать ключ через Keychain и обновить provider. | ⚠️ Нужен live-QA Keychain. |
| 36 | Enable Tool Calling / ACP | Add Provider и Provider detail | Изменить capability-флаги; ACP показывается только для ACP provider. | ✅ |
| 37 | Удалить custom provider | Provider detail/card | Удалить provider после destructive action; список обновляется. | ✅ |
| 38 | Model action menu | Model row | Select provider, открыть parameters, скопировать model info и включить tool-result fix для Agent Router при наличии. | ✅ |
| 39 | Local provider cards | Providers | Добавить Ollama/OpenCode/MiCoder CLI, затем enable/disable или удалить конфигурацию. | ⚠️ Auto-detect требует доступный локальный сервис. |
| 40 | Search resources | Skills/MCP/Plugins/Commands | Фильтровать библиотеку/локальные записи по text query; пустое состояние объясняет дальнейшее действие. | ✅ |
| 41 | Skill admin | Installed skill row | Install, enable/disable, uninstall с destructive confirmation. | ✅ |
| 42 | MCP admin и health | Installed MCP row | Install, enable/disable, удалить с confirmation; индикатор отражает health probe, а не preference. | ⚠️ Health требует доступный MCP server. |
| 43 | Project registry: relink | Storage | Открыть picker, выбрать новую папку для stale project и обновить запись. | ⚠️ Нужен live-QA picker. |
| 44 | Project registry: archive/restore/delete | Storage | Архивировать или восстановить запись; удаление требует ввода точного имени. | ✅ |
| 45 | Backup export/import | Storage | Экспортировать DB+snapshots ZIP или импортировать backup в выбранный проект. | ⚠️ Нужен live-QA файловых диалогов. |

## Найденные проблемы / замечания

- ⚠️ Вкладка «Plugins» и «Commands» визуально близки (обе про расширяемость); без явных подсказок
  пользователь может спутать назначение (план: раздел 1).
- ⚠️ Удаление проекта/записи требует ввода имени — намеренно, но UX не объясняет причину до диалога.

## Цепочная проверка PASS

Все пункты ✅ вручную прослежены от Settings control до `AppState`, registry,
storage и provider services; повторный полный `swift test` прошёл. Keychain,
file picker и реальные network probes остаются live-QA. Детали:
[`12-chain-verification-2026-08-06.md`](12-chain-verification-2026-08-06.md).

Для Web Providers отдельная E2E-проверка discovery и browser tool loop:
[`13-web-provider-e2e-2026-08-06.md`](13-web-provider-e2e-2026-08-06.md).

## Следующий обязательный цикл

```text
/goal go over every single feature in this file create a user story with expected behaviour based on the code keep a single canonical spreadsheet tracking the features status
• when done switch loop to testing every user story and documenting all errors
• when done fix every logistical error or ux error
• test every user behaviour again post fix
```
