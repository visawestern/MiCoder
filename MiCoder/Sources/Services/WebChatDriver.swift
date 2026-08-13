import Foundation

/// Drives a full agentic loop over a plain web chat, turning a tool-less web
/// model into a coding agent (plan Раздел 12 Блок 2 п.15). Pure orchestration:
/// all browser I/O goes through `BrowserAutomationBridge` and all tool execution
/// through `WebToolExecutor`, so the loop is fully unit-testable with fakes and
/// runs against Playwright MCP + real executors in the app — no stubs.
struct WebChatDriver {
    let bridge: BrowserAutomationBridge
    let executor: WebToolExecutor
    let selectors: WebVendorSelectors
    let config: WebProviderConfig
    let projectRoot: String
    let accessLevel: AccessLevel
    /// Injectable RNG for deterministic anti-ban jitter in tests.
    var randomUnit: () -> Double = { Double.random(in: 0..<1) }
    /// Poll interval and stability window for end-of-generation detection.
    var pollIntervalMs: Int = 200
    var stabilityChecks: Int = 3
    /// When false, model/effort injection is skipped (used in unit tests where
    /// the fake bridge has no real web UI to configure).
    var injectModelAndEffortEnabled: Bool = true

    /// Run one user turn: inject the message, then loop tool-calls until the
    /// model produces a final answer or hits the iteration limit. Emits events
    /// (streaming/toolCall/toolResult/captcha/final) via `emit`.
    func runTurn(userMessage: String, isFirstMessage: Bool, emit: (WebChatEvent) -> Void) async {
        do {
            // Inject the selected model and effort before sending, so the web
            // UI reflects the user's current selection (plan Раздел 13 п.5).
            if injectModelAndEffortEnabled {
                try await injectModelAndEffort(emit: emit)
            }

            // On the first message of a session, prepend the tool-protocol preamble.
            var message = userMessage
            if isFirstMessage {
                let preamble = WebToolProtocolEmulator.systemPreamble(userSystemPrompt: config.systemPrompt)
                message = preamble + "\n\n---\n\n" + userMessage
            }

            try await sendPossiblyChunked(message, emit: emit)

            var iteration = 0
            while true {
                // Guard against session drop / captcha before reading.
                if let interruption = try await checkInterruptions(emit: emit) {
                    emit(interruption)
                    return
                }

                let response = try await awaitResponse(emit: emit)

                // Web-model session length limit: restart with carried-over
                // context instead of failing (plan Раздел 12 extension).
                if WebSessionLimitLogic.isSessionLimitReached(responseText: response) {
                    emit(.sessionLimitReached)
                    try await restartSessionWithCarryOver(lastResponse: response, emit: emit)
                    iteration += 1
                    continue
                }

                if WebToolProtocolEmulator.shouldStopLoop(iteration: iteration,
                                                          maxIterations: config.maxToolIterations,
                                                          lastResponse: response) {
                    if WebToolProtocolEmulator.isFinalResponse(response) {
                        emit(.final(response))
                    } else {
                        emit(.iterationLimitReached)
                    }
                    return
                }

                // Execute each requested tool and feed results back.
                let calls = WebToolProtocolEmulator.parseToolCalls(from: response)
                var resultsBlock = ""
                for call in calls {
                    emit(.toolCall(call))
                    if let validationError = WebToolProtocolEmulator.validate(call, projectRoot: projectRoot, accessLevel: accessLevel) {
                        let msg = "validation error: \(validationError)"
                        resultsBlock += WebToolProtocolEmulator.formatToolResult(name: call.name, result: msg) + "\n"
                        emit(.toolResult(name: call.name, result: msg))
                        continue
                    }
                    let result = await executor.execute(call)
                    resultsBlock += WebToolProtocolEmulator.formatToolResult(name: call.name, result: result) + "\n"
                    emit(.toolResult(name: call.name, result: result))
                }

                try await sendPossiblyChunked(resultsBlock, emit: emit)
                iteration += 1
            }
        } catch {
            emit(.error("\(error)"))
        }
    }

    // MARK: - Steps

