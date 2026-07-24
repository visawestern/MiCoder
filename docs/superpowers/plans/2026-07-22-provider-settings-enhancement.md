# Provider Settings Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dedicated Providers tab in Settings with enhanced provider management, spoiler functionality for parameters, and improved UI with chips/counts.

**Architecture:** 
- Add Providers tab alongside existing Model Settings tab
- Create modular UI components for provider management
- Implement spoiler-expandable sections for model parameters
- Maintain backward compatibility with existing provider system

**Tech Stack:** SwiftUI, Swift, SQLite, Keychain

---

## Understanding the Current Architecture

### Current State (from codebase analysis):

1. **Providers are managed in SettingsTab with 11 tabs:**
   - general, codePreview, modelSettings, skills, mcpServers, plugins, commands, indexing, storage, usage, onboard

2. **ModelSettingsView contains both provider selection AND model browsing:**
   - Three-column layout with provider list, provider details, and model cards
   - Already has some UX improvements (chips, spoiler-like behavior in model cards)

3. **Provider types available:**
   - openAI, openRouter, openModel, ollama, anthropic, google, mistral, groq, deepseek, omni, acp

4. **Key files:**
   - `SettingsTab.swift` - enum defining settings tabs
   - `SettingsView.swift` - main settings UI with ModelSettingsView
   - `Settings.swift` - CustomProvider and ProviderType definitions
   - `ProviderSettingsLogic.swift` - business logic for providers
   - `SpoilerExpandLogic.swift` - spoiler animation/height logic
   - `AppLocalization.swift` - localization strings

---

## Implementation Task Breakdown

### Task 1: Add Providers Tab to SettingsTab

**Files:**
- Modify: `Sources/Models/SettingsTab.swift`
- Modify: `Sources/Services/AppLocalization.swift`

- [ ] **Step 1: Add providers case to SettingsTab enum**

```swift
// In SettingsTab.swift, add after .modelSettings:
case providers = "Providers"

var icon: String {
    switch self {
    // ... existing cases
    case .providers: return "server.rack" // or similar icon
    }
}
```

- [ ] **Step 2: Add localization strings**

```swift
// In AppLocalization.swift, add:
case settingsTabProviders

// In translations:
case .settingsTabProviders: return ("Providers", "Провайдеры")

// In settingsTabName function:
case .providers: return string(.settingsTabProviders, language: language)
```

- [ ] **Step 3: Update settingsView to include Providers tab**

```swift
// In SettingsView.swift, switch statement:
case .providers:
    ProvidersSettingsView()
```

---

### Task 2: Create ProvidersSettingsView

**Files:**
- Create: `Sources/Views/SettingsViews/ProvidersSettingsView.swift`
- Modify: `Sources/Views/SettingsView.swift`

- [ ] **Step 1: Create ProvidersSettingsView with sparkline layout**

```swift
struct ProvidersSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddProvider = false
    @State private var providerFilter = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Providers")
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)
            
            // Provider statistics chips
            providerStatsChips
            
            // Search and add
            searchAndAddSection
            
            // Providers list
            providersList
            
            // Add provider sheet
            AddProviderSheet(...)
        }
    }
    
    private var providerStatsChips: some View {
        HStack(spacing: 12) {
            ProviderCountChip(
                title: "Providers",
                count: appState.providerOptions.count,
                icon: "server.rack"
            )
            ProviderCountChip(
                title: "Models",
                count: appState.availableModels.count,
                icon: "cpu"
            )
            Spacer()
        }
    }
}
```

- [ ] **Step 2: Add ProviderCountChip view**

```swift
struct ProviderCountChip: View {
    let title: String
    let count: Int
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .interfaceFont(size: 10)
            Text(title)
                .interfaceFont(size: 10)
            Text("\(count)")
                .interfaceFont(size: 12, weight: .semibold)
                .foregroundColor(Color.mimo.brand)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.mimo.backgroundAlt)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
```

- [ ] **Step 3: Add search functionality**

```swift
private var filteredProviders: [ProviderOption] {
    if providerFilter.isEmpty {
        return appState.providerOptions
    }
    return appState.providerOptions.filter {
        $0.name.localizedCaseInsensitiveContains(providerFilter)
    }
}
```

---

### Task 3: Implement Spoiler Functionality for Model Parameters

**Files:**
- Modify: `Sources/Services/SpoilerExpandLogic.swift`
- Create: `Sources/Views/Components/ProviderParameterSpoiler.swift`

- [ ] **Step 1: Check SpoilerExpandLogic is complete**

The existing SpoilerExpandLogic handles height and opacity. Verify it works for parameters.

