# Web Providers — Complete Mode & Model Detection Plan

> Research completed: 2026-08-10
> All modes discovered via Playwright headless

---

## Final Research Results

### Kimi (Moonshot AI)

**Models (2 main):**
1. **Instant** — Fast chat, quick replies
2. **K3** — Chat & Agent, flagship all-rounder
3. K3 Swarm (may appear after expand or in specific context)

**Effort/Thinking:**
- Levels: High, Low
- Selector class: `current-effort`

**Chat Input Area:**
- Model button: `div.current-model`
- Language switcher: `language-switch`

### Qwen (Alibaba Cloud)

**Models (3):**
1. Qwen3.8-Max — Flagship, state-of-the-art
2. Qwen3.7-Plus — High-performance LLM
3. Qwen3.7-Max — Max capability

**Mode Select (dropdown):**
1. Upload attachment (file, image, video, audio)
2. **Deep Research**
3. **Create Image** (Qwen-Image 2.0)
4. Create Video (may be disabled)
5. **Web Dev**
6. Slides (may be disabled)
7. More (submenu)
8. Tools

**Thinking Selector:**
1. **Auto** (default)
2. **Thinking** (deep reasoning)
3. **Fast** (quick responses)

**Selectors:**
- Model: `[class*="model-selector-text"]`
- Mode: `[class*="mode-select"]`
- Thinking: `[class*="qwen-select-thinking"]`
- Items: `.ant-select-item-option-content`

---

## Implementation Plan

### Step 1: Update Data Models

**File:** `WebProviderConfig.swift`

```swift
struct WebProviderModel: Codable, Equatable, Identifiable {
    var id: String { name }
    let name: String
    let description: String?
    var availableModes: [String]      // ["auto", "think", "fast", "image"]
    var supportsImageGeneration: Bool
    var supportsDeepResearch: Bool
    var supportsWebDev: Bool
}

struct WebProviderConfig: Codable, Identifiable, Equatable {
    // ... existing fields ...

    // Enhanced storage
    var discoveredModels: [WebProviderModel]  // Was [String]
    var manuallyAddedModels: [String]
    var discoveredFeatureModes: [FeatureMode]
    var discoveredEffortLevels: [WebEffort]
    var customModelSelector: String?
}

struct FeatureMode: Codable, Equatable, Identifiable {
    var id: String { name }
    let name: String              // "Deep Research", "Create Image", etc.
    let icon: String?             // SF Symbol or emoji
    let isEnabled: Bool
}
```

### Step 2: Enhanced Model Discovery

**File:** `WebModelDiscovery.swift`

```swift
struct DiscoveryResult {
    let models: [WebProviderModel]
    let effortLevels: [WebEffort]
    let featureModes: [FeatureMode]
}

static func discoverAll(using bridge: BrowserBridge, config: WebProviderConfig) async -> DiscoveryResult {
    async let models = discoverModels(bridge: bridge, vendor: config.vendor)
    async let effort = discoverEffort(bridge: bridge, vendor: config.vendor)
    async let modes = discoverFeatureModes(bridge: bridge, vendor: config.vendor)
    return await DiscoveryResult(models: models, effort: effort, featureModes: modes)
}

static func discoverModes(bridge: BrowserBridge, vendor: WebChatVendor) async -> [WebProviderModel] {
    switch vendor {
    case .kimi:
        return await discoverKimiModels(bridge: bridge)
    case .qwen:
        return await discoverQwenModels(bridge: bridge)
    default:
        return []
    }
}

static func discoverQwenModes(bridge: BrowserBridge) async -> [FeatureMode] {
    // Click mode-select dropdown
    try? await bridge.click(selector: "[class*='mode-select']")
    try? await bridge.waitForSelector(selector: ".ant-select-item-option", timeout: 5000)

    let modes = await bridge.evaluateJS("""
        Array.from(document.querySelectorAll('.ant-select-item-option-content'))
            .map(el => ({
                name: el.textContent.trim(),
                disabled: el.closest('.ant-select-item')?.classList.contains('ant-select-item-disabled')
            }))
    """)

    return modes?.compactMap { dict in
        guard let name = dict["name"] as? String else { return nil }
        return FeatureMode(name: name, icon: iconForMode(name), isEnabled: !(dict["disabled"] as? Bool ?? false))
    } ?? []
}

static func discoverQwenThinking(bridge: BrowserBridge) async -> [WebEffort] {
    // Click thinking selector
    try? await bridge.click(selector: "[class*='qwen-select-thinking']")
    try? await bridge.waitForSelector(selector: ".ant-select-item-option", timeout: 5000)

    let levels = await bridge.evaluateJS("""
        Array.from(document.querySelectorAll('.ant-select-item-option-content'))
            .map(el => el.textContent.trim())
    """)

    return levels?.compactMap { WebEffort.fromLabel($0) } ?? []
}
```

### Step 3: Mode Selector UI

**File:** `WebProvidersSection.swift`