    /// Send a message, splitting a large PROMPT into several messages so we don't
    /// overload the web model / hit its session length limit (plan Раздел 12
    /// extension). Non-final parts use the continuation protocol so the model
    /// waits before responding; only the final part triggers generation.
    private func sendPossiblyChunked(_ text: String, emit: (WebChatEvent) -> Void) async throws {
        let parts = WebPromptChunker.chunkedMessages(text)
        if parts.count > 1 { emit(.promptSplit(parts: parts.count)) }
        for (idx, part) in parts.enumerated() {
            try await sendMessage(part, emit: emit)
            // For non-final continuation parts, wait briefly for the message to
            // register but do NOT wait for a full generation (model is instructed
            // to hold its answer until the final part).
            if idx < parts.count - 1 {
                await bridge.wait(ms: max(config.toolCallDelayMs, 300))
            }
        }
    }

    private func sendMessage(_ text: String, emit: (WebChatEvent) -> Void) async throws {
        await antiBanDelay()
        try await bridge.typeText(text, into: selectors.input, humanized: config.toolCallDelayMs > 0)
        await antiBanDelay()
        try await bridge.click(selector: selectors.sendButton)
    }

    /// Restart the web session after a length-limit response, seeding a fresh
    /// chat with the tool preamble + goal + a compact recent summary so work
    /// continues instead of failing (plan Раздел 12 extension).
    private func restartSessionWithCarryOver(lastResponse: String, emit: (WebChatEvent) -> Void) async throws {
        try await bridge.navigate(to: config.chatURL)
        await bridge.wait(ms: max(config.toolCallDelayMs, 500))
        let preamble = WebToolProtocolEmulator.systemPreamble(userSystemPrompt: config.systemPrompt)
        // Recent summary = the last response minus the limit notice; the caller's
        // system prompt / goal carry the durable intent. No fabricated content.
        let recent = WebSessionLimitLogic.limitMarkers.reduce(lastResponse) { acc, marker in
            acc.replacingOccurrences(of: marker, with: "", options: .caseInsensitive)
        }.trimmingCharacters(in: .whitespacesAndNewlines)
        let seed = WebSessionLimitLogic.carryOverSeed(systemPreamble: preamble,
                                                      goal: config.systemPrompt.isEmpty ? nil : config.systemPrompt,
                                                      recentSummary: String(recent.prefix(2000)))
        try await sendPossiblyChunked(seed, emit: emit)
        emit(.sessionRestarted)
    }

    /// Wait until generation finishes: the stop button disappears and the
    /// response text is stable across `stabilityChecks` polls (plan Блок 2 п.24).
    private func awaitResponse(emit: (WebChatEvent) -> Void) async throws -> String {
        var lastText = ""
        var stableCount = 0
        // Bound the wait to avoid infinite loops on a broken page.
        let maxPolls = 600  // pollIntervalMs * 600 = up to 2 min at 200ms
        var polls = 0
        while polls < maxPolls {
            let generating = (try? await bridge.exists(selector: selectors.stopButton)) ?? false
            let text = (try? await readLatestResponse()) ?? lastText
            if text != lastText {
                emit(.streaming(text))
                lastText = text
                stableCount = 0
            } else if !generating {
                stableCount += 1
                if stableCount >= stabilityChecks { return text }
            }
            await bridge.wait(ms: pollIntervalMs)
            polls += 1
        }
        return lastText
    }

