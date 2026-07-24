# Devil's Advocate Round 5 — Полный аудит + исправления

**Дата:** 2026-07-23  
**Предыдущий раунд:** [Round 4](./devils_advocate_round_4_2026-07-22.md)  
**Метод:** Полная цепочечная верификация: docs → код → тесты, каждый пункт вручную

---

## 🔍 Найденные проблемы (6)

### 🔴 1. Добавление вкладки Providers сломало тесты (Fixed)
**Файл:** `Tests/SettingsIntegrationTests.swift`
**Проблема:** 
- `SettingsTab.allCases.count` ожидал 11 → стало 12 → **тест упал**
- `appStateSetLanguage` — флаки тест из-за параллельного доступа к UserDefaults

**Fix:** Обновлены assertions, сделан тест устойчивее к параллельному выполнению
```swift
// count 11 → 12
#expect(SettingsTab.allCases.count == 12)
// expected array now includes .providers
```

### 🔴 2. ProvidersSettingsView — .constant вместо @State (Fixed)
**Файл:** `Sources/Views/SettingsView.swift:2088-2094`
**Проблема:** `AddProviderSheet` вызывался с `.constant("")` для name/url/apiKey и `.constant(.openAI)` для type:
```swift
AddProviderSheet(
    isPresented: $showAddProvider,       // ✅ работает
    name: .constant(""),                  // ❌ Binding, но константа — ввод игнорировался
    type: .constant(.openAI),             // ❌ тип не менялся
    url: .constant(""),                   // ❌ URL не сохранялся
    apiKey: .constant("")                 // ❌ API key не сохранялся
)
```
**Fix:** Добавлены `@State private var` и переданы как `$newProviderName` и т.д.

### 🟡 3. ProviderRowView — delete button невидим (Fixed)
**Файл:** `Sources/Views/SettingsView.swift:2229-2240`
**Проблема:** Кнопка удаления провайдера имела `.opacity(option.isConnected ? 0 : 1)`. Поскольку `isConnected` для кастомных провайдеров всегда `true` (только enabled попадают в список), кнопка была **всегда невидима**.
**Fix:** Заменено на `.opacity(option.isCustom ? 1 : 0)` — кнопка видна только для кастомных провайдеров.

### 🟡 4. ACPClient — полный orphan (Gap, не исправлен)
**Файл:** `Sources/Services/ACPClient.swift`
**Проблема:** Полноценный ACP-клиент (26 тестов, full streaming, error handling, health check) существует, но **НИГДЕ не интегрирован** в пайплайн отправки сообщений:
- `ChatPanelView.sendDirectly` всегда вызывает `appState.mimoClient.sendMessage()`
- Ни один View или Service не создаёт/использует `ACPClient`
- toggle `acpEnabled` в CustomProvider существует, но нигде не проверяется в send flow

**FEATURE_REGISTRY.md:** "F44: ✅ Implemented" — ❌ **НЕВЕРНО**. Клиент есть, но не интегрирован.
**Статус:** ⚠️ Partially Implemented (код есть, интеграции нет)

### 🟡 5. Undo Cmd+Z keyboard shortcut (Gap, известный)
**Файл:** `Sources/Services/UndoRedoManager.swift`
**Проблема:** UndoRedoManager существует (SQLite-backed undo stack), но не подключён к UI — нет клавиатурного шортката Cmd+Z.
**FEATURE_REGISTRY:** Не упоминается как отдельная фича
**Статус:** Known gap (QUALITY_REPORT п. 4.3)

### 🟢 6. variantMenuDisabledReason не используется (Gap, известный)
**Файл:** `Sources/Services/ProviderCapabilityGates.swift`
**Проблема:** Функция `variantMenuDisabledReason()` существует, но VariantMenu в `InputControls.swift` просто скрывается при отсутствии вариантов — без объяснения причины.
**FEATURE_REGISTRY F14:** Упомянут как gap
**Статус:** Known gap (F14 в FEATURE_REGISTRY)

---

## 📊 Статистика после Round 5

| Метрика | Round 4 | Round 5 | Δ |
|---------|---------|---------|---|
| **Тесты** | 769 / 135 suites | **1241 / 178 suites** | **+472 / +43** |
| **FEATURE_REGISTRY** ✅ | 60 ✅ / 0 ⚠️ | **59 ✅ / 1 ⚠️** (F44) | **−1 ✅ +1 ⚠️** |
| **Исправлено багов** | — | **3** (1 pre-existing, 2 новых) | **+3** |
| **Документировано gap'ов** | — | **3** (F44, Undo, F14) | **+3** |

---

## 📝 Изменённые файлы

### SettingsView.swift
- **.constant → @State import** для AddProviderSheet в ProvidersSettingsView (fix bug #2)
- **ProviderRowView delete button** opacity fix (fix bug #3)
- **Color.zcode → Color.mimo** миграция (pre-existing fix)

### SettingsIntegrationTests.swift
- **count 11 → 12** для SettingsTab.allCases (fix bug #1a)
- **Устойчивый appStateSetLanguage тест** (fix bug #1b)

### ProvidersSettingsTests.swift
- Новый файл с 21 тестом для ProviderType enhancements

---

## ⏭️ Рекомендации по исправлению gap'ов

### 1. F44 — Интегрировать ACPClient в send pipeline (Высокий приоритет)
**Что нужно:**
- В `SessionSendLogic` проверять тип провайдера: если `acpEnabled && type == .acp` → использовать `ACPClient` вместо `MimoServeClient`
- Добавить `ACPClient` как property в `AppState` (lazy init)
- В `ChatPanelView.sendDirectly` добавить ветку для ACP провайдеров
- Написать тесты: send с ACP → ACPClient.sendMessage, send с OpenAI → MimoServeClient

### 2. Undo keyboard shortcut Cmd+Z (Средний)
**Что нужно:**
- В `MiMoMacOSApp.swift` (.commands) добавить CommandGroup с keyboardShortcut("z", modifiers: .command)
- Вызов `UndoRedoManager.shared.undo(sessionId:)` через AppState

### 3. F14 variantMenuDisabledReason (Низкий)
**Что нужно:**
- Вместо `if !availableVariants.isEmpty { Menu }` показывать disabled menu с tooltip
- Использовать `variantMenuDisabledReason` для текста тултипа
