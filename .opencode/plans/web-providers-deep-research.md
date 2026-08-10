# Web Providers — Deep Research & Complete Feature Plan

> Status: IN PROBLEM
> Goal: Document ALL models, modes, switches, effort levels for Kimi + Qwen and implement proper detection

## Current Issues

1. **Qwen**: Only finds 1-3 models, misses "Expand more models" and additional models
2. **Kimi**: Likely misses "Deep thinking" mode, image generation mode, and per-model switches
3. **Both**: Mode switches (auto/think/fast) not detected - each model has different available modes
4. **Localization**: 11+ hardcoded strings need translation

---

## Phase 1: Deep Playwright Research

### 1.1 Kimi Research Script

```javascript
// Tests/Playwright/kimi-deep-research.mjs
import { chromium } from 'playwright';

async function researchKimi() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.goto('https://kimi.moonshot.cn', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(6000);

  // Enter chat
  await page.locator('button, a, div').filter({ hasText: /Новый чат|New Chat/ }).first().click();
  await page.waitForTimeout(5000);

  // DOCUMENT 1: Model button and all models
  console.log('=== MODELS ===');
  await page.locator('div.current-model').first().click();
  await page.waitForTimeout(3000);

  const models = await page.evaluate(() => {
    const items = document.querySelectorAll('div.model-item');
    return Array.from(items).map(el => ({
      name: el.querySelector('span.name')?.textContent?.trim(),
      description: el.querySelector('div.desc')?.textContent?.trim(),
    }));
  });
  console.log(`Found ${models.length} models:`, models);

  // Look for "Expand more models" / "Показать ещё модели"
  const expandBtn = await page.locator('*').filter({ hasText: /Expand|Показать ещё|更多/ }).first();
  if (await expandBtn.count() > 0) {
    console.log('Found expand button, clicking...');
    await expandBtn.click();
    await page.waitForTimeout(2000);
    // Re-read models
  }

  // DOCUMENT 2: Mode switches (auto/think/fast)
  console.log('\n=== MODE SWITCHES ===');
  const switches = await page.evaluate(() => {
    const switches = [];
    // Look for toggle buttons, pills, or segments
    const switchElements = document.querySelectorAll(
      '[class*="switch"], [class*="toggle"], [class*="pill"], [class*="segment"], [role="tab"], [role="radio"]'
    );
    for (const el of switchElements) {
      const text = el.textContent?.trim();
      if (text && text.length < 30) switches.push(text);
    }
    return [...new Set(switches)];
  });
  console.log('Mode switches found:', switches);

  // DOCUMENT 3: Special modes (deep thinking, image generation)
  console.log('\n=== SPECIAL MODES ===');
  const specialModes = await page.evaluate(() => {
    const modes = [];
    const elements = document.querySelectorAll('*');
    for (const el of elements) {
      const text = el.textContent?.trim();
      if (text && (text.includes('Deep') || text.includes('Image') || text.includes('Think') || text.includes('深度') || text.includes('图片')) && text.length < 50) {
        modes.push(text);
      }
    }
    return [...new Set(modes)].slice(0, 20);
  });
  console.log('Special modes found:', specialModes);

  // DOCUMENT 4: Effort levels per model
  console.log('\n=== EFFORT LEVELS ===');
  // Click each model and check effort options
  const effortLevels = await page.evaluate(() => {
    const efforts = document.querySelectorAll('[class*="effort"]');
    return Array.from(efforts).map(el => el.textContent?.trim());
  });
  console.log('Effort elements:', effortLevels);

  // DOCUMENT 5: Per-model mode availability
  console.log('\n=== PER-MODEL MODES ===');
  // For each model, click it and document available modes
  const modelModes = {};
  const modelItems = await page.locator('div.model-item').all();
  for (let i = 0; i < modelItems.length; i++) {
    await modelItems[i].click();
    await page.waitForTimeout(2000);
    const modelName = await modelItems[i].querySelector('span.name')?.textContent?.trim();

    // Check which switches are available
    const availableSwitches = await page.evaluate(() => {
      const switches = document.querySelectorAll('[class*="switch"], [class*="toggle"], [role="tab"]');
      return Array.from(switches).filter(el => el.isVisible()).map(el => el.textContent?.trim());
    });

    modelModes[modelName] = availableSwitches;
    console.log(`Model "${modelName}":`, availableSwitches);
  }

  await page.screenshot({ path: '/tmp/kimi-deep.png', fullPage: false });
  await browser.close();
}

researchKimi().catch(console.error);
```

### 1.2 Qwen Research Script

