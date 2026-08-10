# Web Provider UI — Localization, Model Management & Effort Detection

> Status: IN PROBLEM
> Goal: Fix broken translations, improve model management, add effort detection feedback

## Issues Identified

### Issue 1: Broken Translations (HIGH)
**Symptom:** "Tool-call delay", "Keep-alive", and other strings show localization keys instead of translated text.

**Root cause:** Enum cases exist in `AppLocalizationKey` but dictionary values are missing:
- `locToolCallDelay` — MISSING
- `locKeepalive` — MISSING

**Files:** `AppLocalization.swift`

### Issue 2: "Add Model" Mixes Auto + Manual (HIGH)
**Symptom:** Auto-detected models and manually added models are stored in the same `discoveredModels` array. Running auto-detection again overwrites manual additions.

**Root cause:** Single `discoveredModels: [String]` field used for both auto-detected and manual models.

**Files:** `WebProviderConfig.swift`, `WebProvidersSection.swift`

### Issue 3: No Effort Detection Feedback (MEDIUM)
**Symptom:** User cannot tell if effort/thinking levels were successfully detected for a provider.

**Root cause:** No UI state tracks whether effort detection was attempted/succeeded.

**Files:** `WebProviderLoginView`, `WebProvidersSection.swift`

### Issue 4: Model Switching Not Implemented (MEDIUM)
**Symptom:** No way to switch between detected models in the chat input.

**Root cause:** Models are detected but the chat driver doesn't apply selection before sending.

**Files:** `WebChatDriver.swift`

---

## Fix Plan

### Step 1: Fix Missing Translations
**File:** `AppLocalization.swift`

Add missing dictionary entries after existing `locWeb*` entries:

```swift
"locToolCallDelay": ["en": "Tool-call delay", "ru": "Задержка вызова инструментов", ...],
"locKeepalive": ["en": "Keep-alive", "ru": "Поддержание соединения", ...],
```

Also add any other keys that might be missing (verify all 366 enum cases have values).

**Verification:**
```bash
for key in $(grep "case loc" AppLocalization.swift | sed 's/.*case //' | sed 's/ //g'); do
  if ! grep -q "\"$key\":" AppLocalization.swift; then echo "MISSING: $key"; fi;
done
```

### Step 2: Separate Auto-Detected vs Manual Models
**File:** `WebProviderConfig.swift`

Add new field:
```swift
struct WebProviderConfig: ... {
    var discoveredModels: [String]        // Auto-detected
    var manuallyAddedModels: [String]     // NEW: manually added
    var discoveredEffortLevels: [WebEffort]
    var customModelSelector: String?
}
```

Add computed property:
```swift
var allModels: [String] {
    Array(Set(discoveredModels + manuallyAddedModels)).sorted()
}
```

**File:** `WebProvidersSection.swift`

Update `CustomModelEditor`:
```swift
// Show auto-detected section with count
if !config.discoveredModels.isEmpty {
    Text("Auto-detected: \(config.discoveredModels.count)")
    ForEach(config.discoveredModels, id: \.self) { model in
        // Show with "auto" badge, no remove button
    }
}

// Show manual section
Text("Custom models")
ForEach(config.manuallyAddedModels, id: \.self) { model in
    // Show with remove button
}

// Add model input
TextField("Model ID", text: $newModelName)
Button("Add") {
    config.manuallyAddedModels.append(newModelName)
    onSave()
}
```

### Step 3: Add Effort Detection Feedback
**File:** `WebProviderLoginView`

Add state:
```swift
@State private var effortDetectResult: EffortDetectResult?

enum EffortDetectResult {
    case detecting
    case found([WebEffort])
    case failed(String)
}
```

Add UI in header:
```swift
if let result = effortDetectResult {
    switch result {
    case .detecting:
        Label("Detecting effort...", systemImage: "arrow.triangle.2.circlepath")
    case .found(let efforts):
        Label("\(efforts.count) effort levels", systemImage: "checkmark.circle.fill")
            .foregroundColor(.green)
    case .failed(let err):
        Label("Effort: \(err)", systemImage: "exclamationmark.triangle")
            .foregroundColor(.orange)
    }
}
```

### Step 4: Fix Auto-Detection to Not Overwrite Manual
**File:** `WebProvidersSection.swift`

Update `detectModelsFromPage()`:
```swift
// Only update discoveredModels, preserve manuallyAddedModels
var updated = config
updated.discoveredModels = models  // Replace auto-detected
// manuallyAddedModels stays unchanged
config = updated
```

### Step 5: Model Switching in Chat
**File:** `WebChatDriver.swift`

Update `injectModelAndEffort()`:
```swift
// Use allModels (auto + manual) for selection
// Apply model before sending message
```

### Step 6: Update Catalog with New Fields
**File:** `web_providers_catalog.json`

Add effort selector for each vendor:
```json
{
  "kimi": {
    "effortButton": "div.effort-item",
    "effortItem": "div.effort-option"
  }
}
```

---

## Execution Order

| Step | Task | Time | Priority |
|------|------|------|----------|
| 1 | Fix missing translations | 5 min | P0 |
| 2 | Separate auto/manual models | 15 min | P0 |
| 3 | Add effort detection feedback | 10 min | P1 |
| 4 | Fix auto-detection overwrite | 5 min | P0 |
| 5 | Model switching in chat | 15 min | P1 |
| 6 | Update catalog | 5 min | P1 |
| 7 | Tests | 15 min | P2 |
| 8 | Build + commit | 5 min | — |

**Total: ~75 minutes**

---

## Verification Checklist

- [ ] `locToolCallDelay` shows "Tool-call delay" (en) / "Задержка вызова инструментов" (ru)
- [ ] `locKeepalive` shows "Keep-alive" (en) / "Поддержание соединения" (ru)
- [ ] Auto-detected models shown separately from manual
- [ ] Adding manual model doesn't get overwritten by auto-detect
- [ ] Effort detection shows success/failure state in UI
- [ ] Can switch models in chat input
- [ ] All 366 localization keys have dictionary values
- [ ] Tests pass
