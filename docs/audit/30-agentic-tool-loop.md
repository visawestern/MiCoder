# Activity 30 — Agentic Tool Loop (Auto Free)

Дата аудита: 2026-09-06
Источники: коммиты `d879979..5399233` (2026-09-04 → 2026-09-05), ручная проверка кода
Код: `MiCoder/Sources/Views/ChatPanelView.swift:794-915`, `MiCoderAutoFreeProvider.swift`, `MiCoderAutoFreeClient.swift`, `WebToolProtocolEmulator.swift`, `ProjectWebToolExecutor.swift`, `MiCoderAutoFreeHistoryLogic.swift`

## Обнаруженные кнопки/действия/состояния

| # | Поведение | Текущее качество |
|---|---|---|
| 1 | Отправка сообщения на auto-free провайдере запускает agentic loop (макс. 15 итераций) | WORKS (`for iteration in 0..<maxIterations`, ChatPanelView:831) |
| 2 | Модель вызывает инструменты через ```tool / XML / informal блоки | WORKS (`parseToolCalls` + `arguments` key — commit 5399233) |
| 3 | Инструменты исполняются в проекте (`ProjectWebToolExecutor`) | WORKS |
| 4 | AccessLevel gate до исполнения инструмента | WORKS (gate в `execute()`; валидация `validate()` перед ним в ChatPanelView:861) |
| 5 | Path-boundary проверка (инструмент не выходит за project root при accessLevel != fullAccess) | WORKS (см. ARCH-06 fix — symlink traversal устранён) |
| 6 | Результаты инструментов отправляются обратно модели как user message + tool_result | WORKS (ChatPanelView:876-877) |
| 7 | Reasoning накапливается по всем итерациям | WORKS (commit 5e35d2d: `streamedReasoning += iterationReasoning`) |
| 8 | Tool calls показываются в UI как spoiler parts | WORKS (commit 4f17775: `allToolCallParts`) |
| 9 | История прошлых ходов отправляется модели | WORKS (`MiCoderAutoFreeHistoryLogic.history`, max 20 ходов) |
| 10 | Ограничение итераций останавливает цикл | WORKS (`shouldStopLoop`) |
| 11 | Ошибка API на одной итерации завершает ход сообщением об ошибке | WORKS (catch-блок ChatPanelView:902-913) |

## Найденные дефекты

### BUG-30-01 (MEDIUM, FIXED): tool-преамбула без projectRoot
**Было:** `MiCoderAutoFreeProvider.streamChat` (строка 170) вызывает `MiCoderAutoFreeClient.toolUsagePreamble()` БЕЗ аргументов — модель не знает working directory/git context, в отличие от web-ветки (`WebToolProtocolEmulator.systemPreamble` передаёт `projectRoot`).
**Следствие:** бесплатная модель получает меньше контекста, чем web-модель, для того же запроса.
**Fix:** `toolUsagePreamble(projectRoot:isGitRepo:)` — параметры передаются от caller.

### BUG-30-02 (HIGH, FIXED): бесконечный цикл в первой версии ARCH-06 fix
**Было:** Первая версия `resolvedPath` (ARCH-06) walk-up через `URL.deletingLastPathComponent()` зависала навечно на путях с trailing `..` (`/proj/..` → `deletingLastPathComponent()` возвращает `/proj/..` — no-op). Плюс lexical-guard `stack.count > 1` неверно обрабатывал `..` над единственным компонентом, а walk-up терял missingTail.
**Обнаружение:** Регрессионный полный прогон завис на 200% CPU; `sample` показал 100% времени в `resolvedPath` строки 426-427. Изолированный targeted-тест прошёл — дефект проявлялся только на specific inputs (`../x`).
**Fix v2:** Трёхэтапная резолюция: (1) realpath существующих; (2) lexical-резолюция `..`/`.` (guard `!stack.isEmpty`) + realpath; (3) walk-up по longest-existing-ancestor с сохранением missingTail.
**Тесты:** 10 канонических кейсов (9 symlink/boundary + `dotDotPathsRejectOrAcceptLexically`). Полный прогон 2298/359 GREEN.
**SDLC-урок:** «код существует и компилируется» ≠ «работает»: первый фикс сам ввёл дефект хуже исходного (hang vs wrong-reject). Полный прогон после КАЖДОГО фикса обязателен — это единственное, что поймало его.

### BUG-30-02b (LOW, ACCEPTED-RISK): нет approval UX в auto-free ветке
В отличие от web-ветки (где `approvalSignal` показывает диалог), auto-free ветка возвращает в model текст "requires approval" без UI-диалога. Это осознанное упрощение: gate НЕИЗМЕННО блокирует исполнение; модель просто информируется. Зафиксировано как ограничение, не дефект безопасности.

### BUG-30-03 (MEDIUM, FIXED): hasAPIKey после Keychain-миграции (ARCH-04)
**Было:** `addCustomProvider`/`updateCustomProvider` очищают in-memory `apiKey` после сохранения в Keychain → `SendReadinessLogic` (проверка `$0.apiKey`) и `SendRouteResolver:60` видели пустой ключ до перезапуска → кастомный провайдер с валидным ключом блокировался/шёл без Authorization.
**Fix:** in-memory копия сохраняет ключ (или восстанавливает из Keychain); `SendRouteResolver` резолвит через `getSecureAPIKey()`. Регрессионный тест `customProviderWithKeychainOnlyKeyStillRoutesWithKey`.

## User Stories

### US-AF-01: Agentic tool loop
**User story:** Как пользователь, я хочу, чтобы бесплатная модель могла читать/писать/запускать в моём проекте, как полноценный агент.
**Ожидаемое поведение (из кода):** send → 15 итераций max; каждая итерация: stream → parse tool calls → validate → execute → tool_result обратно; финальный ответ без tool-block завершает цикл.
**Тест:** `WebProviderTests` (parse/stop-loop), `MiCoderAutoFreeAgenticFlowTests`, ручная отправка. Результат: GREEN.

### US-AF-02: Мультиформатный tool-call парсинг
**User story:** Модель должна вызывать инструменты тем форматом, который ей удобен.
**Ожидаемое поведение:** ```tool JSON (args|arguments), XML `ARGE`, informal `[tool call: X with k="v"]`; multiline-whitespace tolerante.
**Тест:** `WebProviderTests.parseToolCalls*`, commit 55d3a50 regression. GREEN.