    // Read the last assistant message from the DOM. Tries the vendor-specific
    // response container first, then falls back to common selectors so we do
    // not falsely report "empty response" while the page is still hydrating.
    private func readLatestResponse() async throws -> String {
        if let primary = (try? await bridge.readText(selector: selectors.responseContainer)), !primary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return primary
        }
        let fallbacks = [
            "div[data-message-author-role='assistant']",
            ".markdown-body",
            "[class*='markdown']",
            "[class*='response']",
            "[class*='message-content']"
        ]
        for selector in fallbacks {
            if let text = (try? await bridge.readText(selector: selector)), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return text
            }
        }
        return ""
    }

    /// Detect captcha / logout before proceeding (plan Блок 3 п.32/п.34).
    private func checkInterruptions(emit: (WebChatEvent) -> Void) async throws -> WebChatEvent? {
        let url = (try? await bridge.currentURL()) ?? ""
        let pageText = (try? await bridge.pageText()) ?? ""
        let hasInput = (try? await bridge.exists(selector: selectors.input)) ?? true
        switch WebSessionLogic.inferState(currentURL: url, hasChatInput: hasInput, pageText: pageText) {
        case .captchaRequired:
            let png = (try? await bridge.screenshot(selector: nil)) ?? Data()
            return .captchaDetected(screenshotPNG: png)
        case .loggedOut:
            return .loggedOut
        case .connected, .unknown:
            return nil
        }
    }

    /// Inject the currently selected model and effort into the web UI before
    /// sending a message. Reads the vendor selectors from the catalog; if the
    /// dropdowns are present, clicks them and selects the matching option.
    /// Best-effort — failures are surfaced as events but don't abort the turn.
    private func injectModelAndEffort(emit: (WebChatEvent) -> Void) async throws {
        // Resolve vendor-specific selectors from the catalog.
        guard let catalogEntry = try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id) else {
            return
        }

        // Inject model selection.
        if !config.selectedModel.isEmpty,
           let modelSelector = catalogEntry.modelDropdown.split(separator: ",").first.map(String.init) {
            do {
                try await bridge.click(selector: modelSelector.trimmingCharacters(in: .whitespaces))
                // Wait for custom dropdown to open
                try? await bridge.waitForSelector(selector: "div.model-item, [class*='model-item'], [role='option']", timeout: 5000)
                await bridge.wait(ms: 500)

                // Try to find and click the matching model
                let modelText = config.selectedModel
                let itemSelector = catalogEntry.modelItem ?? "[role='option'], [class*='option']"
                let clicked = (try? await bridge.clickByText(selector: itemSelector, text: modelText)) ?? false
                if !clicked {
                    // Fallback: try any element containing the model name
                    _ = (try? await bridge.clickByText(selector: "li, div, span, button", text: modelText))
                }
                await bridge.wait(ms: 300)
            } catch {
                emit(.modelInjectionFailed(L.t(AppLocalizationKey.locWebModelInjectionFailed).replacingOccurrences(of: "{0}", with: error.localizedDescription)))
            }
        }

        // Inject effort selection. Try each comma-separated selector in order;
        // only report failure if NONE of them work.
        if let effortLabel = effortLabel(for: config.effort) {
            let selectors = (catalogEntry.effortDropdown?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } ?? [])
                .filter { !$0.isEmpty }
            var anySuccess = false
            var lastError: String = ""
            for selector in selectors {
                do {
                    if (try? await bridge.exists(selector: selector)) == true {
                        try await bridge.click(selector: selector)
                        try? await bridge.waitForSelector(selector: "[class*='effort'], [class*='thinking'], [role='option'], [class*='option']", timeout: 5000)
                        await bridge.wait(ms: 500)
                        let itemSelector = catalogEntry.effortItem ?? "[role='option'], [class*='option']"
                        let clicked = (try? await bridge.clickByText(selector: itemSelector, text: effortLabel)) ?? false
                        if !clicked {
                            _ = (try? await bridge.clickByText(selector: "li, div, span, button", text: effortLabel))
                        }
                        await bridge.wait(ms: 300)
                        anySuccess = true
                        break
                    }
                } catch {
                    lastError = error.localizedDescription
                }
            }
            if !anySuccess && !selectors.isEmpty {
                emit(.effortInjectionFailed(L.t(AppLocalizationKey.locWebEffortNote).replacingOccurrences(of: "{0}", with: lastError.isEmpty ? "effort selector not found" : lastError)))
            }
        }
    }

    /// Start a new chat session by clicking the "New Chat" button.
    /// Returns the new chat URL or nil if could not determine.
    func startNewSession() async throws -> String? {
        guard let catalogEntry = try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id) else {
            return nil
        }

        // Try each "New Chat" text variant until one works
        let newChatTexts = catalogEntry.newChatTexts ?? ["New Chat", "Новый чат", "Начать", "新对话"]
        for text in newChatTexts {
            let clicked = (try? await bridge.clickByText(selector: "button, a, div", text: text)) ?? false
            if clicked {
                await bridge.wait(ms: 2000)
                return try await bridge.currentURL()
            }
        }
        return nil
    }

    /// Extract the chat ID/slug from the current URL.
    func getCurrentChatID() async throws -> String? {
        let url = try await bridge.currentURL()
        // Kimi: /chat/{id}, Qwen: /chat/{id}, ChatGPT: /c/{id}
        let patterns = ["/chat/", "/c/"]
        for pattern in patterns {
            if let range = url.range(of: pattern) {
                let after = url[range.upperBound...]
                let chatId = after.split(separator: "/").first.map(String.init) ?? String(after)
                if !chatId.isEmpty { return chatId }
            }
        }
        return nil
    }

    /// Select a model in the web UI.
    func selectModel(_ modelName: String) async throws {
        let selector = try modelSelector()
        // Click model button
        try await bridge.click(selector: selector)
        // Wait for dropdown
        try await bridge.waitForSelector(selector: "div.model-item, [class*='model-item']", timeout: 5000)
        // Find and click matching model
        let clicked = try await bridge.clickByText(
            selector: "div.model-item, [class*='model-item']",
            text: modelName
        )
        if !clicked {
            throw WebChatError.modelNotFound(L.t(AppLocalizationKey.locWebModelNotFound).replacingOccurrences(of: "{0}", with: modelName))
        }
        await bridge.wait(ms: 500)
    }

    /// Select a mode (auto/think/fast/image).
    func selectMode(_ mode: String) async throws {
        switch config.vendor {
        case .qwen:
            try await bridge.click(selector: "[class*='mode-select']")
            try await bridge.waitForSelector(selector: ".ant-select-item-option", timeout: 5000)
            let clicked = try await bridge.clickByText(
                selector: ".ant-select-item-option-content",
                text: mode
            )
            if !clicked { throw WebChatError.modeNotFound(mode) }
        case .kimi:
            // Kimi modes are in sidebar
            let clicked = try await bridge.clickByText(
                selector: "a, button, [role='button']",
                text: mode
            )
            if !clicked { throw WebChatError.modeNotFound(mode) }
        default:
            break
        }
        await bridge.wait(ms: 500)
    }

    /// Select thinking/effort level.
    func selectThinking(_ level: WebEffort) async throws {
        let label = effortLabel(for: level) ?? level.displayName
        switch config.vendor {
        case .qwen:
            try await bridge.click(selector: "[class*='qwen-select-thinking']")
            try await bridge.waitForSelector(selector: ".ant-select-item-option", timeout: 5000)
            let clicked = try await bridge.clickByText(
                selector: ".ant-select-item-option-content",
                text: label
            )
            if !clicked { throw WebChatError.effortNotFound(label) }
        case .kimi:
            try await bridge.click(selector: "[class*='effort']")
            try await bridge.waitForSelector(selector: "[class*='effort-option'], [role='option']", timeout: 5000)
            let clicked = try await bridge.clickByText(
                selector: "[class*='effort-option'], [role='option']",
                text: label
            )
            if !clicked { throw WebChatError.effortNotFound(label) }
        default:
            break
        }
        await bridge.wait(ms: 500)
    }

    /// Resolve the model selector for the current vendor.
    private func modelSelector() throws -> String {
        if let custom = config.customModelSelector, !custom.isEmpty { return custom }
        if let catalog = try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id) {
            if let button = catalog.modelButton, !button.isEmpty { return button }
            if let first = catalog.modelDropdown.components(separatedBy: ",").first {
                return first.trimmingCharacters(in: .whitespaces)
            }
        }
        throw WebChatError.noModelSelector
    }

    /// Map a WebEffort to a vendor-specific label for matching in the dropdown.
    private func effortLabel(for effort: WebEffort) -> String? {
        switch config.vendor {
        case .kimi:
            switch effort {
            case .low: return "快"
            case .medium: return "标准"
            case .high: return "深度思考"
            }
        case .qwen:
            switch effort {
            case .low: return "快"
            case .medium: return "标准"
            case .high: return "深度思考"
            }
        case .chatgpt:
            switch effort {
            case .low: return "low"
            case .medium: return "medium"
            case .high: return "high"
            }
        case .custom:
            return nil
        }
    }

    private func antiBanDelay() async {
        let ms = WebAntiBanTiming.delayMs(base: config.toolCallDelayMs, randomUnit: randomUnit())
        if ms > 0 { await bridge.wait(ms: ms) }
    }
}

/// Errors that can occur during web chat operations.
enum WebChatError: LocalizedError {
    case modelNotFound(String)
    case modeNotFound(String)
    case effortNotFound(String)
    case noModelSelector
    case noSession

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let m): return "Model '\(m)' not found in web UI"
        case .modeNotFound(let m): return "Mode '\(m)' not found in web UI"
        case .effortNotFound(let e): return "Effort level '\(e)' not found"
        case .noModelSelector: return "No model selector configured for this vendor"
        case .noSession: return "No active web session"
        }
    }
}
