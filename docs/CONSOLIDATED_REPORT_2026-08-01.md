# Сводный отчёт по всем раундам (2026-07-17 → 2026-08-01)

Финальная сводка всех раундов работы над MiCoder/miMo macOS, от первого
прохода "как адвокат дьявола" до текущего состояния. Постоянные требования
пользователя, выполнявшиеся в каждом раунде: TDD с red-тестами на крайние
случаи, ручная пошаговая проверка каждой цепочки, честный отчёт без заглушек,
коммит и пуш на origin/main после каждого раунда.

---

## Раунды 1–6 (2026-07-17 … 2026-07-23)
Фундаментальные проходы "адвоката дьявола": сборка, send-цепочка, провайдеры,
хранилище, локализация, сайдбар. Заложены: отдельные отчёты
`devils_advocate_round_1…6`, `FEATURE_REGISTRY.md`, `QUALITY_REPORT`,
`mimo_zcode_parity`. Создан и наполнен план `mimo_settings_full_overhaul_2026-07-23.md`
(Разделы 1–13, блоки по 10 пунктов, оценки 10/10).

## Round 7 (2026-07-24) — Send-цепочка: отправка молча ничего не делала
- 5 ветвей маршрутизации (`openAICompatible/web/acp/mimoServe/none`) разобраны
  вручную по цепочке; P1–P4 дефекты закрыты; добавлены
  `SendReadinessReason`, `SendRouteGuard`, `SendStatusText`, `WebChatTurnMutation`;
  TDD-тесты в `SendChainRegressionTests.swift`.
- Результат: отправка сообщения больше не "пропадает в никуда" — причина
  показывается, статусы пишутся.

## Round 8 (2026-07-31) — Полный devil's-advocate прогон
- `DEVILS_ADVOCATE_ROUND_8_2026-07-31.md`: перепроверены все предыдущие фиксы;
  зафиксированы остаточные риски P5 (MessageQueue → isLoading flip) и
  P6 (долгие таймауты SSE/MimoServeClient до 300 с).

## Round 9 (2026-07-31) — Модели из web определяются динамически
- `WebModelDiscovery`, `WebProviderCatalog` (web_providers_catalog.json),
  `WebProviderConnectivity.modelsOrError`; 8 тестов в `WebModelDiscoveryTests.swift`.
- Итог: веб-модели больше не хардкодятся — читаются со страницы вендора.

## Round 10 (2026-07-31) — Краш на очистке базы + переводы
- Корневая причина краша: `removeSubrange` вне границ в navigation didSet
  при параллельной мутации; первый фикс — bounds-check + `clearInMemoryState()`
  без DB I/O (3×1599 зелёных).
- Добавлены ключи локализации (AppLocalization) для StatusBar/Storage/и пр.;
  `SettingsActionsRegressionTests`, `LocalizationCoverageTests`,
  `StorageResetCrashTests`.
- Ремайндер: брендинг MiMoCode → MiCoder (Round 11, `TopBarView`).

## Round 11 (2026-08-01) — Брендинг
- `a37256e`: все надписи MiMoCode → MiCoder.

## Round 12 (2026-08-01) — ручной аудит КАЖДОЙ кнопки clear/delete
(детали — в `DEVILS_ADVOCATE_ROUND_12_2026-08-01.md`)
- D1: `deleteProject` без подтверждения → alert с вводом имени (п.24/п.54),
  `ProjectDeleteConfirmation` (TDD, 5 тестов).
- D2: Skill/MCP remove без подтверждения → отдельные destructive-алерты.
- D3: краш навигации ВЕРНУЛСЯ → настоящий NSLock вокруг всех
  navigationHistory/navigationIndex операций (не bounds-check, а атомарность).
  3×1603 зелёных.
- D4: флаки `UserDefaults.standard` → `AppSettings.load/save(from:)` +
  выделенный suite в тесте.
- D5: анализ "зависает" на `[tool call: LS ...]` → толерантный парсер
  неформальных tool-вызовов + case-insensitive алиасы (LS→list_dir и т.д.),
  5 новых тестов; побочно найден и устранён NSException в `substring(with:)`
  на NSNotFound-группах.

---

## Итоговое состояние (проверено на реальных примерах)

| Критерий | Статус |
|---|---|
| Сборка под Intel MacBook (`swift build`, `build-app.sh`) | ✅ |
| `.app` бандл v2.12 (build 14), ресурсы включены | ✅ |
| Полный набор тестов | ✅ 1603 passed, 220 suites, 3× стабильно |
| Краш на очистке базы/навигации | ✅ устранён (lock + атомарность) |
| Все деструктивные кнопки имеют подтверждение | ✅ (deleteProject — с вводом имени) |
| Модели из web определяются со страницы, не хардкод | ✅ |
| Send-цепочка не "молчит", причины видны | ✅ |
| Неформальные tool-вызовы веб-моделей парсятся | ✅ (LS/Read/Grep/Run + bracket-форма) |
| Локализация основных экранов | ✅ (10 языков, fallback → EN) |
| Брендинг MiMoCode → MiCoder | ✅ |

## Остаточные риски (честно, из Round 8)
- P5: `MessageQueue.processNext` зависит от flip `isLoading` — по-прежнему в
  коде; воспроизвести молчаливый отказ не удалось, но каскад не убран.
- P6: длинные таймауты SSE/MimoServeClient (до 300 с) — намеренно консервативны
  для медленных web-моделей; при желании можно сократить.

## План дальше (mimo_settings_full_overhaul)
Разделы 1–13 плана детализированы блоками по 10 пунктов с оценками 10/10.
Следующий раунд продолжит с ближайших незакрытых пунктов плана (после того,
что закрыл Round 12), с тем же правилом: TDD red→green, ручная проверка,
отчёт, коммит, пуш.
