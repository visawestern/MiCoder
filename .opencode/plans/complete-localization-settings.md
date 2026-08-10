# Web & Model Settings — Complete Localization Plan

> Status: IN PROBLEM
> Goal: Translate ALL hardcoded strings in model/provider settings to support 10 languages

## Missing Dictionary Values (AppLocalization.swift)

Only 2 keys have NO value at all:
- `locToolCallDelay`
- `locKeepalive`

## Hardcoded Strings That Need Localization

### 1. WebProvidersSection.swift (Web Provider Login)

| Line | Current | Action |
|------|---------|--------|
| 797 | `"Picked Element"` | Add `locPickerTitle` |
| 799 | `"Selector:"` | Add `locPickerSelector` |
| 800 | `"Tag:"` | Add `locPickerTag` |
| 802 | `"Class:"` | Add `locPickerClass` |
| 804 | `"Text:"` | Add `locPickerText` |

### 2. ModelSettingsView.swift

| Line | Current | Action |
|------|---------|--------|
| 481 | `"· \(count)"` | Keep (dynamic) or add `locModelCount` |
| 527 | `"R"` | Keep (icon) |
| 536 | `"T"` | Keep (icon) |
| 545 | `"\(context / 1000)k"` | Keep (dynamic format) |
| 552 | `"$"` | Keep (symbol) |
| 725 | `"\(provider.models.count) available"` | Add `locModelsAvailable` |

### 3. ProvidersSettingsView.swift

| Line | Current | Action |
|------|---------|--------|
| 224 | `"\(config.serveBaseURL) · \(config.models.count) models"` | Add `locProviderStats` with format |
| 427 | `"\(custom.models.count) models"` | Add `locModelsCount` |

### 4. StorageSettingsView.swift

| Line | Current | Action |
|------|---------|--------|
| 72 | `"\(item.active) active"` | Add `locActiveCount` |
| 75 | `"\(item.archived) archived"` | Add `locArchivedCount` |

### 5. UsageSettingsView.swift

| Line | Current | Action |
|------|---------|--------|
| 77 | `"\(agg.messageCount) msg"` | Add `locMessageCount` |

---

## New Localization Keys Needed

```
locToolCallDelay     → "Tool-call delay" / "Задержка вызова инструментов"
locKeepalive         → "Keep-alive" / "Поддержание соединения"
locPickerTitle       → "Picked Element" / "Выбранный элемент"
locPickerSelector    → "Selector:" / "Селектор:"
locPickerTag         → "Tag:" / "Тег:"
locPickerClass       → "Class:" / "Класс:"
locPickerText        → "Text:" / "Текст:"
locModelsAvailable   → "%d models available" / "%d моделей доступно"
locProviderStats     → "%@ · %d models" / "%@ · %d моделей"
locModelsCount       → "%d models" / "%d моделей"
locActiveCount       → "%d active" / "%d активных"
locArchivedCount     → "%d archived" / "%d в архиве"
locMessageCount      → "%d msg" / "%d сообщ."
```

---

## Execution Plan

### Step 1: Add Missing Dictionary Values
**File:** `AppLocalization.swift`

Add after existing entries:
```swift
"locToolCallDelay": ["en": "Tool-call delay", "ru": "Задержка вызова инструментов", ...],
"locKeepalive": ["en": "Keep-alive", "ru": "Поддержание соединения", ...],
"locPickerTitle": ["en": "Picked Element", "ru": "Выбранный элемент", ...],
"locPickerSelector": ["en": "Selector:", "ru": "Селектор:", ...],
"locPickerTag": ["en": "Tag:", "ru": "Тег:", ...],
"locPickerClass": ["en": "Class:", "ru": "Класс:", ...],
"locPickerText": ["en": "Text:", "ru": "Текст:", ...],
"locModelsAvailable": ["en": "%d models available", "ru": "%d моделей доступно", ...],
"locProviderStats": ["en": "%@ · %d models", "ru": "%@ · %d моделей", ...],
"locModelsCount": ["en": "%d models", "ru": "%d моделей", ...],
"locActiveCount": ["en": "%d active", "ru": "%d активных", ...],
"locArchivedCount": ["en": "%d archived", "ru": "%d в архиве", ...],
"locMessageCount": ["en": "%d msg", "ru": "%d сообщ.", ...],
```

**Also add enum cases** (after existing `case` declarations):
```swift
case locToolCallDelay
case locKeepalive
case locPickerTitle
case locPickerSelector
case locPickerTag
case locPickerClass
case locPickerText
case locModelsAvailable
case locProviderStats
case locModelsCount
case locActiveCount
case locArchivedCount
case locMessageCount
```

### Step 2: Replace Hardcoded Strings in Views

**WebProvidersSection.swift:**
```swift
// Line 797
Text(L.t(AppLocalizationKey.locPickerTitle))

// Line 799
HStack { Text(L.t(AppLocalizationKey.locPickerSelector)).bold(); ... }
HStack { Text(L.t(AppLocalizationKey.locPickerTag)).bold(); ... }
HStack { Text(L.t(AppLocalizationKey.locPickerClass)).bold(); ... }
HStack { Text(L.t(AppLocalizationKey.locPickerText)).bold(); ... }
```

**ModelSettingsView.swift:**
```swift
// Line 725
Text(String(format: L.t(AppLocalizationKey.locModelsAvailable), provider.models.count))
```

**ProvidersSettingsView.swift:**
```swift
// Line 224
Text(String(format: L.t(AppLocalizationKey.locProviderStats), config.serveBaseURL, config.models.count))

// Line 427
Text(String(format: L.t(AppLocalizationKey.locModelsCount), custom.models.count))
```

**StorageSettingsView.swift:**
```swift
// Line 72
Text(String(format: L.t(AppLocalizationKey.locActiveCount), item.active))

// Line 75
Text(String(format: L.t(AppLocalizationKey.locArchivedCount), item.archived))
```

**UsageSettingsView.swift:**
```swift
// Line 77
Text(String(format: L.t(AppLocalizationKey.locMessageCount), agg.messageCount))
```

### Step 3: Verify All Keys

Run verification:
```bash
for key in $(grep "case loc" AppLocalization.swift | sed 's/.*case //' | sed 's/ //g'); do
  if ! grep -q "\"$key\":" AppLocalization.swift; then echo "MISSING: $key"; fi;
done
```

Expected output: (empty — no missing keys)

### Step 4: Build & Test

```bash
swift build  # 0 errors
swift test   # all tests pass
./build-app.sh --skip-tests
```

---

## Summary

| Category | Count |
|----------|-------|
| Missing dictionary values | 2 |
| New keys to add | 11 |
| Hardcoded strings to replace | 11 |
| Files modified | 6 |

**Execution time:** ~30 minutes