```swift
struct ModeSelectorView: View {
    @Binding var config: WebProviderConfig
    @State private var selectedMode: String = "auto"
    @State private var selectedThinking: String = "auto"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Model selector
            if !config.discoveredModels.isEmpty {
                Text(L.t(AppLocalizationKey.locModel))
                    .interfaceFont(size: 11, weight: .medium)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(config.discoveredModels) { model in
                            ModelPill(model: model, isSelected: model.name == config.selectedModel) {
                                config.selectedModel = model.name
                            }
                        }
                    }
                }
            }

            // Thinking/Effort selector
            if !config.discoveredEffortLevels.isEmpty {
                Text(L.t(AppLocalizationKey.locThinkingMode))
                    .interfaceFont(size: 11, weight: .medium)
                Picker("", selection: $selectedThinking) {
                    ForEach(config.discoveredEffortLevels, id: \.self) { level in
                        Text(level.displayName).tag(level.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Feature modes (Qwen: Deep Research, Create Image, etc.)
            if !config.discoveredFeatureModes.isEmpty {
                Text(L.t(AppLocalizationKey.locFeatureModes))
                    .interfaceFont(size: 11, weight: .medium)
                FlowLayout(spacing: 8) {
                    ForEach(config.discoveredFeatureModes) { mode in
                        FeatureModeToggle(mode: mode)
                    }
                }
            }
        }
    }
}
```

### Step 4: Model Switching in Chat

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
    if !clicked { throw WebChatError.modelNotFound(modelName) }
}

func selectMode(_ mode: String) async throws {
    switch config.vendor {
    case .qwen:
        try await bridge.click(selector: "[class*='mode-select']")
        try await bridge.clickByText(selector: ".ant-select-item-option-content", text: mode)
    case .kimi:
        // Kimi modes are in sidebar
        try await bridge.clickByText(selector: "a, button, [role='button']", text: mode)
    default:
        break
    }
}

func selectThinking(_ level: WebEffort) async throws {
    switch config.vendor {
    case .qwen:
        try await bridge.click(selector: "[class*='qwen-select-thinking']")
        try await bridge.clickByText(selector: ".ant-select-item-option-content", text: level.displayName)
    case .kimi:
        try await bridge.click(selector: "[class*='effort']")
        try await bridge.clickByText(selector: "[class*='effort-option'], [role='option']", text: level.displayName)
    default:
        break
    }
}
```

### Step 5: Complete Localization

**New keys to add (30+):**

```swift
// Mode switches
locMode                  → "Mode" / "Режим"
locThinkingMode          → "Thinking Mode" / "Режим мышления"
locFeatureModes          → "Feature Modes" / "Режимы работы"
locAuto                  → "Auto" / "Авто"
locThink                 → "Think" / "Думание"
locFast                  → "Fast" / "Быстро"

// Qwen specific
locDeepResearch          → "Deep Research" / "Глубокое исследование"
locCreateImage           → "Create Image" / "Создать изображение"
locCreateVideo           → "Create Video" / "Создать видео"
locWebDev                → "Web Dev" / "Веб-разработка"
locTools                 → "Tools" / "Инструменты"
locUpload                → "Upload" / "Загрузить"
locMore                  → "More" / "Ещё"
locSlides                → "Slides" / "Слайды"

// Kimi specific
locInstant               → "Instant" / "Мгновенный"
locK3                    → "K3" / "K3"
locK3Swarm               → "K3 Swarm" / "K3 Рой"

// Effort
locThinkingEffort        → "Thinking effort" / "Интенсивность рассуждений"
locEffortHigh            → "High" / "Высокий"
locEffortLow             → "Low" / "Низкий"

// Picker
locPickerTitle           → "Picked Element" / "Выбранный элемент"
locPickerSelector        → "Selector:" / "Селектор:"
locPickerTag             → "Tag:" / "Тег:"
locPickerClass           → "Class:" / "Класс:"
locPickerText            → "Text:" / "Текст:"
locUseAsModelSelector    → "Use as Model Selector" / "Использовать как селектор модели"

// Misc
locTosViolation          → "I understand this may violate..." / "Я понимаю, что это может нарушить..."
locModelsCount           → "%d models" / "%d моделей"
locActiveCount           → "%d active" / "%d активных"
locArchivedCount         → "%d archived" / "%d в архиве"
locMessageCount          → "%d msg" / "%d сообщ."
locToolCallDelay         → "Tool-call delay" / "Задержка вызова инструментов"
locKeepalive             → "Keep-alive" / "Поддержание соединения"
```

### Step 6: Execution Order

| # | Task | Time | Priority |
|---|------|------|----------|
| 1 | Update data models (WebProviderConfig, FeatureMode) | 15 min | P0 |
| 2 | Implement enhanced discovery (Qwen modes, Kimi effort) | 25 min | P0 |
| 3 | Build ModeSelectorView UI | 20 min | P0 |
| 4 | Implement selectModel/selectMode/selectThinking | 20 min | P0 |
| 5 | Add 30+ localization keys | 20 min | P1 |
| 6 | Replace all hardcoded strings | 15 min | P1 |
| 7 | TDD tests | 20 min | P2 |
| 8 | Build + commit | 5 min | — |

**Total: ~2.5 hours**

---

## Success Criteria

- [ ] Qwen: detect 3 models + Deep Research + Create Image + Web Dev + Tools
- [ ] Qwen: detect thinking levels (Auto/Thinking/Fast)
- [ ] Kimi: detect Instant + K3 + K3 Swarm models
- [ ] Kimi: detect effort levels (High/Low)
- [ ] UI: Mode selector with pills/toggles
- [ ] Chat: can switch models, modes, thinking levels
- [ ] All hardcoded strings localized (30+ keys)
- [ ] Tests pass