### US-AF-03: Гейт безопасности доступа
**User story:** Модель не должна уметь изменить мой проект без моего уровня доступа.
**Ожидаемое поведение:** `WebToolAccessGate.permission` — read-only всегда; write при askBeforeChanges → requireApproval (не исполняется); run_command только read-only команды на уровнях ниже fullAccess.
**Тест:** `WebToolAccessGateTests`, `ProjectWebToolExecutorTests`. GREEN.

### US-AF-04: Path boundary + symlink
**User story:** Инструменты не должны читать/писать вне project root.
**Ожидаемое поведение:** относительные пути резолвятся в root; `../` и absolute-пути вне root отклоняются; symlink внутри root НЕ может вывести наружу (после ARCH-06 fix).
**Тест:** `pathInsideRootHandlesAbsoluteAndRelative`, `symlinkInsideRootPointingOutsideIsRejected`, `symlinkedRootItselfStillResolves`, `missingWriteTargetInsideRootStillPasses`. GREEN (4 новых теста).

### US-AF-05: Накопление reasoning и spoiler parts
**User story:** Весь ход, включая промежуточные tool-итерации, должен быть виден в одном ответе.
**Ожидаемое поведение:** reasoning складывается по итерациям; tool calls копятся в `parts`; финал: content = последний ответ, parts = все tool calls, reasoning = сумма.
**Тест:** commits 5e35d2d/4f17775 (были баги reset/replacement — исправлены), `MessageFlowTests`. GREEN.

## Связанные дефекты из 29-architecture
- ARCH-04 (hasAPIKey) — FIXED в этой activity (см. BUG-30-03)
- ARCH-06 (symlink) — FIXED в этой activity (US-AF-04)