```javascript
// Tests/Playwright/qwen-deep-research.mjs
import { chromium } from 'playwright';

async function researchQwen() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.goto('https://chat.qwen.ai/', { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(6000);

  // Enter chat
  await page.locator('button').filter({ hasText: 'Начать' }).first().click();
  await page.waitForTimeout(5000);

  // DOCUMENT 1: Model selector and all models
  console.log('=== MODELS ===');
  await page.locator('[class*="model-selector-text"]').first().click();
  await page.waitForTimeout(3000);

  // First pass: visible models
  let models = await page.evaluate(() => {
    const items = document.querySelectorAll('[class*="model-item-name"]');
    return Array.from(items).map(el => ({
      name: el.textContent?.trim(),
      description: el.closest('[class*="model-item"]')?.querySelector('[class*="desc"]')?.textContent?.trim()
    }));
  });
  console.log(`Visible models: ${models.length}`, models);

  // DOCUMENT 2: "Expand more models" button
  console.log('\n=== EXPAND MORE MODELS ===');
  const expandTexts = ['Expand more', 'Show more', '更多', 'Показать ещё'];
  for (const text of expandTexts) {
    const btn = page.locator('*').filter({ hasText: text }).first();
    if (await btn.count() > 0 && await btn.isVisible()) {
      console.log(`Found expand button: "${text}"`);
      await btn.click();
      await page.waitForTimeout(2000);
      // Re-read models
      models = await page.evaluate(() => {
        const items = document.querySelectorAll('[class*="model-item-name"]');
        return Array.from(items).map(el => ({
          name: el.textContent?.trim(),
          description: el.closest('[class*="model-item"]')?.querySelector('[class*="desc"]')?.textContent?.trim()
        }));
      });
      console.log(`After expand: ${models.length} models`);
      break;
    }
  }

  // DOCUMENT 3: Mode switches (auto/think/fast)
  console.log('\n=== MODE SWITCHES ===');
  const switches = await page.evaluate(() => {
    const switches = [];
    const elements = document.querySelectorAll('[class*="switch"], [class*="toggle"], [class*="mode"], [role="tab"], [role="radio"]');
    for (const el of elements) {
      if (el.isVisible()) {
        const text = el.textContent?.trim();
        if (text && text.length < 30) switches.push(text);
      }
    }
    return [...new Set(switches)];
  });
  console.log('Mode switches:', switches);

  // DOCUMENT 4: Special modes (image generation, deep thinking)
  console.log('\n=== SPECIAL MODES ===');
  const specialModes = await page.evaluate(() => {
    const modes = [];
    const all = document.querySelectorAll('*');
    for (const el of all) {
      if (!el.isVisible()) continue;
      const text = el.textContent?.trim();
      if (text && (text.includes('Image') || text.includes('Think') || text.includes('Deep') || text.includes('图片') || text.includes('深度')) && text.length < 40) {
        modes.push(text);
      }
    }
    return [...new Set(modes)].slice(0, 20);
  });
  console.log('Special modes:', specialModes);

  // DOCUMENT 5: Per-model modes
  console.log('\n=== PER-MODEL MODES ===');
  const modelItems = await page.locator('[class*="model-item"]').all();
  const modelModes = {};
  for (let i = 0; i < modelItems.length; i++) {
    await modelItems[i].click();
    await page.waitForTimeout(2000);
    const modelName = await modelItems[i].querySelector('[class*="model-item-name"]')?.textContent?.trim();

    const available = await page.evaluate(() => {
      const els = document.querySelectorAll('[class*="switch"], [class*="toggle"], [role="tab"]');
      return Array.from(els).filter(el => el.isVisible()).map(el => el.textContent?.trim());
    });

    modelModes[modelName] = available;
    console.log(`Model "${modelName}":`, available);
  }

  await page.screenshot({ path: '/tmp/qwen-deep.png', fullPage: false });
  await browser.close();
}

researchQwen().catch(console.error);
```

### 1.3 Expected Research Output

```
=== KIMI ===
Models (5+):
  1. Быстрый — Fast chat
  2. K3 — Universal flagship
  3. K3 Swarm — Scale search
  4. [+] Deep thinking mode (toggle)
  5. [+] Image generation mode (toggle)

Mode switches:
  - Auto / Think / Fast (per-model availability varies)

Effort levels:
  - Высокий / Низкий (High / Low)

=== QWEN ===
Models (8+ with expand):
  1. Qwen3.8-Max
  2. Qwen3.7-Plus
  3. Qwen3.7-Max
  4. [+] More after expand...

Mode switches:
  - Auto / Think / Fast / Image

Special modes:
  - Image generation (Qwen-Image 2.0)
  - Deep thinking
```

---

## Phase 2: Implementation Plan

### 2.1 Enhanced Model Detection

