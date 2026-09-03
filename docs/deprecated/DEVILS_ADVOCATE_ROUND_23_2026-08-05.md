# Devil's Advocate — Round 23 (2026-08-05)

Тема раунда: **E25/E26/E27/E28 — контракт вкладок Settings, остатки бренда MiMo, заголовок Overview-шита, мёртвый код** (Раздел 13 п.7/п.11, Раздел 1 п.7, правило clean-slate). Каждый пункт проверен вручную по коду перед фиксом.

---

## Проверка цепочки (как адвокат дьявола)

### E25 — тест утверждал НЕ тот контракт (не дефект кода, а дефект теста)
**Где:** `SettingsIntegrationTests.swift:703-714` — `#expect(SettingsTab.allCases.count == 11)` включая `.modelSettings`.
**Почему это реально:** UI уже рендерит только `SettingsTab.visibleCases` (`SettingsView.swift:42`, `SettingsTab.swift:22-24` — `.modelSettings` отфильтрован, вкладки объединены по Разделу 1 Блок 3). Кейс `.modelSettings` намеренно сохранён для обратной совместимости (deep links/последняя вкладка). Старый тест валидировал сырой enum и тем самым фиксировал «11 вкладок включая Model settings» — контракт, противоречащий плану.
**Решение:** тест переписан на два: (a) raw enum держит back-compat кейс; (b) `visibleCases` = ровно 10 вкладок БЕЗ `.modelSettings`, порядок совпадает с отрисованным списком. Это и есть честный контракт.

### E26 (HIGH) — пользовательские строки с брендом MiMo (Раздел 13 п.11)
Проверено grep'ом по Sources, найдены и исправлены:
1. `SettingsView.swift:1564` — «Manage **MiMo** Agent .md command files…» → «Manage **MiCoder** Agent…».
2. `SettingsView.swift:2412` — «…via Ollama, OpenCode, or **MiMo CLI/Serve**…» → «**MiCoder CLI/Serve**».
3. `BottomPanelView.swift:487` — «Auto-commit from **MiMo**» → «Auto-commit from **MiCoder**».
Плюс зачищены устаревшие комментарии (`SettingsView.swift:2377` — «MiMo CLI» → «MiCoder CLI»; `:1307` — комментарий про «MiMo and Cursor paths», код которого больше не существует: цикл удаления идёт только по `~/.micoder/skills`).

### E27 (MED) — Overview-шит назван «Workspaces» (Раздел 13 п.7)
**Где:** `SidebarView.swift:502` — `Text("Workspaces")` в `WorkspacesOverviewSheet` (единственное вхождение `Text("Workspaces")` в файле; заголовок секции сайдбара уже убран ранее, см. комментарий в `WorkspacesSectionHeader`).
**Решение:** заголовок шита → «Overview».

### E28 (MED) — мёртвый production-код `neutralizeServeBranding` (Раздел 1 п.7 / clean-slate)
**Где:** `LocalProviderConfig.swift:126-131` — функция определена, нигде в Sources не вызывается (grep по Sources: только определение; единственный референс — тест `LocalProviderConfigTests.swift:54-57`).
**Почему это реально:** Round 18 (директива пользователя «clean slate») удалил весь легаси; серверные провайдеры с брендом serve больше не проходят через эту функцию. Мёртвый код = путаница и ложная уверенность, что он нужен.
**Решение:** функция удалена вместе с её тестом. Красный тест (source-inspection): `neutralizeServeBranding` не должен встречаться в `LocalProviderConfig.swift` — падал на старом состоянии, зелёный после удаления.

---

## TDD: red → green

| Тест | Red (до фикса) | Green (после) |
|------|----------------|---------------|
| `noMiMoAgentCopy` | ✘ «Manage MiMo Agent» найден | ✔ |
| `noMiMoCLIServeCopy` | ✘ «MiMo CLI/Serve» найден | ✔ |
| `noMiMoCommitMessage` | ✘ «Auto-commit from MiMo» найден | ✔ |
| `overviewSheetNotTitledWorkspaces` | ✘ `Text("Workspaces")` найден | ✔ |
| `noNeutralizeServeBrandingDeadCode` | ✘ идентификатор найден | ✔ |
| `settingsTabVisibleList` (E25, новый контракт) | — (контракт уже выполнялся; старый тест фиксировал неверный) | ✔ `visibleCases == 10` без `.modelSettings` |

Полный прогон: **1706 тестов / 232 сьюта, все зелёные** (после Round 22 было 1701/231).

## Изменённые файлы
- `MiCoder/Sources/Views/SettingsView.swift` — строки бренда + комментарии (E26).
- `MiCoder/Sources/Views/BottomPanelView.swift` — «Auto-commit from MiCoder» (E26).
- `MiCoder/Sources/Views/SidebarView.swift` — заголовок шита «Overview» (E27).
- `MiCoder/Sources/Services/LocalProviderConfig.swift` — удалён `neutralizeServeBranding` (E28).
- `MiCoder/Tests/LocalProviderConfigTests.swift` — удалён тест мёртвой функции.
- `MiCoder/Tests/SettingsIntegrationTests.swift` — E25: контракт visible-вкладок.
- `MiCoder/Tests/E26E27E28RebrandAndCleanupTests.swift` — новый source-inspection сьют (5 тестов).

## Версия
`Info.plist`: CFBundleShortVersionString 2.18 → **2.19**, build 20 → **21**.

## Осталось в очереди (честно)
- E29 — локализация панели Storage (Раздел 8 п.34) — большой локализационный блок.
- E30 — жёсткий лимит `getAllProjects(limit: 100)` (Раздел 8 п.42).
- E31 — интерактивный мост решения капчи web-провайдера (Раздел 12 п.34).
- E13/E14/E15, E17/E18/E19, E07/E22, E20/E21 — по списку `FEATURE_TEST_REPORT.md`.
