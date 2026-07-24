---
name: Mimo Settings Overhaul
overview: Полный чеклист-план (555 пунктов, 11 разделов) для переработки Settings/Providers, полной локализации, администрирования Skills/MCP, dev-команд, кастомного дропдауна ввода, per-project БД/индексации, фикса бага сброса хранилища, корректных attachments+автоопределения провайдера, удаления онбординга/статистики и растягиваемого сайдбара.
todos:
  - id: section1
    content: "Providers: объединить вкладки, убрать MiMo Serve из UI, добавить локальные провайдеры (Ollama/OpenCode/mimoCLI)"
    status: pending
  - id: section2
    content: Полная локализация на 10 языков + кастомный дропдаун языков с флагами
    status: pending
  - id: section3
    content: Полное администрирование Skills (CRUD, зависимости, каталог ≥45)
    status: pending
  - id: section4
    content: Полное администрирование MCP (CRUD, каталог ≥25, акцент browser/design)
    status: pending
  - id: section5
    content: Dev-команды в настройках (/goal и другие, аналог Cursor/Claude Code/Codex)
    status: pending
  - id: section6
    content: Кастомный дропдаун в поле ввода для skills/MCP/команд
    status: pending
  - id: section7
    content: Per-project БД + реальная индексация файлов проекта
    status: pending
  - id: section8
    content: Фикс бага автосоздания сессий после сброса + панель администрирования хранения
    status: pending
  - id: section9
    content: Фикс attachments для ACP + автоопределение провайдера по IP:порту
    status: pending
  - id: section10
    content: Убрать онбординг + реальная статистика использования по всем моделям
    status: pending
  - id: section11
    content: Растягиваемый сайдбар + редизайн по референс-скриншотам
    status: pending
isProject: false
---


# Полный план: MiMo macOS — 11 крупных доработок

Полный детализированный чеклист (555 пунктов, батчи по 10, оценка 10/10 по каждому батчу) сохранён в файле [mimo_settings_full_overhaul_2026-07-23.md](mimo_settings_full_overhaul_2026-07-23.md) в корне репозитория — согласно правилу "Режим создания плана". Ниже — краткая сводка по каждому разделу с ключевыми файлами и решениями.

## Подтверждённые решения
- **MiMo Serve**: убираем только UI-карточку/бренд из Settings → Providers. Транспортный слой (`MimoServeClient.swift`, `MimoServeConnectionManager.swift`) остаётся как техническая шина отправки сообщений.
- **Языки перевода (10)**: English, Русский, Español, Français, Deutsch, 中文, 日本語, 한국어, Português, العربية.
- **Источники каталогов Skills/MCP**: t.me/whackdoor и t.me/neuraldvig — общие тех-новостные каналы без структурированных списков; каталог собран из реальных публичных реестров (`github.com/modelcontextprotocol/servers`, `registry.modelcontextprotocol.io`, `github.com/anthropics/skills`, плюс skill-паки, уже используемые в среде разработки — superpowers, cursor-team-kit, appdisign).

## Раздел 1 — Providers: merge вкладок, убрать MiMo Serve из UI, локальные провайдеры
Объединить `SettingsTab.modelSettings` + `.providers` в одну вкладку "Providers" ([SettingsTab.swift](MiMoMacOS/Sources/Models/SettingsTab.swift), [SettingsView.swift](MiMoMacOS/Sources/Views/SettingsView.swift) L321–935, L2071–2278). Убрать карточку "MiMo Serve" (L343–395), добавить `LocalProviderKind {ollama, openCode, mimoCLI}` с health-check и автозагрузкой моделей.

## Раздел 2 — Полная локализация + флаги в дропдауне языков
Инвентаризация всех хардкод-строк, переход с самодельного EN/RU switch ([AppLocalization.swift](MiMoMacOS/Sources/Services/AppLocalization.swift)) на String Catalog (`.xcstrings`), перевод на 10 языков (с RTL для арабского, plural rules), кастомный `LanguagePickerDropdown` с emoji-флагами вместо системного `Menu`.

