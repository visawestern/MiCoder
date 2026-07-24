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
    /// Injectable RNG for deterministic anti-ban jitter in tests.
    var randomUnit: () -> Double = { Double.random(in: 0..<1) }
    /// Poll interval and stability window for end-of-generation detection.
    var pollIntervalMs: Int = 200
    var stabilityChecks: Int = 3

    /// Run one user turn: inject the message, then loop tool-calls until the
    /// model produces a final answer or hits the iteration limit. Emits events
    /// (streaming/toolCall/toolResult/captcha/final) via `emit`.
    func runTurn(userMessage: String, isFirstMessage: Bool, emit: (WebChatEvent) -> Void) async {
        do {
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
                    if let validationError = WebToolProtocolEmulator.validate(call, projectRoot: projectRoot) {
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
            let text = (try? await bridge.readText(selector: selectors.responseContainer)) ?? lastText
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

    private func antiBanDelay() async {
        let ms = WebAntiBanTiming.delayMs(base: config.toolCallDelayMs, randomUnit: randomUnit())
        if ms > 0 { await bridge.wait(ms: ms) }
    }
}
