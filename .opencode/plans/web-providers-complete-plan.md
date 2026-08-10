# Web Providers — Complete Feature Research & Implementation Plan

> Research Date: 2026-08-10
> Tested via Playwright (headless) against live Kimi + Qwen

---

## Research Results

### Kimi (Moonshot AI)

**Sidebar Navigation (feature modes):**
1. My Kimi
2. Scheduled Tasks
3. **Swarm** (multi-agent)
4. **Slides** (presentation)
5. **Deep Research**
6. Websites
7. Docs
8. Sheets
9. Design
10. Kimi Work
11. Kimi Code

**Chat Models (3):**
1. Быстрый — Fast chat, instant answers
2. K3 — Universal flagship for chat + agent tasks
3. K3 Swarm — Scale search, batch processing

**Effort/Thinking:**
- "Интенсивность рассуждений" (Thinking effort)
- Levels: Высокий (High), Низкий (Low)

**Feature Modes (in-chat):**
- Slides
- Deep Research

### Qwen (Alibaba Cloud)

**Chat Models (3):**
1. Qwen3.8-Max — Flagship, state-of-the-art
2. Qwen3.7-Plus — High-performance LLM
3. Qwen3.7-Max — Max capability

**Mode Selector:**
- "Создать изображение" (Create image) — toggles image generation
- Qwen-Image 2.0 with aspect ratios (16:9, etc.)

**No sidebar in chat view** — modes are inline

---

## Implementation Plan

### Phase 1: Enhanced Data Model

```swift
// WebProviderConfig.swift
struct WebProviderConfig: Codable, Identifiable, Equatable {
    // ... existing fields ...

    // Enhanced model storage
    var discoveredModels: [WebProviderModel]  // Was [String]
    var manuallyAddedModels: [String]
    var discoveredEffortLevels: [WebEffort]
    var customModelSelector: String?

    // NEW: Feature modes per provider
    var discoveredFeatureModes: [FeatureMode]
}

struct WebProviderModel: Codable, Equatable {
    let name: String
    let description: String?
    var availableModes: [String]      // ["auto", "think", "fast", "image"]
    var supportsImageGeneration: Bool
    var supportsDeepThinking: Bool
}

struct FeatureMode: Codable, Equatable {
    let id: String          // "slides", "deep_research", "swarm"
    let name: String        // "Slides", "Deep Research"
    let icon: String?       // SF Symbol name
    let isAvailable: Bool
}
```

### Phase 2: Kimi Feature Mode Detection

**File:** `WebModelDiscovery.swift`

```swift
static func discoverFeatureModes(using bridge: BrowserBridge, vendor: WebChatVendor) async -> [FeatureMode] {
    guard vendor == .kimi else { return [] }

    // Kimi has sidebar with feature modes
    let sidebarSelectors = [
        "a:has-text('Slides')",
        "a:has-text('Deep Research')",
        "a:has-text('Swarm')",
        "[class*='sidebar'] a, [class*='nav'] a"
    ]

    // Read sidebar items
    let modes = await bridge.evaluateJS("""
        Array.from(document.querySelectorAll('[class*="sidebar"] a, [class*="nav"] a, [class*="sidebar"] button'))
            .map(el => el.textContent.trim())
            .filter(t => t.length > 0 && t.length < 40)
    """)

    return modes.map { modeName in
        FeatureMode(
            id: modeName.lowercased().replacingOccurrences(of: " ", with: "_"),
            name: modeName,
            icon: iconForFeature(modeName),
            isAvailable: true
        )
    }
}

static func discoverEffortLevels(using bridge: BrowserBridge) async -> [WebEffort] {
    // Click effort selector
    try? await bridge.click(selector: "[class*='effort']")
    try? await bridge.waitForSelector(selector: "[class*='effort-option'], [role='option']")

    let levels = await bridge.evaluateJS("""
        Array.from(document.querySelectorAll('[class*="effort"] [class*="option"], [class*="effort"] [role="option"]'))
            .map(el => el.textContent.trim())
            .filter(t => t.length > 0 && t.length < 30)
    """)

    return levels.compactMap { WebEffort.fromLabel($0) }
}
```

### Phase 3: Custom Mode Selector UI

**File:** `WebProvidersSection.swift`