- [ ] **Step 2: Create ParameterSpoilerView**

```swift
struct ParameterSpoilerView: View {
    let provider: ProviderOption
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Summary row with chips
            parameterSummaryRow
            
            // Expandable content
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 12) {
                    ParameterField(
                        label: "Base URL",
                        value: provider.baseURL,
                        isEditable: false
                    )
                    
                    ParameterField(
                        label: "Models",
                        value: "\(provider.modelCount)",
                        isEditable: false
                    )
                    
                    if provider.isCustom {
                        ParameterField(
                            label: "API Key",
                            value: provider.hasAPIKey ? "••••••••" : "Not set",
                            isEditable: false
                        )
                    }
                }
                .frame(height: SpoilerExpandLogic.contentHeight(
                    isExpanded: isExpanded,
                    measuredHeight: geometry.size.height
                ))
                .opacity(SpoilerExpandLogic.contentOpacity(isExpanded: isExpanded))
            }
            .frame(minHeight: 80)
            .animation(SpoilerExpandLogic.animation, value: isExpanded)
        }
        .onTapGesture {
            withAnimation {
                isExpanded.toggle()
            }
        }
    }
    
    private var parameterSummaryRow: some View {
        HStack {
            Text("Parameters")
                .interfaceFont(size: 12, weight: .semibold)
                .foregroundColor(Color.mimo.textSecondary)
            Spacer()
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .interfaceFont(size: 10)
                .foregroundColor(Color.mimo.textMuted)
        }
    }
}
```

---

### Task 4: Add API Endpoint Configuration for Provider Types

**Files:**
- Modify: `Sources/Models/Settings.swift`
- Modify: `Sources/Views/Components/AddProviderSheet.swift` (or create new)

- [ ] **Step 1: Add type-specific API endpoint details**

Extend ProviderType with more configuration options:

```swift
enum ProviderType: String, Codable, CaseIterable, Identifiable {
    // ... existing cases
    
    var id: String { rawValue }
    
    var icon: String { /* existing */ }
    
    var defaultURL: String { /* existing */ }
    
    // NEW: Add endpoint patterns for different API types
    var endpointPattern: String {
        switch self {
        case .openRouter:
            return "/v1/chat/completions"  // OpenRouter uses OpenAI-compatible API
        case .omni:
            return "/v1/chat/completions"  // OmniRouter also OpenAI-compatible
        case .acp:
            return "/v1/task"              // ACP has different endpoints
        default:
            return "/v1/chat/completions"
        }
    }
    
    var needsAPIKey: Bool {
        switch self {
        case .ollama: return false
        case .openModel: return false  // May need API key for some models
        default: return true
        }
    }
}
```

- [ ] **Step 2: Update AddProviderSheet with type-specific UI**

Show different fields based on provider type:

```swift
struct AddProviderSheet: View {
    @Binding var isPresented: Bool
    @Binding var name: String
    @Binding var type: ProviderType
    @Binding var url: String
    @Binding var apiKey: String
    
    var body: some View {
        VStack {
            // Type picker
            Picker("Provider Type", selection: $type) {
                ForEach(ProviderType.allCases) { t in
                    HStack {
                        Image(systemName: t.icon)
                        Text(t.rawValue)
                    }
                    .tag(t)
                }
            }
            .pickerStyle(.menu)
            
            // Type-specific help text
            typeSpecificHelp
            
            // API endpoint field (type-aware)
            if type == .openModel {
                Text("OpenModel: API format may vary. Check model-specific requirements.")
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
            }
            
            if type == .omni || type == .openRouter {
                Text("Using OmniRouter/OpenRouter API endpoint structure")
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
            }
        }
    }
    
    private var typeSpecificHelp: some View {
        switch type {
        case .omni:
            return AnyView(Text("OmniRouter supports all model types. Models can be prefixed with 'agentrouter/' for specific variants.").foregroundColor(Color.mimo.textMuted))
        case .acp:
            return AnyView(Text("ACP (Agent Coder Protocol) enables autonomous coding tasks.").foregroundColor(Color.mimo.textMuted))
        default:
            return AnyView(Text(""))
        }
    }
}
```

---

### Task 5: Add Provider/Model Counts with Chips

**Files:**
- Modify: `Sources/Views/SettingsView.swift` (existing ModelSettingsView)

- [ ] **Step 1: Add count chips to ModelSettingsView**