**New data structures:**
```swift
struct WebProviderModel: Codable, Equatable {
    let name: String
    let description: String?
    let availableModes: [String]      // ["auto", "think", "fast"]
    let supportsImageGeneration: Bool
    let supportsDeepThinking: Bool
}

struct WebProviderConfig: Codable {
    var discoveredModels: [WebProviderModel]  // Enhanced from [String]
    var manuallyAddedModels: [String]
    var discoveredEffortLevels: [WebEffort]
    var customModelSelector: String?
}
```

### 2.2 Expand More Models Detection

**File:** `WebModelDiscovery.swift`

```swift
static func discover(using bridge: ..., vendor: ...) async -> [WebProviderModel]? {
    // 1. Click model button
    // 2. Wait for dropdown
    // 3. Read visible models
    // 4. Look for "Expand more" button
    // 5. If found, click and re-read
    // 6. Return complete list
}

private static func findExpandButton(bridge: ...) async -> String? {
    let expandTexts = ["Expand more", "Show more", "更多", "Показать ещё", "展开更多"]
    for text in expandTexts {
        if let btn = try? await bridge.clickByText(selector: "*", text: text), btn {
            return text
        }
    }
    return nil
}
```

### 2.3 Mode Switch Detection

```swift
static func discoverModes(using bridge: ..., for model: String) async -> [String] {
    // 1. Click the model
    // 2. Wait for UI to update
    // 3. Read all visible toggle/switch elements
    // 4. Return mode names
}
```

### 2.4 Per-Model Mode UI

**File:** `WebProvidersSection.swift`

```swift
ForEach(config.discoveredModels, id: \.name) { model in
    VStack(alignment: .leading) {
        Text(model.name)
        if !model.availableModes.isEmpty {
            HStack {
                ForEach(model.availableModes, id: \.self) { mode in
                    ModeToggle(mode: mode)
                }
            }
        }
    }
}
```

### 2.5 Effort Detection Feedback

```swift
@State private var effortDetectResult: EffortDetectResult?

enum EffortDetectResult {
    case notChecked
    case checking
    case found([WebEffort])
    case failed(String)
}

// UI:
switch effortDetectResult {
case .notChecked:
    Button("Detect effort") { detectEffort() }
case .checking:
    ProgressView("Detecting effort...")
case .found(let levels):
    Label("\(levels.count) effort levels found", systemImage: "checkmark.circle")
case .failed(let error):
    Label(error, systemImage: "exclamationmark.triangle")
}
```

---

## Phase 3: Localization (11 New Keys)

### New Keys
```swift
locPickerTitle       → "Picked Element"
locPickerSelector    → "Selector:"
locPickerTag         → "Tag:"
locPickerClass       → "Class:"
locPickerText        → "Text:"
locModelsAvailable   → "%d models available"
locProviderStats     → "%@ · %d models"
locModelsCount       → "%d models"
locActiveCount       → "%d active"
locArchivedCount     → "%d archived"
locMessageCount      → "%d msg"
```

### Files to Update
1. `AppLocalization.swift` — add enum cases + dictionary values
2. `WebProvidersSection.swift` — replace 5 hardcoded strings
3. `ModelSettingsView.swift` — replace 1 string
4. `ProvidersSettingsView.swift` — replace 2 strings
5. `StorageSettingsView.swift` — replace 2 strings
6. `UsageSettingsView.swift` — replace 1 string

---

## Phase 4: Execution Order

| Step | Task | Time | Priority |
|------|------|------|----------|
| 1 | Run Kimi deep research (Playwright) | 10 min | P0 |
| 2 | Run Qwen deep research (Playwright) | 10 min | P0 |
| 3 | Document findings | 5 min | P0 |
| 4 | Implement enhanced model detection | 20 min | P0 |
| 5 | Implement "Expand more" logic | 10 min | P0 |
| 6 | Implement mode switch detection | 15 min | P1 |
| 7 | Implement per-model mode UI | 15 min | P1 |
| 8 | Add effort detection feedback | 10 min | P1 |
| 9 | Add 11 localization keys | 10 min | P1 |
| 10 | Replace hardcoded strings | 10 min | P1 |
| 11 | TDD tests | 20 min | P2 |
| 12 | Build + commit | 5 min | — |

**Total: ~2.5 hours**

---

## Research Questions to Answer

1. How many models does Kimi REALLY have (including after expand)?
2. How many models does Qwen REALLY have (including after expand)?
3. What mode switches exist for each model?
4. How to detect "Deep thinking" / "Image generation" toggles?
5. What effort levels are available per model?
6. How to switch modes programmatically?

---

## Success Criteria

- [ ] Kimi: detect ALL models (including expanded)
- [ ] Qwen: detect ALL models (including expanded)
- [ ] Detect mode switches per model
- [ ] Detect effort levels per model
- [ ] UI shows mode/effort detection status
- [ ] All hardcoded strings localized
- [ ] Tests pass