```swift
struct ModeSelectorView: View {
    @Binding var config: WebProviderConfig
    @State private var selectedMode: String = "auto"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.t(AppLocalizationKey.locMode))
                .interfaceFont(size: 11, weight: .medium)

            // Mode pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(availableModes, id: \.self) { mode in
                        ModePill(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            action: { selectedMode = mode }
                        )
                    }
                }
            }

            // Feature modes (Kimi-specific)
            if config.vendor == .kimi && !config.discoveredFeatureModes.isEmpty {
                Text(L.t(AppLocalizationKey.locFeatureModes))
                    .interfaceFont(size: 11, weight: .medium)
                ForEach(config.discoveredFeatureModes, id: \.id) { mode in
                    FeatureModeRow(mode: mode)
                }
            }
        }
    }
}

struct ModePill: View {
    let mode: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(mode)
                .interfaceFont(size: 10)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.mimo.brand : Color.mimo.surface)
                .foregroundColor(isSelected ? .white : Color.mimo.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
```

### Phase 4: Model Switching in Chat

**File:** `WebChatDriver.swift`

```swift
func selectModel(_ modelName: String) async throws {
    guard let catalog = try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id) else { return }

    // Click model button
    try await bridge.click(selector: catalog.modelButton ?? catalog.modelDropdown)
    try await bridge.waitForSelector(selector: "div.model-item, [class*='model-item']", timeout: 5000)

    // Find and click matching model
    let clicked = try await bridge.clickByText(
        selector: "div.model-item, [class*='model-item']",
        text: modelName
    )

    if !clicked {
        throw WebChatError.modelNotFound(modelName)
    }
}

func selectMode(_ mode: String) async throws {
    // For Kimi: click sidebar item or mode pill
    // For Qwen: click mode selector
    switch config.vendor {
    case .kimi:
        try await bridge.clickByText(selector: "a, button, [role='button']", text: mode)
    case .qwen:
        try await bridge.click(selector: "[class*='mode-select']")
        try await bridge.clickByText(selector: "[class*='option'], [role='option']", text: mode)
    default:
        break
    }
}
```

### Phase 5: Complete Localization

**New keys to add (20+):**

```swift
// Feature modes
locSlides              → "Slides" / "Слайды"
locDeepResearch        → "Deep Research" / "Глубокое исследование"
locSwarm               → "Swarm" / "Рой"
locImageGeneration     → "Image Generation" / "Создание изображений"
locMode                → "Mode" / "Режим"
locFeatureModes        → "Feature Modes" / "Режимы работы"
locAuto                → "Auto" / "Авто"
locThink               → "Think" / "Думание"
locFast                → "Fast" / "Быстро"

// Effort
locThinkingEffort      → "Thinking effort" / "Интенсивность рассуждений"
locEffortHigh          → "High" / "Высокий"
locEffortLow           → "Low" / "Низкий"

// Picker
locPickerTitle         → "Picked Element" / "Выбранный элемент"
locPickerSelector      → "Selector:" / "Селектор:"
locPickerTag           → "Tag:" / "Тег:"
locPickerClass         → "Class:" / "Класс:"
locPickerText          → "Text:" / "Текст:"
locUseAsModelSelector  → "Use as Model Selector" / "Использовать как селектор модели"

// Misc
locTosViolation        → "I understand this may violate..." / "Я понимаю что это может нарушить..."
locModelsCount         → "%d models" / "%d моделей"
locActiveCount         → "%d active" / "%d активных"
locArchivedCount       → "%d archived" / "%d в архиве"
locMessageCount        → "%d msg" / "%d сообщ."
```

### Phase 6: Execution Order

| Step | Task | Time |
|------|------|------|
| 1 | Update data model (WebProviderConfig) | 15 min |
| 2 | Implement Kimi feature mode detection | 20 min |
| 3 | Implement effort level detection | 15 min |
| 4 | Build ModeSelectorView UI | 20 min |
| 5 | Implement model/mode switching in WebChatDriver | 20 min |
| 6 | Add 20+ localization keys | 15 min |
| 7 | Replace hardcoded strings | 15 min |
| 8 | TDD tests | 20 min |
| 9 | Build + commit | 5 min |

**Total: ~2.5 hours**

---

## Success Criteria

- [ ] Kimi: detect 3 models + Slides/Deep Research/Swarm modes
- [ ] Qwen: detect 3 models + Image generation mode
- [ ] Effort levels detected for both
- [ ] Custom mode selector UI in settings
- [ ] Model/mode switching works in chat
- [ ] All hardcoded strings localized
- [ ] Tests pass