```swift
// In ModelSettingsView struct
private var modelCountChips: some View {
    HStack(spacing: 16) {
        Label {
            HStack(spacing: 4) {
                Text("\(appState.providerOptions.count)")
                    .interfaceFont(size: 14, weight: .semibold)
                    .foregroundColor(Color.mimo.brand)
                Text("providers")
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textSecondary)
            }
        } label: {
            Image(systemName: "server.rack")
        }
        .frame(maxWidth: .infinity)
        
        Label {
            HStack(spacing: 4) {
                Text("\(appState.availableModels.count)")
                    .interfaceFont(size: 14, weight: .semibold)
                    .foregroundColor(Color.mimo.brand)
                Text("models")
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textSecondary)
            }
        } label: {
            Image(systemName: "cpu")
        }
        .frame(maxWidth: .infinity)
    }
    .padding(.bottom, 8)
}
```

---

### Task 6: Write Tests for New Functionality

**Files:**
- Create: `Tests/ProvidersSettingsTests.swift`
- Modify: `Tests/AppLocalizationTests.swift` (if new keys added)

- [ ] **Step 1: Test SettingsTab.providers**

```swift
@Test("SettingsTab has providers case")
func testProvidersTabExists() {
    #expect(SettingsTab.allCases.contains(.providers))
}

@Test("SettingsTab.providers has correct icon")
func testProvidersTabIcon() {
    #expect(SettingsTab.providers.icon == "server.rack")
}
```

- [ ] **Step 2: Test provider count chips**

```swift
@Test("AppState provider counts are accurate")
func testProviderCounts() {
    let state = AppState()
    state.customProviders = [
        CustomProvider(id: "p1", name: "P1", type: .openAI, baseURL: "https://a.com", isEnabled: true, models: ["m1", "m2"]),
        CustomProvider(id: "p2", name: "P2", type: .openAI, baseURL: "https://b.com", isEnabled: false, models: ["m3"])
    ]
    state.serverProviders = [
        MimoProviderResponse(id: "srv", name: "Server", models: ["m4": MimoProviderModel(id: "m4")])
    ]
    
    #expect(state.providerOptions.count == 2)  // p1 and srv
    #expect(state.availableModels.count == 3)  // m1, m2, m4
}
```

- [ ] **Step 3: Test ProviderType enhancements**

```swift
@Test("ProviderType has endpoint patterns")
func testEndpointPatterns() {
    for type in ProviderType.allCases {
        #expect(!type.endpointPattern.isEmpty)
    }
}

@Test("ProviderType needsAPIKey returns correct values")
func testNeedsAPIKey() {
    #expect(ProviderType.ollama.needsAPIKey == false)
    #expect(ProviderType.openAI.needsAPIKey == true)
    #expect(ProviderType.openModel.needsAPIKey == false)
}
```

---

### Task 7: Commit and Push Changes

- [ ] **Step 1: Run all tests**

```bash
cd /Users/apple/projects/mimo-macos
./miMoMacOS.xcodeproj  # or use xcodebuild/test
```

- [ ] **Step 2: Stage changes**

```bash
git add -A
```

- [ ] **Step 3: Commit with descriptive message**

```bash
git commit -m "feat: Add dedicated Providers tab to Settings

- Add Providers tab alongside Model Settings for dedicated management
- Implement spoiler-expandable parameter sections for providers
- Add provider/model count chips with visual indicators
- Add API endpoint configuration support for provider types
- Include localization for Russian and English
- Add comprehensive test coverage

Fixes provider management UX issues and adds missing functionality."
```

- [ ] **Step 4: Push to remote**

```bash
git push origin main
```

---

## Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `Sources/Models/SettingsTab.swift` | Modify | Add providers case |
| `Sources/Services/AppLocalization.swift` | Modify | Add localization keys |
| `Sources/Views/SettingsView.swift` | Modify | Add providers tab view |
| `Sources/Views/SettingsViews/ProvidersSettingsView.swift` | Create | Dedicated providers UI |
| `Sources/Views/Components/ProviderCountChip.swift` | Create | Count chip component |
| `Sources/Views/Components/ParameterSpoilerView.swift` | Create | Expandable parameters |
| `Sources/Models/Settings.swift` | Modify | Add endpointPattern to ProviderType |
| `Tests/ProvidersSettingsTests.swift` | Create | Test coverage |

---

## Backward Compatibility

All changes are UI additions - no breaking changes to existing functionality:
- Existing ModelSettings still works in parallel
- Provider selection logic unchanged
- No database schema changes required
- No API changes to MimoServeClient

## Success Criteria

- [ ] Settings shows new Providers tab
- [ ] Provider counts display correctly as chips
- [ ] Parameter sections are expandable with spoiler animation
- [ ] Provider types show appropriate endpoint help
- [ ] All tests pass
- [ ] Code follows existing patterns and style