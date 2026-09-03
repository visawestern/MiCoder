# Smart Fallback Architecture — Documentation

## Progress (Updated: 2026-08-17)

| # | Task | Status |
|---|------|--------|
| 1 | SmartElementFinder — classify UI elements | ✅ Done |
| 2 | NetworkInterceptor — capture XHR/fetch | ✅ Done |
| 3 | DirectWebAPIClient — direct API calls | ✅ Done |
| 4 | FallbackRouter — route between methods | ✅ Done |
| 5 | SmartSend — integrate all components | ✅ Done |
| 6 | TDD Tests — 204 tests, all passing | ✅ Done |
| 7 | Documentation — full param specs | ✅ Done |
| 8 | Integration — ChatPanelView.trySmartSendFallback | ✅ Done |
| 9 | Persistence — circuit breaker in UserDefaults | ✅ Done |
| 10 | Logging — SmartSendLogger (#if DEBUG) | ✅ Done |
| 11 | Pre-existing fix — Workspace Equatable | ✅ Done |
| 12 | Build — v2.119.0 (build 117), 31758 KB | ✅ Verified |
| 13 | Tests — 204/204 pass (my code) | ✅ Verified |
| 14 | Webview sizing — fixed 1280x720 frame | ✅ Done |
| 15 | Send button in viewport — verified | ✅ Done |

### Remaining (requires manual testing)
- [ ] Real-world test on Kimi (requires live cookies) — **BLOCKED**: React ignores untrusted clicks; ConnectRPC endpoint needs protobuf schema
- [ ] Real-world test on Qwen (requires live cookies)
- [ ] ChatGPT provider not configured in MiCoder
- [ ] DirectWebAPIClient needs actual API endpoint discovery (NetworkInterceptor captures 0 requests on Kimi) — **PARTIAL**: captures ChatService endpoint but protobuf schema unknown
- [ ] Response capture from DOM after send (awaitResponse not finding response)

### Known Limitations (Kimi-specific)
| Issue | Root Cause | Workaround |
|-------|------------|------------|
| Click doesn't trigger send | React ignores untrusted `click()` events | Requires WebDriver/CDP for trusted events |
| Direct API call fails | ConnectRPC binary protobuf, no public .proto schema | Reverse-engineer schema or find REST alternative |
| NetworkInterceptor captures 0 requests | Page reload clears JS interceptor | Reinstall interceptor after navigation |

---

## Overview

This document describes the smart fallback architecture for sending messages to web chat providers (Kimi, Qwen, ChatGPT) when catalog selectors fail.

## Architecture

```
SmartSend.execute()
  ├─ FallbackRouter.resolve()
  │   ├─ tryDirectAPI() → NetworkInterceptor.findChatAPI()
  │   │   └─ NetworkInterceptor.captureRequests()
  │   ├─ trySmartElement() → SmartElementFinder.findElement()
  │   │   └─ SmartElementFinder.analyzeDOM()
  │   │       └─ SmartElementFinder.classifyElement()
  │   └─ browserAutomation (fallback)
  └─ FallbackRouter.execute()
      ├─ DirectWebAPIClient.send()
      │   └─ URLSession.data(for:)
      ├─ SmartElementFinder + bridge.typeText + bridge.click
      └─ bridge.typeText + bridge.click (standard)
```

---

## Chain 1: SmartElementFinder

### Purpose
Find and classify web UI elements by their function when catalog selectors fail.

### Types

#### `ElementType`
Enum classifying web UI elements by function.

| Case | Description | Class Keywords | Aria Keywords |
|------|-------------|----------------|---------------|
| `.sendButton` | Send message button | send, submit, send-btn, send-button | send, submit, отправить |
| `.input` | Text input field | input, editor, composer, textarea | message, chat, input |
| `.modelDropdown` | Model selection dropdown | model, dropdown, select, switcher | model, select model |
| `.newChat` | New chat button | new-chat, new-chat-btn, create-chat | new chat, создать чат |
| `.effortToggle` | Effort/thinking level toggle | effort, thinking, reasoning | effort, thinking |
| `.stopButton` | Stop generation button | stop, cancel, abort | stop, остановить |
| `.unknown` | Unknown element | (none) | (none) |

#### `SmartElementResult`
Result of smart element finding.

| Field | Type | Description |
|-------|------|-------------|
| `selector` | `String` | CSS selector that found the element |
| `confidence` | `Float` | Confidence score (0.0 - 1.0) |
| `method` | `String` | How the element was found |
| `elementType` | `ElementType` | Classified element type |
| `text` | `String?` | Element text content |
| `ariaLabel` | `String?` | Element aria-label |
| `classes` | `[String]` | Element CSS classes |
| `tagName` | `String` | Element tag name |
| `isVisible` | `Bool` | Whether element is visible |
| `isEnabled` | `Bool` | Whether element is enabled |
| `position` | `ElementPosition?` | Element position in viewport |

#### `ElementPosition`
Element position in viewport.

| Field | Type | Description |
|-------|------|-------------|
| `x` | `Double` | X coordinate |
| `y` | `Double` | Y coordinate |
| `width` | `Double` | Element width |
| `height` | `Double` | Element height |

#### `DOMAnalysis`
DOM analysis result.

| Field | Type | Description |
|-------|------|-------------|
| `buttons` | `[ElementInfo]` | All button elements |
| `inputs` | `[ElementInfo]` | All input elements |
| `dropdowns` | `[ElementInfo]` | All dropdown elements |
| `links` | `[ElementInfo]` | All link elements |
| `allInteractive` | `[ElementInfo]` | All interactive elements |

#### `ElementInfo`
Information about a single DOM element.

| Field | Type | Description |
|-------|------|-------------|
| `selector` | `String` | CSS selector |
| `tagName` | `String` | Element tag name |
| `text` | `String` | Text content |
| `ariaLabel` | `String` | Aria label |
| `classes` | `[String]` | CSS classes |
| `isVisible` | `Bool` | Visibility |
| `isEnabled` | `Bool` | Enabled state |
| `position` | `ElementPosition?` | Position |
| `elementType` | `ElementType` | Classified type |
| `confidence` | `Float` | Classification confidence |

### Functions

#### `findElement(bridge:description:context:)`
Find an element by natural language description.

| Parameter | Type | Description |
|-----------|------|-------------|
| `bridge` | `BrowserAutomationBridge` | Browser automation bridge |
| `description` | `String` | Natural language description |
| `context` | `String` | Current page URL or context |
| **Returns** | `SmartElementResult?` | Best matching element |

**Flow:**
1. `analyzeDOM()` → get all interactive elements
2. `classifyAll()` → classify each element
3. `rankByDescription()` → rank by description match
4. Return best match above threshold (0.5)

**Side Effects:**
- Executes JavaScript in WKWebView
- Reads DOM structure

---

#### `analyzeDOM(bridge:)`
Analyze the DOM and classify all interactive elements.

| Parameter | Type | Description |
|-----------|------|-------------|
| `bridge` | `BrowserAutomationBridge` | Browser automation bridge |
| **Returns** | `DOMAnalysis` | All interactive elements classified |

**JavaScript Executed:**
```javascript
// Scans for: button, a[href], input, textarea,
// [role="button"], [role="textbox"], [role="combobox"],
// [role="option"], [role="menuitem"],
// [contenteditable="true"], [tabindex]
```

**Side Effects:**
- Executes JavaScript in WKWebView
- Reads DOM structure
- Returns up to 500 elements

---

#### `classifyElement(tagName:classes:ariaLabel:text:role:ariaHasPopup:inputType:placeholder:contentEditable:svgName:dataTestId:position:)`
Classify an element by its attributes.

| Parameter | Type | Description |
|-----------|------|-------------|
| `tagName` | `String` | Element tag name |
| `classes` | `[String]` | CSS classes |
| `ariaLabel` | `String` | Aria label |
| `text` | `String` | Text content |
| `role` | `String` | ARIA role |
| `ariaHasPopup` | `String` | aria-haspopup value |
| `inputType` | `String` | Input type attribute |
| `placeholder` | `String` | Placeholder text |
| `contentEditable` | `String` | contenteditable value |
| `svgName` | `String` | SVG icon name |
| `dataTestId` | `String` | data-testid value |
| `position` | `ElementPosition?` | Element position |
| **Returns** | `ElementType` | Classified element type |

**Classification Algorithm:**
1. Check CSS classes for keywords
2. Check aria-label for keywords
3. Check SVG icon names
4. Check data-testid
5. Apply type-specific heuristics
6. Return highest scoring type

**Side Effects:**
- None (pure function)

---

## Chain 2: NetworkInterceptor

### Purpose
Capture XHR/fetch requests from WKWebView for analysis.

### Types

#### `CapturedRequest`
A single captured network request.

| Field | Type | Description |
|-------|------|-------------|
| `url` | `String` | Request URL |
| `method` | `String` | HTTP method |
| `headers` | `[String: String]` | Request headers |
| `body` | `String?` | Request body |
| `timestamp` | `Date` | When captured |
| `requestID` | `String` | Tracking ID |

#### `CapturedResponse`
A single captured network response.

| Field | Type | Description |
|-------|------|-------------|
| `url` | `String` | Response URL |
| `status` | `Int` | HTTP status code |
| `headers` | `[String: String]` | Response headers |
| `body` | `String?` | Response body |
| `requestID` | `String` | Associated request ID |
| `timestamp` | `Date` | When captured |

#### `ChatAPIEndpoint`
Identified chat API endpoint.

| Field | Type | Description |
|-------|------|-------------|
| `url` | `String` | Full API URL |
| `method` | `String` | HTTP method |
| `headers` | `[String: String]` | Required headers |
| `bodyTemplate` | `String` | Body template with {{message}} |
| `isStreaming` | `Bool` | Whether SSE endpoint |
| `contentType` | `String` | Content type |
| `authLocation` | `String?` | Auth token location |
| `authToken` | `String?` | Auth token value |

### Functions

#### `install(bridge:)`
Install the network interceptor by injecting JavaScript.

| Parameter | Type | Description |
|-----------|------|-------------|
| `bridge` | `BrowserAutomationBridge` | Browser automation bridge |
| **Returns** | `Void` | |

**JavaScript Injected:**
- Overrides `XMLHttpRequest.prototype.open`
- Overrides `XMLHttpRequest.prototype.send`
- Overrides `XMLHttpRequest.prototype.setRequestHeader`
- Overrides `window.fetch`
- Stores data in `window.__micoder_requests` and `window.__micoder_responses`

**Side Effects:**
- Modifies global XMLHttpRequest and fetch
- Stores captured data in window object

---

#### `captureRequests(bridge:)`
Capture all intercepted requests.

| Parameter | Type | Description |
|-----------|------|-------------|
| `bridge` | `BrowserAutomationBridge` | Browser automation bridge |
| **Returns** | `[CapturedRequest]` | Captured requests |

**Side Effects:**
- Reads from `window.__micoder_requests`
- Clears captured data

---

#### `captureResponses(bridge:)`
Capture all intercepted responses.

| Parameter | Type | Description |
|-----------|------|-------------|
| `bridge` | `BrowserAutomationBridge` | Browser automation bridge |
| **Returns** | `[CapturedResponse]` | Captured responses |

**Side Effects:**
- Reads from `window.__micoder_responses`
- Clears captured data

---

#### `findChatAPI(requests:)`
Find chat API endpoint from captured requests.

| Parameter | Type | Description |
|-----------|------|-------------|
| `requests` | `[CapturedRequest]` | Captured requests |
| **Returns** | `ChatAPIEndpoint?` | Chat API endpoint |

**Detection Logic:**
1. Filter POST requests with JSON Content-Type
2. Check body for message/content/prompt fields
3. Check URL for chat/send/message/api paths
4. Extract auth tokens from headers

**Side Effects:**
- None (pure function)

---

#### `buildDirectRequest(endpoint:cookies:message:)`
Build a direct URLRequest from an endpoint.

| Parameter | Type | Description |
|-----------|------|-------------|
| `endpoint` | `ChatAPIEndpoint` | Chat API endpoint |
| `cookies` | `[BrowserCookie]` | Browser cookies |
| `message` | `String` | Message to send |
| **Returns** | `URLRequest` | Configured request |

**Side Effects:**
- None (pure function)

---

## Chain 3: DirectWebAPIClient

### Purpose
Send messages directly via API with cookies from WKWebView.

### Types

#### `DirectAPIResult`
Result of a direct API call.

| Field | Type | Description |
|-------|------|-------------|
| `success` | `Bool` | Whether request succeeded |
| `response` | `String?` | Response body |
| `error` | `String?` | Error message |
| `statusCode` | `Int` | HTTP status code |
| `headers` | `[String: String]` | Response headers |
| `duration` | `TimeInterval` | Request duration |
| `wasStreaming` | `Bool` | Whether response was streamed |

#### `SSEEvent`
A parsed SSE event.

| Field | Type | Description |
|-------|------|-------------|
| `type` | `String` | Event type |
| `data` | `String` | Event data |
| `id` | `String?` | Event ID |
| `retry` | `Int?` | Retry interval ms |

### Functions

#### `send(message:endpoint:cookies:timeout:)`
Send a message directly via API.

| Parameter | Type | Description |
|-----------|------|-------------|
| `message` | `String` | Message to send |
| `endpoint` | `ChatAPIEndpoint` | Chat API endpoint |
| `cookies` | `[BrowserCookie]` | Browser cookies |
| `timeout` | `TimeInterval` | Request timeout |
| **Returns** | `DirectAPIResult` | API result |

**Flow:**
1. Build URLRequest from endpoint
2. Add cookies and auth tokens
3. Send via URLSession
4. Parse response
5. Handle errors

**Side Effects:**
- Makes HTTP request
- May trigger server-side actions

---

#### `stream(message:endpoint:cookies:onChunk:)`
Send a message and stream response via SSE.

| Parameter | Type | Description |
|-----------|------|-------------|
| `message` | `String` | Message to send |
| `endpoint` | `ChatAPIEndpoint` | Chat API endpoint |
| `cookies` | `[BrowserCookie]` | Browser cookies |
| `onChunk` | `(SSEEvent) -> Void` | Called for each SSE event |
| **Returns** | `DirectAPIResult` | API result |

**SSE Format:**
```
data: {"choices":[{"delta":{"content":"Hello"}}]}

data: {"choices":[{"delta":{"content":" world"}}]}

data: [DONE]
```

**Side Effects:**
- Makes streaming HTTP request
- Calls onChunk for each event

---

#### `extractCookies(from:)`
Extract cookies from HTTPCookie array.

| Parameter | Type | Description |
|-----------|------|-------------|
| `cookies` | `[HTTPCookie]` | HTTP cookies |
| **Returns** | `String` | Cookie header value |

**Side Effects:**
- None (pure function)

---

#### `convertCookies(_:)`
Convert BrowserCookie array to HTTPCookie array.

| Parameter | Type | Description |
|-----------|------|-------------|
| `browserCookies` | `[BrowserCookie]` | Browser cookies |
| **Returns** | `[HTTPCookie]` | HTTP cookies |

**Side Effects:**
- None (pure function)

---

#### `parseSSEEvent(_:)`
Parse SSE event string into SSEEvent.

| Parameter | Type | Description |
|-----------|------|-------------|
| `eventStr` | `String` | Raw SSE event string |
| **Returns** | `SSEEvent?` | Parsed event |

**Side Effects:**
- None (pure function)

---

#### `extractToken(from:headerName:)`
Extract auth token from headers.

| Parameter | Type | Description |
|-----------|------|-------------|
| `headers` | `[String: String]` | Response headers |
| `headerName` | `String` | Header to extract from |
| **Returns** | `String?` | Auth token |

**Side Effects:**
- None (pure function)

---

## Chain 4: FallbackRouter

### Purpose
Route between sending methods with circuit breaker.

### Types

#### `SendRoute`
Route type for sending messages.

| Case | Description |
|------|-------------|
| `.directAPI(ChatAPIEndpoint)` | Direct API call |
| `.smartElement(String, ElementType)` | Smart element detection |
| `.browserAutomation` | Standard browser automation |
| `.none` | No route available |

#### `SendAttempt`
Result of a send attempt.

| Field | Type | Description |
|-------|------|-------------|
| `method` | `String` | Method used |
| `success` | `Bool` | Whether succeeded |
| `duration` | `TimeInterval` | Duration |
| `error` | `String?` | Error message |
| `response` | `String?` | Response |
| `confidence` | `Float` | Confidence score |

#### `SendResult`
Complete send result.

| Field | Type | Description |
|-------|------|-------------|
| `success` | `Bool` | Overall success |
| `response` | `String?` | Final response |
| `attempts` | `[SendAttempt]` | All attempts |
| `winningMethod` | `String?` | Method that succeeded |
| `duration` | `TimeInterval` | Total duration |

#### `EndpointUpdate`
Endpoint update from failure analysis.

| Field | Type | Description |
|-------|------|-------------|
| `endpoint` | `ChatAPIEndpoint` | Updated endpoint |
| `reason` | `String` | Reason for update |
| `confidence` | `Float` | Confidence in update |

### Functions

#### `resolve(vendor:message:bridge:)`
Resolve the best route for sending a message.

| Parameter | Type | Description |
|-----------|------|-------------|
| `vendor` | `WebChatVendor` | Chat vendor |
| `message` | `String` | Message to send |
| `bridge` | `BrowserAutomationBridge` | Browser bridge |
| **Returns** | `SendRoute` | Best available route |

**Resolution Order:**
1. Check circuit breaker for each method
2. Try Direct API (if endpoint available)
3. Try Smart Element (if element found)
4. Fall back to Browser Automation

**Side Effects:**
- May capture network requests
- May scan DOM for elements

---

#### `tryDirectAPI(vendor:bridge:)`
Try to find a direct API endpoint.

| Parameter | Type | Description |
|-----------|------|-------------|
| `vendor` | `WebChatVendor` | Chat vendor |
| `bridge` | `BrowserAutomationBridge` | Browser bridge |
| **Returns** | `ChatAPIEndpoint?` | Chat API endpoint |

**Side Effects:**
- Captures network requests

---

#### `trySmartElement(vendor:bridge:element:)`
Try to find an element via smart detection.

| Parameter | Type | Description |
|-----------|------|-------------|
| `vendor` | `WebChatVendor` | Chat vendor |
| `bridge` | `BrowserAutomationBridge` | Browser bridge |
| `element` | `ElementType` | Element type to find |
| **Returns** | `String?` | CSS selector |

**Side Effects:**
- Scans DOM for elements

---

#### `execute(route:message:bridge:config:)`
Execute a send route.

| Parameter | Type | Description |
|-----------|------|-------------|
| `route` | `SendRoute` | Send route |
| `message` | `String` | Message to send |
| `bridge` | `BrowserAutomationBridge` | Browser bridge |
| `config` | `WebProviderConfig` | Provider config |
| **Returns** | `SendResult` | Send result |

**Execution:**
1. DirectAPI → URLSession with cookies
2. SmartElement → bridge.typeText + bridge.click
3. BrowserAutomation → standard catalog flow

**Side Effects:**
- May make HTTP request
- May type text in webview
- May click elements

---

## Chain 5: SmartSend

### Purpose
Integrate all components into a single send operation.

### Types

#### `SmartSendResult`
Complete result of smart send.

| Field | Type | Description |
|-------|------|-------------|
| `success` | `Bool` | Whether send succeeded |
| `response` | `String?` | Final response |
| `winningMethod` | `String?` | Method that succeeded |
| `attempts` | `[SendAttempt]` | All attempts |
| `duration` | `TimeInterval` | Total duration |
| `updates` | `[EndpointUpdate]` | Learned updates |

### Functions

#### `execute(message:config:bridge:appState:)`
Execute smart send with all fallbacks.

| Parameter | Type | Description |
|-----------|------|-------------|
| `message` | `String` | Message to send |
| `config` | `WebProviderConfig` | Provider config |
| `bridge` | `BrowserAutomationBridge` | Browser bridge |
| `appState` | `MiCoderAppState?` | Application state |
| **Returns** | `SmartSendResult` | Complete result |

**Flow:**
1. Resolve best route via FallbackRouter
2. Execute route
3. If failed, learn and retry
4. Return result with all attempts

**Side Effects:**
- May make HTTP request
- May type text in webview
- May click elements
- Updates circuit breaker state

---

#### `learnFromFailure(attempt:endpoint:)`
Learn from a failed attempt and suggest endpoint update.

| Parameter | Type | Description |
|-----------|------|-------------|
| `attempt` | `SendAttempt` | Failed attempt |
| `endpoint` | `ChatAPIEndpoint` | Original endpoint |
| **Returns** | `EndpointUpdate?` | Update suggestion |

**Learning Rules:**
1. 401 Unauthorized → token expired
2. 403 Forbidden → CSRF token expired
3. 429 Too Many Requests → rate limited
4. 404 Not Found → endpoint changed
5. 500+ → server error
6. Network error → connectivity issue

**Side Effects:**
- None (pure function)
