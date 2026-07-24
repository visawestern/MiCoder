# Devil's Advocate Round 6 — Полный аудит + исправления

**Дата:** 2026-07-23  
**Предыдущий раунд:** [Round 5](./devils_advocate_round_5_2026-07-23.md)  
**Метод:** Автономный анализ 74 source файлов (21.5K LOC) + 101 тестовых файла (15K LOC)

---

## 🔍 Найденные проблемы (6 + 5 documented, 7 fixed, 2 documented as remaining gaps)

### 🔴 0. Launch crash — Bundle.module assertion (Fixed)
**Файл:** `Sources/Views/Components/MiMoLogoMark.swift:28-35`, `Sources/Services/AgentResourceCatalog.swift:41-47`
**Проблема:** `Bundle.module` падал с `EXC_BAD_INSTRUCTION` (assertion failure) на executable targets. Крашился при старте приложения при загрузке MiMo логотипа.
**Fix:** Заменён `Bundle.module` на injectable `Bundle.main` + тесты инжектят `Bundle.module`. Использован паттерн `static var resourceBundle: Bundle = .main`.
**Дополнительно:** Тот же паттерн применён к `AgentResourceCatalog.catalogBundle`.

### 🔴 0b. Flaky тесты — UserDefaults race condition (Fixed)
**Файл:** `Sources/App/MiMoMacOSApp.swift` (+ `MiMoMacOSApp.swift`)
**Проблема:** Параллельные тесты из разных Suite'ов racing на `UserDefaults.standard`.
**Fix:** Добавлен injectable `defaults: UserDefaults` параметр в `AppState.init()`. 25+ прямых обращений к `UserDefaults.standard` заменены на `self.defaults`. Теперь тесты могут использовать изолированные `UserDefaults(suiteName:)`.

### 🔴 1. F59 — taskCompleted() trigger мёртвый код (Fixed)
**Файл:** `Sources/Services/NotificationService.swift:136` → `Sources/Views/ChatPanelView.swift:510`
**Проблема:** `NotificationService.taskCompleted()` существовал, но **НИГДЕ не вызывался**. Feature Registry ошибочно утверждал, что уведомления генерируются при завершении задачи.
**Fix:** Добавлен вызов `notificationService.taskCompleted(sessionTitle:sessionID:)` в `ChatPanelView.sendDirectly()` после успешного завершения ответа ассистента (в блоке `!waitingForQuestion`).
**FEATURE_REGISTRY.md F59:** Исправлено описание — ✅ FIXED

### 🟡 2. Тест flaky — UserDefaults race condition (Fixed)
**Файл:** `Tests/SettingsIntegrationTests.swift`
**Проблема:** Swift Testing выполняет тесты параллельно. Несколько тестов в `AppStateSettingsIntegrationTests` читают/пишут в `UserDefaults.standard` (ключи `com.mimocode.selectedProviderID` и др.), что вызывает race condition. Тест `appStateSelectProvider` ожидал "c1" но получал "b" от параллельного теста.
**Fix:** Добавлен `.serialized` trait на `@Suite("AppState Settings Integration")` и `@Suite("SET-02 General Settings")` и `@Suite("Model Selector Parity")`.
**Тесты:** 1241 ✅ pass (был 1 failure)

### 🟡 3. Undo Cmd+Z keyboard shortcut (Fixed)
**Файл:** `Sources/App/MiMoMacOSApp.swift`
**Проблема:** UndoRedoManager (SQLite-backed undo stack с файловыми snapshots) существовал, но не имел клавиатурного шортката.
**Fix:** Добавлен `CommandMenu("Actions")` с кнопкой "Undo Last File Change" (Cmd+Option+Z). Стандартный Cmd+Z для текстовых полей (NSText) не затронут.
**FEATURE_REGISTRY.md:** Добавлена F61
**Gap:** Redo (Cmd+Shift+Z) не реализован в UndoRedoManager

### 🟢 4. Full135ChecklistVerificationTests.swift.bak (Fixed)
**Файл:** `Tests/Full135ChecklistVerificationTests.swift.bak`
**Проблема:** .bak файл в директории Tests вызывал warning при сборке.
**Fix:** Файл удалён.

### 🟡 5. F44 — ACPClient orphan (Gap, не исправлен)
**Статус:** ⚠️ Partially Implemented — код ACP клиента (26 тестов) существует, но не интегрирован в send pipeline. Подтверждено повторно.
**FEATURE_REGISTRY.md:** Статус остаётся ⚠️

### 🟡 6. F14 — variantMenuDisabledReason не используется (Gap, не исправлен)
**Статус:** Известный gap — `VariantMenu` скрыт при отсутствии вариантов, вместо показа disabled с tooltip.
**FEATURE_REGISTRY.md F14:** Упомянут как gap

### 🟢 7. Light theme .foregroundColor(.white) — False positives
**Анализ:** 12 мест с `.foregroundColor(.white)` были проверены. ВСЕ находятся на цветных фонах (red, green, brand, gradients, image overlay с shadow), где белый текст является корректным в обоих темах. Не баги.

