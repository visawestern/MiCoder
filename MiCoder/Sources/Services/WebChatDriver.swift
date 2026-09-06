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

    private struct ResponseBaseline {
        let text: String
        let fingerprint: String
    }

    /// Run one user turn: inject the message, then loop tool-calls until the
    /// model produces a final answer or hits the iteration limit. Emits events
    /// (streaming/toolCall/toolResult/captcha/final) via `emit`.
    func runTurn(userMessage: String, isFirstMessage: Bool, emit: (WebChatEvent) -> Void, skipSend: Bool = false, preSendFingerprint: String? = nil) async {
        print("🔄 [WebChatDriver] runTurn started, skipSend=\(skipSend)")
        do {
            try Task.checkCancellation()
            // Check session state before touching any model/effort controls. A
            // logged-out or captcha page must produce its actionable interruption
            // event rather than a misleading injection failure.
            if let interruption = try await checkInterruptions(emit: emit) {
                if case .captchaDetected = interruption {
                    emit(interruption)
                    try await waitForCaptchaResolution(emit: emit)
                } else {
                    emit(interruption)
                    print("🔄 [WebChatDriver] runTurn interrupted")
                    return
                }
            }

            // Inject the selected model and effort before sending, so the web
            // UI reflects the user's current selection (plan Раздел 13 п.5).
            if injectModelAndEffortEnabled {
                let injectionSucceeded = await injectModelAndEffort(emit: emit)
                guard injectionSucceeded else {
                    // Never type/send when the browser did not confirm the
                    // selected model or required effort. The caller may refresh
                    // the live catalog and retry this same local turn safely.
                    print("🔄 [WebChatDriver] runTurn: injection failed")
                    return
                }
            }

            // On the first message of a session, prepend the tool-protocol preamble.
            var message = userMessage
            if isFirstMessage {
                let preamble = WebToolProtocolEmulator.systemPreamble(
                    userSystemPrompt: config.systemPrompt,
                    projectRoot: projectRoot,
                    directory: projectRoot,
                    isGitRepo: (try? GitRepository.repositoryRoot(for: projectRoot)) != nil
                )
                message = preamble + "\n\n---\n\n" + userMessage
            }

            // If skipSend is true, SmartSend already typed and clicked.
            // Just get the baseline response and wait for the answer.
            var responseBaseline: ResponseBaseline
            if skipSend {
                print("🔄 [WebChatDriver] skipSend=true, getting baseline response")
                let baselineText: String
                let baselineFingerprint: String
                if let preSendFingerprint {
                    // Round 30b: the answer may ALREADY be fully rendered by the
                    // time we get here (binding + injection took seconds). Use
                    // the fingerprint captured BEFORE SmartSend submitted so any
                    // post-send content counts as new.
                    baselineText = ""
                    baselineFingerprint = preSendFingerprint
                } else {
                    baselineText = (try? await readLatestResponse()) ?? ""
                    baselineFingerprint = (try? await bridge.responseFingerprint(selector: selectors.responseContainer)) ?? baselineText
                }
                print("🔄 [WebChatDriver] baseline: text_len=\(baselineText.count), fingerprint_len=\(baselineFingerprint.count)")
                responseBaseline = ResponseBaseline(text: baselineText, fingerprint: baselineFingerprint)
            } else {
                print("🔄 [WebChatDriver] skipSend=false, calling sendPossiblyChunked")
                responseBaseline = try await sendPossiblyChunked(message, emit: emit)
            }

            var iteration = 0
            while true {
                try Task.checkCancellation()
                // Guard against session drop / captcha before reading.
                if let interruption = try await checkInterruptions(emit: emit) {
                    if case .captchaDetected = interruption {
                        emit(interruption)
                        try await waitForCaptchaResolution(emit: emit)
                    } else {
                        emit(interruption)
                        return
                    }
                }

                let response = try await awaitResponse(after: responseBaseline, emit: emit)

                // Web-model session length limit: restart with carried-over
                // context instead of failing (plan Раздел 12 extension).
                if WebSessionLimitLogic.isSessionLimitReached(responseText: response) {
                    emit(.sessionLimitReached)
                    responseBaseline = try await restartSessionWithCarryOver(lastResponse: response, emit: emit)
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
                // Images requested via read_file are attached to the NEXT
                // composer message through the vendor's real upload flow
                // (vision works in every web chat, but only via attachments).
                var pendingImages: [(mime: String, data: Data)] = []
                for call in calls {
                    emit(.toolCall(call))
                    if WebToolAccessGate.permission(for: call, accessLevel: accessLevel) == .requireApproval {
                        let message = "\(call.name) requires approval (AccessLevel: \(accessLevel.rawValue)); not executed"
                        emit(.approvalRequired(tool: call.name, message: message))
                        return
                    }
                    if let validationError = WebToolProtocolEmulator.validate(call, projectRoot: projectRoot, accessLevel: accessLevel) {
                        let msg = "validation error: \(validationError)"
                        resultsBlock += WebToolProtocolEmulator.formatToolResult(name: call.name, result: msg) + "\n"
                        emit(.toolResult(name: call.name, result: msg))
                        continue
                    }
                    let result = await executor.execute(call)
                    if let image = (executor as? ProjectWebToolExecutor) != nil
                        ? ProjectWebToolExecutor.parseAttachedImage(from: result)
                        : nil {
                        pendingImages.append((image.mime, image.data))
                        // Never inline megabytes of base64 into the chat text.
                        let summary = "Image \"\(call.arguments["path"] ?? "?")\" is attached to this message; analyze it visually."
                        resultsBlock += WebToolProtocolEmulator.formatToolResult(name: call.name, result: summary) + "\n"
                        emit(.toolResult(name: call.name, result: summary))
                        continue
                    }
                    resultsBlock += WebToolProtocolEmulator.formatToolResult(name: call.name, result: result) + "\n"
                    emit(.toolResult(name: call.name, result: result))
                }

                // Attach every collected image to the composer before the
                // results text goes out, so the vendor's upload handler binds
                // the real bytes to this outgoing message.
                for image in pendingImages {
                    _ = try? await bridge.attachImageToComposer(data: image.data, mime: image.mime)
                    await bridge.wait(ms: 500)
                }

                responseBaseline = try await sendPossiblyChunked(resultsBlock, emit: emit)
                iteration += 1
            }
        } catch is CancellationError {
            return
        } catch let error as WebChatError {
            switch error {
            case .captchaResolutionAborted, .sessionLoggedOut:
                return
            default:
                emit(.error(error.localizedDescription))
            }
        } catch {
            emit(.error("\(error)"))
        }
    }

    // MARK: - Steps

    /// Wait for the user to solve a captcha in the same live browser page.
    /// The chat turn remains in the driver; no duplicate prompt or new remote
    /// chat is created. A logout aborts the turn and a bounded timeout avoids a
    /// permanently suspended task.
    private func waitForCaptchaResolution(emit: (WebChatEvent) -> Void) async throws {
        let maxPolls = 600 // five minutes at 500 ms
        for _ in 0..<maxPolls {
            try Task.checkCancellation()
            await bridge.wait(ms: 500)
            let url = (try? await bridge.currentURL()) ?? ""
            let pageText = (try? await bridge.pageText()) ?? ""
            let hasInput = (try? await bridge.exists(selector: selectors.input)) ?? false
            let state = WebSessionLogic.inferState(
                currentURL: url,
                hasChatInput: hasInput,
                pageText: pageText
            )
            switch WebCaptchaResolutionLogic.action(for: state) {
            case .resume:
                return
            case .abort:
                emit(.loggedOut)
                throw WebChatError.captchaResolutionAborted
            case .wait:
                continue
            }
        }
        throw WebChatError.captchaResolutionTimedOut
    }

    /// Send a message, splitting a large PROMPT into several messages so we don't
    /// overload the web model / hit its session length limit (plan Раздел 12
    /// extension). Non-final parts use the continuation protocol so the model
    /// waits before responding; only the final part triggers generation.
    private func sendPossiblyChunked(_ text: String, emit: (WebChatEvent) -> Void) async throws -> ResponseBaseline {
        let parts = WebPromptChunker.chunkedMessages(text)
        if parts.count > 1 { emit(.promptSplit(parts: parts.count)) }
        var baseline = ResponseBaseline(text: "", fingerprint: "")
        for (idx, part) in parts.enumerated() {
            baseline = try await sendMessage(part, emit: emit)
            // For non-final continuation parts, wait briefly for the message to
            // register but do NOT wait for a full generation (model is instructed
            // to hold its answer until the final part).
            if idx < parts.count - 1 {
                await bridge.wait(ms: max(config.toolCallDelayMs, 300))
            }
        }
        return baseline
    }

    /// Type and submit one message. The returned text is the response already
    /// present before this submit; awaitResponse uses it as a baseline so an
    /// empty/old DOM node can never be reported as the new answer.
    private func sendMessage(_ text: String, emit: (WebChatEvent) -> Void) async throws -> ResponseBaseline {
        guard (try? await bridge.exists(selector: selectors.input)) == true else {
            throw WebChatError.selectorNotFound(selectors.input)
        }
        guard (try? await bridge.exists(selector: selectors.sendButton)) == true else {
            throw WebChatError.selectorNotFound(selectors.sendButton)
        }
        let baselineText = (try? await readLatestResponse()) ?? ""
        let baselineFingerprint = (try? await bridge.responseFingerprint(selector: selectors.responseContainer)) ?? baselineText
        await antiBanDelay()
        try await bridge.typeText(text, into: selectors.input, humanized: config.toolCallDelayMs > 0, pressEnter: true)
        await antiBanDelay()
        try await bridge.click(selector: selectors.sendButton)
        return ResponseBaseline(text: baselineText, fingerprint: baselineFingerprint)
    }

    /// Restart the web session after a length-limit response, seeding a fresh
    /// chat with the tool preamble + goal + a compact recent summary so work
    /// continues instead of failing (plan Раздел 12 extension).
    private func restartSessionWithCarryOver(lastResponse: String, emit: (WebChatEvent) -> Void) async throws -> ResponseBaseline {
        try await bridge.navigate(to: config.chatURL)
        await bridge.wait(ms: max(config.toolCallDelayMs, 500))
        let preamble = WebToolProtocolEmulator.systemPreamble(
            userSystemPrompt: config.systemPrompt,
            projectRoot: projectRoot,
            directory: projectRoot,
            isGitRepo: (try? GitRepository.repositoryRoot(for: projectRoot)) != nil
        )
        // Recent summary = the last response minus the limit notice; the caller's
        // system prompt / goal carry the durable intent. No fabricated content.
        let recent = WebSessionLimitLogic.limitMarkers.reduce(lastResponse) { acc, marker in
            acc.replacingOccurrences(of: marker, with: "", options: .caseInsensitive)
        }.trimmingCharacters(in: .whitespacesAndNewlines)
        let seed = WebSessionLimitLogic.carryOverSeed(systemPreamble: preamble,
                                                      goal: config.systemPrompt.isEmpty ? nil : config.systemPrompt,
                                                      recentSummary: String(recent.prefix(2000)))
        let baseline = try await sendPossiblyChunked(seed, emit: emit)
        emit(.sessionRestarted)
        return baseline
    }

    /// Wait until generation finishes: the stop button disappears and the
    /// response text is stable across `stabilityChecks` polls (plan Блок 2 п.24).
    private func awaitResponse(after baseline: ResponseBaseline, emit: (WebChatEvent) -> Void) async throws -> String {
        var lastText = baseline.text
        var lastFingerprint = baseline.fingerprint
        var stableCount = 0
        var hasNonEmptyResponse = false
        var observedNewResponse = false
        // Bound the wait to avoid infinite loops on a broken page.
        let maxPolls = 600  // pollIntervalMs * 600 = up to 2 min at 200ms
        var polls = 0
        print("🔄 [WebChatDriver] awaitResponse started, baseline_text_len=\(baseline.text.count), maxPolls=\(maxPolls)")
        while polls < maxPolls {
            try Task.checkCancellation()
            if let interruption = try await checkInterruptions(emit: emit) {
                if case .captchaDetected = interruption {
                    emit(interruption)
                    try await waitForCaptchaResolution(emit: emit)
                } else {
                    emit(interruption)
                    throw WebChatError.sessionLoggedOut
                }
            }

            let generating = (try? await bridge.exists(selector: selectors.stopButton)) ?? false
            let text = (try? await readLatestResponse()) ?? lastText
            let fingerprint = (try? await bridge.responseFingerprint(selector: selectors.responseContainer)) ?? text
            let changed = text != baseline.text || fingerprint != baseline.fingerprint
            let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if polls % 50 == 0 {
                print("🔄 [WebChatDriver] poll \(polls): generating=\(generating), text_len=\(text.count), changed=\(changed), normalized_len=\(normalized.count)")
            }
            if !normalized.isEmpty && changed {
                hasNonEmptyResponse = true
                observedNewResponse = true
            }
            if text != lastText || fingerprint != lastFingerprint {
                if observedNewResponse { emit(.streaming(text)) }
                lastText = text
                lastFingerprint = fingerprint
                stableCount = 0
            } else if !generating && hasNonEmptyResponse && observedNewResponse {
                stableCount += 1
                if stableCount >= stabilityChecks { return lastText }
            }
            await bridge.wait(ms: pollIntervalMs)
            polls += 1
        }
        // An unchanged empty DOM is a failed send/response, not a valid answer.
        // Surface a timeout so the caller can retry the browser path instead of
        // presenting the misleading "model returned empty response" message.
        throw WebChatError.responseTimeout
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
    /// Returns false when a requested model/effort could not be confirmed. The
    /// caller must abort before typing so a recovery retry cannot duplicate text.
    private func injectModelAndEffort(emit: (WebChatEvent) -> Void) async -> Bool {
        // Round 30b: let post-submission navigation settle first.
        await waitForPageURLStability()
        // Resolve vendor-specific selectors from the catalog. A custom provider
        // may have no bundled entry, but can still be safe when the user saved a
        // custom model selector. A selected model without either route is a hard
        // failure: never send under an unverified model.
        let catalogEntry = try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id)
        var injectionSucceeded = true

        // Model selection requires exact confirmation before sending.
        if !config.selectedModel.isEmpty {
            let configuredModelButton = config.customModelSelector?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? catalogEntry?.modelButton
            let modelSelectors = (configuredModelButton?.split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) } ?? [])
                .filter { !$0.isEmpty }
            guard !modelSelectors.isEmpty else {
                injectionSucceeded = false
                emit(.modelInjectionFailed(
                    "No model selector is configured; injection was blocked before send."
                ))
                return false
            }
            // Audit 2026-09-06 (Claude): the model button's own label carries
            // the CURRENT model (e.g. "Sonnet 5 Max" = model Sonnet 5 + Effort
            // Max). When the target model is already active, opening the menu
            // is unnecessary AND the menu may not list the current model in
            // its current state (live evidence: the menu showed only gated
            // families while Sonnet 5 was already selected), which used to
            // fail the send with a false "Model not found".
            if let activeText = (try? await bridge.readText(selector: modelSelectors[0])),
               activeText.trimmingCharacters(in: .whitespacesAndNewlines)
                   .contains(config.selectedModel) {
                await bridge.wait(ms: 200)
            } else {
            var openedSelector: String?
            for selector in modelSelectors {
                guard (try? await bridge.exists(selector: selector)) == true else { continue }
                do {
                    try await bridge.click(selector: selector)
                    openedSelector = selector
                    break
                } catch {
                    continue
                }
            }

            if let openedSelector {
                try? await bridge.waitForSelector(selector: "div.model-item, [class*='model-item'], [role='option']", timeout: 5000)
                await bridge.wait(ms: 500)
                let modelText = config.selectedModel
                let itemSelector = catalogEntry?.modelItem ?? "[role='option'], [class*='option']"
                // Round 30b: menus can render late; re-open and re-match within
                // a small bounded budget instead of one-shot failing.
                var clicked = false
                for attempt in 1...SendSubmissionPolicy.maxMatchRetries {
                    if attempt > 1 {
                        try? await bridge.click(selector: openedSelector)
                        await bridge.wait(ms: SendSubmissionPolicy.matchRetryDelayMs)
                        try? await bridge.waitForSelector(selector: "div.model-item, [class*='model-item'], [role='option']", timeout: 5000)
                        await bridge.wait(ms: SendSubmissionPolicy.matchRetryDelayMs)
                    }
                    clicked = (try? await bridge.clickVisibleTextExact(selector: itemSelector, text: modelText)) == true
                    if clicked { break }
                }
                if clicked {
                    // Let the model menu close and the provider commit its state
                    // before touching the independent effort control.
                    await bridge.wait(ms: 800)
                } else {
                    // Toggle the same control once to avoid leaving a menu overlay
                    // in front of the composer. A visible dropdown without an exact
                    // confirmed option is still a hard failure: never send under a
                    // different model than the one shown in the composer.
                    try? await bridge.click(selector: openedSelector)
                    injectionSucceeded = false
                    emit(.modelInjectionFailed(
                        "Model '\(modelText)' was not found; injection was blocked before send."
                    ))
                }
            } else {
                injectionSucceeded = false
                emit(.modelInjectionFailed(
                    "The page model control is unavailable; model injection was blocked before send."
                ))
            }
            }
        }

        // Effort is optional: models without a live effort selector are not
        // injected. If a requested effort selector exists but cannot confirm the
        // choice, block before typing so recovery cannot duplicate a turn.
        let selectedModel = config.discoveredModels.first(where: { $0.name == config.selectedModel })
        let effortToInject: WebEffort? = {
            // Before any live model profile exists, preserve the legacy
            // persisted-effort path for vendors whose catalog exposes a
            // universal control. Once profiles exist, an undetected model has
            // no verified capability and must not inherit another model's
            // effort setting.
            guard !config.discoveredModels.isEmpty else { return config.effort }
            guard let selectedModel else { return nil }
            return selectedModel.availableEfforts.contains(config.effort) ? config.effort : nil
        }()
        if let candidates = effortToInject.flatMap({ effortCandidates(for: $0) }), !candidates.isEmpty,
           let catalogEntry {
            let selectors = (catalogEntry.effortDropdown?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } ?? [])
                .filter { !$0.isEmpty }
            var anySuccess = false
            var foundControl = false
            var lastError = ""
            for selector in selectors {
                do {
                    guard (try? await bridge.exists(selector: selector)) == true else { continue }
                    foundControl = true
                    try await bridge.click(selector: selector)
                    try? await bridge.waitForSelector(selector: "[class*='effort'], [class*='thinking'], [role='option'], [class*='option']", timeout: 5000)
                    await bridge.wait(ms: 500)
                    let itemSelector = catalogEntry.effortItem ?? "[role='option'], [class*='option']"
                    // Round 30b: match ANY known label variant, retrying with a
                    // re-opened menu within the bounded budget.
                    for attempt in 1...SendSubmissionPolicy.maxMatchRetries {
                        if attempt > 1 {
                            try? await bridge.click(selector: selector)
                            await bridge.wait(ms: SendSubmissionPolicy.matchRetryDelayMs)
                        }
                        var labelClicked = false
                        for candidate in candidates where !labelClicked {
                            labelClicked = (try? await bridge.clickVisibleTextExact(selector: itemSelector, text: candidate)) == true
                        }
                        if labelClicked {
                            // Keep effort injection isolated from the model menu.
                            await bridge.wait(ms: 800)
                            anySuccess = true
                            break
                        }
                    }
                    if anySuccess { break }
                    lastError = "effort option not found"
                } catch {
                    lastError = error.localizedDescription
                }
            }
            if foundControl && !anySuccess {
                injectionSucceeded = false
                emit(.effortInjectionFailed(
                    L.t(AppLocalizationKey.locWebEffortNote)
                        .replacingOccurrences(of: "{0}", with: lastError.isEmpty ? "effort option not found; effort injection was blocked before send" : lastError)
                ))
            }
        }

        // Parameters are optional vendor controls. Apply only the user's saved
        // overrides and only when discovery identified matching live controls;
        // absence never blocks a normal send.
        if let model = config.discoveredModels.first(where: { $0.name == config.selectedModel }) {
            await injectParameters(ModelCallParametersStore.parameters(for: config.selectedModel),
                                   profile: model.parameterProfile)
        }
        return injectionSucceeded
    }

    private func injectParameters(_ parameters: ModelCallParameters,
                                  profile: WebModelParameterProfile) async {
        guard parameters.isCustomized, !profile.availableKeys.isEmpty else { return }
        let fragment = ModelCallParametersStore.requestFragment(parameters)
        guard let data = try? JSONSerialization.data(withJSONObject: fragment),
              let json = String(data: data, encoding: .utf8) else { return }
        let script = """
        (function(){
          const values = \(json);
          const visible = el => {
            const s = getComputedStyle(el), r = el.getBoundingClientRect();
            return s.display !== 'none' && s.visibility !== 'hidden' && r.width > 0 && r.height > 0;
          };
          const nodes = Array.from(document.querySelectorAll('input, textarea, select, [role=spinbutton], [role=slider]')).filter(visible);
          const aliases = {
            temperature: /temperature|temp/i,
            max_tokens: /max.?tokens?|max.?output|token.?limit/i,
            top_p: /top.?p/i,
            system: /system.?prompt/i
          };
          let applied = 0;
          Object.keys(values).forEach(key => {
            if (!aliases[key]) return;
            const el = nodes.find(node => {
              const label = ((node.getAttribute('name') || '') + ' ' + (node.getAttribute('aria-label') || '') + ' ' + (node.id || '') + ' ' + (node.innerText || '')).toLowerCase();
              return aliases[key].test(label);
            });
            if (!el) return;
            const value = String(values[key]);
            if (el.tagName.toLowerCase() === 'textarea' || el.tagName.toLowerCase() === 'input') {
              const proto = el.tagName.toLowerCase() === 'textarea' ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
              const descriptor = Object.getOwnPropertyDescriptor(proto, 'value');
              if (descriptor && descriptor.set) descriptor.set.call(el, value); else el.value = value;
            } else {
              el.setAttribute('data-micoder-value', value);
            }
            el.dispatchEvent(new Event('input', {bubbles: true}));
            el.dispatchEvent(new Event('change', {bubbles: true}));
            applied += 1;
          });
          return applied;
        })();
        """
        _ = try? await bridge.evaluateJS(script)
    }

    /// Start a new chat session by clicking the "New Chat" button.
    /// Returns the new chat URL or nil if could not determine.
    func startNewSession() async throws -> String? {
        let catalogEntry = try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id)

        // Try exact interactive controls only. A fuzzy div click can select a
        // history row or page heading and silently keep the old remote chat.
        let beforeURL = try? await bridge.currentURL()
        let beforeID = try? await getCurrentChatID()
        let newChatTexts = catalogEntry?.newChatTexts ?? ["New Chat", "Новый чат", "New chat", "Начать", "新对话"]
        for text in newChatTexts {
            let clicked = (try? await bridge.clickVisibleTextExact(selector: "button, a, [role='button'], [role='menuitem']", text: text)) ?? false
            guard clicked else { continue }
            await bridge.wait(ms: 2000)
            let afterURL = try await bridge.currentURL()
            let afterID = try? await getCurrentChatID()
            guard afterURL != beforeURL || afterID != beforeID,
                  afterID?.isEmpty == false else { continue }
            return afterURL
        }
        // Fallback: try clicking catalog-specific newChatSelector (e.g. ".new-chat-btn")
        if let newChatSel = catalogEntry?.newChatSelector {
            let clicked = (try? await bridge.click(selector: newChatSel)) != nil
            if clicked {
                await bridge.wait(ms: 2000)
                let afterURL = try await bridge.currentURL()
                let afterID = try? await getCurrentChatID()
                if afterURL != beforeURL || afterID != beforeID {
                    return afterURL
                }
            }
        }
        // Final fallback: try clicking any element with "new-chat" in class
        if (try? await bridge.click(selector: "[class*='new-chat']")) != nil {
            await bridge.wait(ms: 2000)
            let afterURL = try await bridge.currentURL()
            if afterURL != beforeURL {
                return afterURL
            }
        }
        return nil
    }

    /// Extract the chat ID/slug from the current URL or the provider's active
    /// conversation DOM. Kimi can keep the shell at `/` while exposing the
    /// active UUID through data attributes/history links, so URL-only parsing
    /// incorrectly blocked every first send.
    func getCurrentChatID() async throws -> String? {
        let url = try await bridge.currentURL()
        // Kimi/Qwen: /chat/{id}; ChatGPT: /c/{id}.
        let patterns = ["/chat/", "/c/"]
        for pattern in patterns {
            if let range = url.range(of: pattern) {
                let after = url[range.upperBound...]
                let pathPart = after.split(whereSeparator: { $0 == "/" || $0 == "?" || $0 == "#" }).first.map(String.init) ?? String(after)
                if let chatID = WebRemoteChatIdentityLogic.firstValid([pathPart]) {
                    return chatID
                }
            }
        }

        let script = """
        (function(){
          const values = [];
          const selectors = [
            '[data-chat-id]', '[data-conversation-id]', '[data-conversationid]',
            '[data-testid*="conversation" i]', '[aria-current="page"]',
            'a[href*="/chat/"]', 'a[href*="/c/"]'
          ];
          selectors.forEach(selector => document.querySelectorAll(selector).forEach(el => {
            ['data-chat-id', 'data-conversation-id', 'data-conversationid', 'data-testid', 'href'].forEach(attr => {
              const value = el.getAttribute(attr);
              if (!value) return;
              if (attr === 'href') {
                const parts = value.split(/[\\/?#]/).filter(Boolean);
                if (parts.length) values.push(parts[parts.length - 1]);
              } else {
                values.push(value);
              }
            });
          }));
          return JSON.stringify(values);
        })();
        """
        let raw = try await bridge.evaluateJS(script)
        let candidates: [String]
        if let json = raw as? String,
           let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            candidates = decoded
        } else if let decoded = raw as? [String] {
            candidates = decoded
        } else {
            candidates = []
        }
        return WebRemoteChatIdentityLogic.firstValid(candidates)
    }

    /// Select a model in the web UI.
    func selectModel(_ modelName: String) async throws {
        let selector = try modelSelector()
        // Click model button
        try await bridge.click(selector: selector)
        // Wait for dropdown
        try await bridge.waitForSelector(selector: "div.model-item, [class*='model-item']", timeout: 5000)
        // Find and click matching model
        let clicked = try await bridge.clickVisibleTextExact(
            selector: "div.model-item, [class*='model-item'], [role='option'], [role='menuitem']",
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
        // Round 30b: try live menu labels first, legacy fallbacks after.
        let labels = effortCandidates(for: level) ?? [level.displayName]
        switch config.vendor {
        case .qwen:
            try await bridge.click(selector: ".qwen-thinking-selector .qwen-chat-v2-dropdown-menu-trigger, .qwen-thinking-selector")
            try? await bridge.waitForSelector(selector: ".qwen-chat-v2-dropdown-menu-item, .ant-select-item-option", timeout: 5000)
            var clicked = false
            for label in labels where !clicked {
                clicked = try await bridge.clickByText(
                    selector: ".qwen-chat-v2-dropdown-menu-item, .ant-select-item-option-content",
                    text: label
                )
            }
            if !clicked { throw WebChatError.effortNotFound(labels.first ?? "") }
        case .kimi:
            try await bridge.click(selector: "[class*='effort']")
            try await bridge.waitForSelector(selector: "[class*='effort-option'], [role='option']", timeout: 5000)
            var kimiClicked = false
            for candidate in labels where !kimiClicked {
                kimiClicked = try await bridge.clickByText(
                    selector: "[class*='effort-option'], [role='option']",
                    text: candidate
                )
            }
            if !kimiClicked { throw WebChatError.effortNotFound(labels.first ?? "") }
        default:
            break
        }
        await bridge.wait(ms: 500)
    }

    /// Resolve the model selector for the current vendor.
    private func modelSelector() throws -> String {
        if let custom = config.customModelSelector, !custom.isEmpty { return custom }
        if let catalog = try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id),
           let button = catalog.modelButton?.trimmingCharacters(in: .whitespacesAndNewlines),
           !button.isEmpty {
            return button
        }
        throw WebChatError.noModelSelector
    }

    /// Map a WebEffort to a vendor-specific label for matching in the dropdown.
    /// Round 30b: right after a verified SmartSend submission the page is still
    /// navigating to its remote chat URL; the model/effort DOM may be mid-reload
    /// and a single immediate injection pass races against it. Wait until the
    /// location has stopped changing before touching vendor menus.
    private func waitForPageURLStability(maxMs: Int = 6000) async {
        var last = (try? await bridge.currentURL()) ?? ""
        var stableReads = 0
        let start = Date()
        while Date().timeIntervalSince(start) * 1000 < Double(maxMs) {
            await bridge.wait(ms: 300)
            let now = (try? await bridge.currentURL()) ?? last
            if now == last {
                stableReads += 1
                if stableReads >= 2 { return }
            } else {
                last = now
                stableReads = 0
            }
        }
    }

    func effortCandidates(for effort: WebEffort) -> [String]? {
        switch config.vendor {
        case .kimi:
            switch effort {
            case .low: return ["快"]
            case .medium: return ["标准"]
            case .high: return ["深度思考"]
            }
        case .qwen:
            // Round 30b: live menu renders English items ("Auto"/"Think"/"Fast");
            // legacy Chinese labels kept as fallbacks for older locales.
            switch effort {
            case .low: return ["Fast", "快"]
            case .medium: return ["Auto", "标准"]
            case .high: return ["Think", "深度思考"]
            }
        case .chatgpt:
            switch effort {
            case .low: return ["low"]
            case .medium: return ["medium"]
            case .high: return ["high"]
            }
        case .claude:
            // Live 2026 Claude UI exposes an Effort submenu inside the model
            // menu ("Effort: Max"); the tiers map to low/medium/high.
            switch effort {
            case .low: return ["Low", "Низкий"]
            case .medium: return ["Medium", "Средний"]
            case .high: return ["Max", "High", "Высокий", "Максимум"]
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
    case modelInjectionFailed(String)
    case effortInjectionFailed(String)
    case selectorNotFound(String)
    case responseTimeout
    case noModelSelector
    case noSession
    case captchaResolutionTimedOut
    case captchaResolutionAborted
    case sessionLoggedOut
    case remoteChatBindingFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let m): return "Model '\(m)' not found in web UI"
        case .modeNotFound(let m): return "Mode '\(m)' not found in web UI"
        case .effortNotFound(let e): return "Effort level '\(e)' not found"
        case .modelInjectionFailed(let message): return message
        case .effortInjectionFailed(let message): return message
        case .selectorNotFound(let selector): return "Browser element was not found: \(selector)"
        case .responseTimeout: return "The browser did not confirm a new response after submit. The message may not have been sent; check the web page/session and retry."
        case .noModelSelector: return "No model selector configured for this vendor"
        case .noSession: return "No active web session"
        case .captchaResolutionTimedOut: return "Captcha was not solved before the browser wait timed out. Retry after completing it."
        case .captchaResolutionAborted: return "Captcha resolution was aborted because the browser session was logged out."
        case .sessionLoggedOut: return "The browser session was logged out."
        case .remoteChatBindingFailed(let message): return message
        }
    }
}