## Раздел 3 — Полное администрирование Skills
Расширить [AgentResourceInstaller.swift](MiMoMacOS/Sources/Services/AgentResourceInstaller.swift): enable/disable, update, remove (вкл. Cursor-путь), dependency-resolver, one-click install с зависимостями. Каталог расширен с 6 до ≥45 записей (anthropics/skills document/example-skills, superpowers, cursor-team-kit, appdisign).

## Раздел 4 — Полное администрирование MCP (акцент на браузеры и дизайн)
Аналогичный CRUD для MCP (enable/disable setter для `disabled` флага, edit args/env, health-check). Каталог расширен с 2 до ≥25 записей: reference-серверы, GitHub/Stripe/Linear, **Browser Automation** (Playwright, Puppeteer, Chrome DevTools, Browserbase), **Design** (Figma, Pablooo). Тематические "Установить набор" бандлы.

## Раздел 5 — Dev-команды (/goal и др.)
Новый `SlashCommandRegistry`: 15 встроенных команд (`/goal`, `/plan`, `/review`, `/test`, `/commit`, `/pr`, `/explain`, `/fix`, `/refactor`, `/document`, `/todo`, `/summarize`, `/context`, `/debug`, `/verify`) + полный CRUD для custom `.md`-команд в Settings.

## Раздел 6 — Кастомный дропдаун в поле ввода
`InputCommandTriggerLogic` + `InputCommandDropdownView`: живой оверлей по `/`, `@`, `#` с клавиатурной навигацией, объединяющий команды/skills/MCP/файлы/сессии из единых реестров разделов 3–5.

## Раздел 7 — Per-project БД и индексация
Переход от единой `~/.mimocode/mimo.db` к БД на проект (`<project>/.mimocode/project.db`) с полной историей диалогов, undo-стеком, request_history. Реальный FSEvents-индексатор файлов проекта (сейчас — только UI-флаги без индексатора).

## Раздел 8 — Фикс бага сброса хранилища + панель архивации
Корневая причина (подтверждена разведкой): [MiMoMacOSApp.swift](MiMoMacOS/Sources/App/MiMoMacOSApp.swift) `loadSessionsFromServer` (L272–300) реимпортирует всё из CLI-хранилища `~/.local/share/mimocode/mimocode.db`, которое `resetDatabase()` не трогает. Фикс: 3 явных сценария сброса + флаг `autoImportFromCLI` (default false) + новая панель Settings → Storage → Проекты с точечной архивацией/удалением/экспортом.

## Раздел 9 — Attachments по провайдерам + автоопределение по IP:порту
Найден реальный баг: ACP-путь (`ChatPanelView.swift` L678–688) отбрасывает реальные изображения в текстовый плейсхолдер — фикс через переиспользование `MessagePartsBuilder`. Новый `ProviderAutoDetector` с последовательностью проб (Ollama/OpenAI-compatible/MiMo/ACP) по адресу host:port с автозагрузкой моделей.

## Раздел 10 — Убрать онбординг + понятная статистика
Удалить `SettingsTab.onboard`/`OnboardSettingsView` (только UI-заглушка). Переработать Usage: реальная агрегация по `tokens_used`/`cost_usd`/`prompt_tokens`/`completion_tokens` (колонки уже есть, не используются), per-model breakdown, рабочая фильтрация по датам.

## Раздел 11 — Растягиваемый сайдбар + редизайн по скриншотам
Заменить фиксированный `.frame(width: 260)` ([ContentView.swift](MiMoMacOS/Sources/Views/ContentView.swift) L7–14) на resizable с drag-хендлом и персистентностью. Редизайн верхней панели: пилл "# Group / 📁 Project", иконки развернуть/фильтр/архив, счётчик, кнопка "+", цветная полоса активной задачи, статус-точки, относительное время — по референс-скриншотам.

## Методология
Каждый раздел содержит "(TDD)" пункты (тест до реализации), явные критерии приёмки, регрессионные тесты для существующего покрытия, и — где применимо — тест, который явно воспроизводит текущий баг и падает на старом коде (Раздел 8, п.36; Раздел 9, п.11). Полный текст со всеми 555 пунктами и оценками находится в [mimo_settings_full_overhaul_2026-07-23.md](mimo_settings_full_overhaul_2026-07-23.md).