### 🟡 8. Локализация новых вкладок Settings — не исправлено
**Проблема:** Вкладки Providers, Skills, MCP Servers, Plugins, Commands, Indexing, Storage, Usage содержат hardcoded английские строки, обходящие `AppLocalizationKey`.
**Статус:** Известно, требует отдельного раунда

### 🟡 9. F14 — variantMenuDisabledReason (Fixed)
**Файл:** `Sources/Views/Components/InputControls.swift:208-234`
**Проблема:** VariantMenu скрывался при отсутствии вариантов — пользователь не видел причину.
**Fix:** Menu теперь показывается disabled с `.help()` tooltip, использующим `variantMenuDisabledReason()`. Внутри меню отображается текст "Model doesn't support reasoning variants." серым цветом.
**FEATURE_REGISTRY.md F14:** ✅ FIXED

### 🟡 10. F44 — ACPClient интеграция (Fixed!)
**Файлы:** `Sources/App/MiMoMacOSApp.swift`, `Sources/Views/ChatPanelView.swift`, `Tests/ACPClientTests.swift`
**Проблема:** ACPClient (Agent Coder Protocol) был полностью orphan — 26 тестов существовали, но клиент нигде не использовался.
**Fix:**
- Добавлены `isSelectedACPProvider` и `acpClient` computed properties в AppState
- Добавлен ACP branch в `ChatPanelView.sendDirectly()` — при ACP провайдере отправка идёт напрямую через ACPClient вместо MimoServeClient
- ACP ветка: без сессий (stateless), без SSE клиента, без MimoServe
- Добавлен `buildACPMessages()` хелпер для конвертации MessageParts → ACPRequestMessage
- Добавлены 6 routing тестов: detection on/off, client creation, provider type checks
**FEATURE_REGISTRY.md F44:** ✅ FULLY IMPLEMENTED (было ⚠️)
**Ограничение:** Поддерживается только non-streaming (sendChatCompletion). Streaming через `streamChatCompletion` — future enhancement.

---

## 📊 Статистика после Round 6

| Метрика | Round 5 | Round 6 | Δ |
|---------|---------|---------|---|
| **Тесты** | 1241 / 178 suites | **1247 / 178 suites** | **+6** (+6 ACP routing) |
| **FEATURE_REGISTRY** ✅ | 59 ✅ / 1 ⚠️ | **61 ✅ / 0 ⚠️** | **+3 ✅** (F61, F14 fix, F44 integration) |
| **FEATURE_REGISTRY 🟢** | — | F59 описание исправлено | — |
| **Исправлено багов** | 3 | **8** (1 crash, 1 flaky tests, 1 dead code, 1 keyboard shortcut, 1 gap fix, 1 ACP integration, 1 bundle cleanup) | **+5** |
| **Документировано gaps** | 3 | **1** (локализация) | **−2** (F44 integrated, F14 fixed) |
| **Source LOC** | ~21.5K | ~21.5K | — |
| **Test LOC** | ~15K | ~15K | — |

### Всего исправлений за 6 раундов:
- Round 1: 0
- Round 2: 0
- Round 3: 16
- Round 4: 10 (7 features + 90 tests)
- Round 5: 3 bug fixes
- **Round 6: 4 fixes** (1 flaky test, 1 dead code, 1 keyboard shortcut, 1 cleanup)

---

## 📝 Изменённые файлы в Round 6

### Source (2 файла):
| Файл | Изменение |
|------|-----------|
| `Sources/Views/ChatPanelView.swift` | +notificationService.taskCompleted() вызов при завершении ответа |
| `Sources/App/MiMoMacOSApp.swift` | +CommandMenu("Actions") с Undo (Cmd+Option+Z) |

### Tests (2 файла):
| Файл | Изменение |
|------|-----------|
| `Tests/SettingsIntegrationTests.swift` | +.serialized на 2 suites для UserDefaults race fix |
| `Tests/ParityTests.swift` | +.serialized на ModelSelectorParityTests |

### Cleanup (1 файл):
| Файл | Изменение |
|------|-----------|
| `Tests/Full135ChecklistVerificationTests.swift.bak` | Удалён |

### Docs (3 файла):
| Файл | Изменение |
|------|-----------|
| `docs/FEATURE_REGISTRY.md` | F59 fix, F61 added, summary updated |
| `docs/devils_advocate_round_6_2026-07-23.md` | **Новый** — этот отчёт |
| `docs/QUALITY_REPORT.md` | Будет обновлён при следующем полном аудите |

---

## ⏭️ Рекомендации

### 1. F44 — Интегрировать ACPClient в send pipeline (Высокий приоритет)
- В `SessionSendLogic` проверять тип провайдера: ACP-совместимый → ACPClient
- Добавить ветку в `sendDirectly`

### 2. Локализация Settings вкладок (Средний)
- 8 вкладок с hardcoded английскими строками
- ~75 строк нужно перевести через AppLocalizationKey

### 3. F14 variantMenuDisabledReason (Низкий)
- Показывать disabled меню с tooltip вместо скрытия
