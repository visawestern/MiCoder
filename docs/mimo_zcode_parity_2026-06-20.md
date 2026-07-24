# MiMoMacOS — ZCode Functional Parity Checklist

> **Historical checklist (2026-06-20).** Stale claims corrected 2026-07-17: test count has grown to ~489 `@Test` declarations; git commit/branch/push actions are real (`commitGitChanges`/`checkoutGitBranch`/`pushGitChanges` in `MiMoMacOSApp`); the terminal runs a real `/bin/zsh -c` shell via `Process`. See `docs/FEATURE_REGISTRY.md`.

> **Goal:** Functional and layout parity with ZCode (zcode.z.ai) for mimo-auto agent coder, preserving MiMo sci-fi theme (no Z branding).
>
> **TDD loop:** failing test → implement → `swift test` → `./build-app.sh` → mark ✅

**Reference screenshots:** `screenshot_1_1.png`, `screenshot_11.png`, `screenshot_14.png`, `screenshot_2.png` … `screenshot_20.png`

---

## Блок 1: Baseline & Build (1–10)

✅ 1. Запустить `./build-app.sh`, зафиксировать ошибки  
✅ 2. Исправить все compile errors до `swift build -c release` OK  
✅ 3. Запустить `swift test`, собрать список failing suites  
✅ 4. Обновить `PlusMenuTests` под актуальный `PlusMenuItem` (+ `insertCommand`)  
✅ 5. Пометить live-тесты env-gate `MIMO_LIVE_TESTS=1`  
✅ 6. Добавить `MiMoCopy` константы (placeholder, watermark) — test first  
✅ 7. Убрать «ZCode» из UI strings — test first  
✅ 8. Скрипт `scripts/kill-mimo.sh`: `pkill -x MiMoMacOS`  
✅ 9. Документировать build loop в этом файле  
✅ 10. Блок 1 → оценка **10/10**

### Прогресс блока 1
Сборка release OK. Unit-тесты зелёные (live gated). MiMoCopy + kill script добавлены.

---

## Блок 2: Session & Data Models (11–20)

✅ 11. Тест: `sendDirectly` использует `selectedSession.id` если есть  
✅ 12. Тест: первый send без session → create + select  
✅ 13. Тест: follow-up не создаёт новую session  
✅ 14. Тест: `ChatSession.durationLabel` форматы `9m`, `2h`, `3d`  
✅ 15. Тест: `sessions(for:)` фильтрует по `directory`  
✅ 16. Реализовать session reuse в `ChatPanelView`  
✅ 17. После send — обновить `appState.sessions` и `selectedSession`  
✅ 18. SSE `message.updated` — reconcile server message id  
✅ 19. Тест: queue обрабатывается после `isLoading = false` (existing MessageQueueTests)  
✅ 20. Блок 2 → оценка **10/10**

### Прогресс блока 2
`SessionSendLogic` + `SessionReuseTests`. ChatPanelView reuses session, registers new sessions in AppState.

---

## Блок 3: Layout Shell (21–30)

✅ 21. Тест: task header visible when session selected  
✅ 22. Создать `TaskHeaderView` (title, workspace, branch, toggles)  
✅ 23. Подключить `TaskHeaderView` в `ContentView`  
✅ 24. Wire `showTerminal` / `showGoal` из header  
✅ 25. Убрать `MessageType` selector из input  
✅ 26. Status bar — не дублирует header controls  
✅ 27. Spacing/borders — sci-fi readable contrast (сохранена палитра ZCodeColors)  
✅ 28. Empty state: max-width input ~520px, без branch chip  
✅ 29. Active state: bottom input bar full width  
✅ 30. Блок 3 → оценка **10/10**

---

## Блок 4: Sidebar & Input (31–40)

✅ 31. Sidebar: New task / Search / Skills (ZCode layout)  
✅ 32. Workspaces section с nested sessions  
✅ 33. Session row hover actions (+, ellipsis, Open in Finder)  
✅ 34. Skills → settings skills tab  
✅ 35. Plus menu: `insertCommand` (`/` prefix) — TDD  
✅ 36. Access menu: icons + descriptions в dropdown  
✅ 37. Model menu: `Manage models` → settings  
✅ 38. Thinking menu: compact 3-option layout  
✅ 39. Workspace dropdown: `Open folder` → NSOpenPanel  
✅ 40. Workspace dropdown: `Remote connection` → host/port sheet  
✅ 41. Workspaces header: expand, sort, filter search, list/grid toggle  
✅ 42. Sidebar footer: avatar, user name, notifications, settings  
✅ 43. Keyboard shortcuts ⌘N / ⌘K wired in app menu  
✅ 44. Блок 4 → оценка **10/10**

---

## Блок 5: Panels, Chat, Settings (45–54)

✅ 45. Right panel: Git totals из `vcsDiff()` + session summary fallback  
✅ 46. Progress: plan/todo из TodoWrite, markdown, step markers при открытии сессии  
✅ 47. Transcript: «Worked for Xs» separators  
✅ 48. File change rows в `MessageRowView`  
✅ 49. Stop generation button wired to `stopGeneration()`  
✅ 50. Settings tabs order/icons match screenshot hierarchy  
✅ 51. Model settings: MiMo Serve providers (existing)  
✅ 52. Static settings sections: MiMo-branded copy  
✅ 53. Terminal panel: toggle from header works  
✅ 54. Auto-open right panel при выборе сессии  
✅ 55. Блок 5 → оценка **10/10**

---

## Блок 6: Verification (56–60)

✅ 56. `swift test` all green (206 tests, live gated)  
⬜ 57. `./build-app.sh` → manual visual compare vs screenshots  
⬜ 58. Manual compare sidebar vs screenshot_1_1 / screenshot_11  
⬜ 59. Fix clipped text / contrast if found in manual pass  
⬜ 60. Final parity checklist sign-off  

### Прогress блока 6
Automated tests pass. Sidebar toolbar + footer implemented. Session git/plan load on open implemented. Manual screenshot compare pending.

---

## Build Loop

```bash
pkill -x MiMoMacOS 2>/dev/null || true
swift test
./build-app.sh
open MiMoMacOS.app
```

## Remaining non-blocking gaps

- Git commit/branch actions in right panel still no-op (API not exposed)
- Terminal panel is mock shell (functional toggle only)
- `$` skills trigger in placeholder only (no autocomplete yet)
- Notifications panel shows empty state until server push/events API exists
- Manual visual parity vs screenshots not automated (items 57–60)
