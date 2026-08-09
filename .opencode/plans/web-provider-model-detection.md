# Web Provider Model Detection & Session Management — Complete Plan

> Status: IN PROBLEM
> Goal: Auto-detect models, handle sessions, switch models/chat/effort for ALL web providers

## Current State

**Working:**
- ✅ Kimi: detects 3 models (Быстрый, K3, K3 Swarm) via `div.current-model` → `div.model-item`
- ✅ Element picker JS rewritten with named functions
- ✅ `:has-text()` support added to `exists()` and `click()`
- ✅ Logo restored to original 197x197

**Broken:**
- ❌ Build fails: `waitForSelector` and `readModelItems` not in `BrowserAutomationBridge` protocol
  - They exist in `WKWebViewBrowserBridge` but not declared in the protocol
- ❌ Other providers not tested (Qwen, ChatGPT, etc.)
- ❌ No study of what each model sends / how to extract chat URL per model
- ❌ No effort level switching implemented

---

## Phase 1: Fix Build (P0)

### 1.1 Add missing protocol methods
**File:** `BrowserAutomationBridge.swift`
```swift
protocol BrowserAutomationBridge {
    // ... existing methods ...
    func waitForSelector(selector: String, timeout: Int) async throws
    func readModelItems() async throws -> [String]
}
```

### 1.2 Add default implementations (extension)
```swift
extension BrowserAutomationBridge {
    func waitForSelector(selector: String, timeout: Int = 5000) async throws {
        let deadline = Date().addingTimeInterval(Double(timeout) / 1000.0)
        while Date() < deadline {
            if try await exists(selector: selector) { return }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
    }

    func readModelItems() async throws -> [String] { return [] }
}
```

---

## Phase 2: Test ALL Web Providers via Playwright (P0)

### 2.1 Test Matrix
For EACH provider (kimi, qwen, chatgpt):
1. Navigate to chat URL
2. Find "New Chat" button (localized text)
3. Click to enter chat
4. Find model selector (try catalog selector first)
5. Click to open dropdown
6. Read all model names
7. Document: selector that works, model list, effort selector

### 2.2 Playwright Test Script
```javascript
// For each provider:
await page.goto(url, { waitUntil: 'domcontentloaded' });
await page.waitForTimeout(5000);

// Click "New Chat" (try multiple text variants)
const newChatVariants = ['New Chat', '新对话', 'Новый чат', 'Start Chat', 'Начать'];
// ... click first visible

// Wait for model button
await page.waitForSelector(modelSelector, { timeout: 10000 });
await page.locator(modelSelector).first().click();
await page.waitForTimeout(3000);

// Read models
const models = await page.evaluate(() => {
  // Try multiple selectors for dropdown items
  const selectors = [
    'div.model-item span.name',
    '[role="option"]',
    '[class*="option"]',
    'li',
  ];
  // ... extract text
});
```

### 2.3 Expected Output
```
Provider: kimi
  Model button: div.current-model
  Dropdown items: div.model-item
  Models: Быстрый, K3, K3 Swarm
  Effort: div.effort-item (Высокий/Низкий)
  Chat URL after model select: /chat/{chat_id}

Provider: qwen
  Model button: ???
  Dropdown items: ???
  Models: ???
  Effort: ???

Provider: chatgpt
  Model button: ???
  Dropdown items: ???
  Models: ???
  Effort: ???
```

---

## Phase 3: Study Model-Specific Behavior (P1)

### 3.1 What to capture per model
For each provider+model combination:
- **Request payload**: What JSON is sent to the API? (model id, effort, etc.)
- **Endpoint**: Which URL receives the chat message?
- **Chat URL**: After selecting model, what's the chat URL pattern?
- **Effort**: How is effort/thinking level encoded in requests?

### 3.2 Capture via Playwright
```javascript
// Intercept network requests
page.on('request', req => {
  if (req.url().includes('/api/') || req.url().includes('/chat/')) {
    console.log('REQUEST:', req.url(), req.postData());
  }
});

// Select model, send message, capture request
await page.locator('div.model-item').first().click();
await page.locator('textarea').fill('test');
await page.locator('button[type="submit"]').click();
await page.waitForTimeout(2000);
```

### 3.3 Document findings
Create `docs/qa/web-providers-api.md`:
```markdown
## Kimi
- Endpoint: POST https://kimi.moonshot.cn/api/chat/{chat_id}/completion/stream
- Model field: `model` = "k2" | "k2-thinking" | "k1.5"
- Effort field: `thinking` = "high" | "low"
- Chat URL: https://kimi.moonshot.cn/chat/{uuid}

## Qwen
- Endpoint: ???
- Model field: ???
- Effort field: ???

## ChatGPT
- Endpoint: ???
- Model field: ???
- Effort field: ???
```

---

## Phase 4: Implement Model/Session/Effort Switching (P1)

### 4.1 Model Selection
**File:** `WebChatDriver.swift`
```swift
func selectModel(_ modelName: String, bridge: BrowserAutomationBridge) async throws {
    // 1. Click model button (from catalog selector)
    // 2. Wait for dropdown
    // 3. Find item matching modelName
    // 4. Click it
    // 5. Verify selection changed
}
```

### 4.2 Session Management
**File:** `WebChatDriver.swift`
```swift
func startNewSession(bridge: BrowserAutomationBridge) async throws -> String {
    // 1. Click "New Chat"
    // 2. Wait for navigation
    // 3. Extract chat ID from URL
    // 4. Return chat URL/ID
}

func getCurrentChatID(bridge: BrowserAutomationBridge) async -> String? {
    // Extract from current URL
}
```

### 4.3 Effort Selection
**File:** `WebChatDriver.swift`
```swift
func selectEffort(_ effort: WebEffort, bridge: BrowserAutomationBridge) async throws {
    // 1. Click effort button
    // 2. Wait for dropdown
    // 3. Select matching level
}
```

---

## Phase 5: Update Catalog (P2)

### 5.1 Per-vendor selectors
Update `web_providers_catalog.json` with REAL selectors from Playwright tests:
```json
{
  "kimi": {
    "modelButton": "div.current-model",
    "modelItems": "div.model-item",
    "modelName": "span.name",
    "effortButton": "div.effort-item",
    "newChatTexts": ["Новый чат", "New Chat"]
  },
  "qwen": { ... },
  "chatgpt": { ... }
}
```

---

## Phase 6: TDD Tests (P2)

### 6.1 Unit tests
- `WebModelListParserTests`: parse known dropdown texts
- `WebModelDiscoveryTests`: mock bridge, verify fallback logic

### 6.2 Integration tests
- `WebChatDriverTests`: full flow (new chat → select model → send → verify)

---

## Execution Order

1. Fix build (Phase 1) — 5 min
2. Test all providers (Phase 2) — 30 min
3. Study API behavior (Phase 3) — 30 min
4. Implement switching (Phase 4) — 45 min
5. Update catalog (Phase 5) — 10 min
6. Write tests (Phase 6) — 30 min

**Total: ~2.5 hours**
