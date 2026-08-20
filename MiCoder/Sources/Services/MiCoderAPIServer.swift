import Foundation
import Network
import os.log

private let apiLog = OSLog(subsystem: "com.micoder.app", category: "api")

/// Local HTTP API server for MiCoder testing and integration.
/// Provides endpoints to list providers/models/chats and send messages.
final class MiCoderAPIServer {
    static let shared = MiCoderAPIServer()
    static let fixedPort: UInt16 = 8766
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "micoder.api.server")
    private(set) var port: Int = 0
    
    static func appendLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let line = "[\(formatter.string(from: Date()))] \(message)\n"
        if let data = line.data(using: .utf8) {
            let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".micoder/logs/api-server.log")
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            } else {
                try? data.write(to: url)
            }
        }
    }
    
    func start() {
        Self.appendLog("MiCoderAPIServer.start() called")
        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            let port = NWEndpoint.Port(rawValue: Self.fixedPort)!
            listener = try NWListener(using: params, on: port)
            listener?.stateUpdateHandler = { [weak self] state in
                if case .ready = state {
                    self?.port = Int(Self.fixedPort)
                    let msg = "MiCoder API server ready on http://127.0.0.1:\(Self.fixedPort)"
                    os_log("%{public}@", log: apiLog, type: .info, msg)
                    Self.appendLog(msg)
                }
            }
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            listener?.start(queue: queue)
        } catch {
            print("Failed to start API server: \(error)")
        }
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveHTTPRequest(connection)
    }
    
    private func receiveHTTPRequest(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let data = data, !data.isEmpty else {
                connection.cancel()
                return
            }
            
            let request = String(data: data, encoding: .utf8) ?? ""
            let lines = request.components(separatedBy: "\r\n")
            let requestLine = lines.first ?? ""
            let parts = requestLine.components(separatedBy: " ")
            let method = parts.count > 0 ? parts[0] : "GET"
            let path = parts.count > 1 ? parts[1] : "/"
            
            var body = ""
            if let bodyStart = request.range(of: "\r\n\r\n") {
                body = String(request[bodyStart.upperBound...])
            }
            
            let response = self?.routeRequest(method: method, path: path, body: body) ?? self?.notFound() ?? ""
            connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
                connection.cancel()
            })
            
            if !isComplete {
                self?.receiveHTTPRequest(connection)
            }
        }
    }
    
    private func routeRequest(method: String, path: String, body: String) -> String {
        switch (method, path) {
        case ("GET", "/api/providers"):
            return jsonResponse(providersInfo())
        case ("GET", "/api/chats"):
            return jsonResponse(chatsInfo())
        case ("GET", "/api/messages"):
            return jsonResponse(messagesInfo())
        case ("POST", "/api/send"):
            return handleSend(body: body)
        case ("POST", "/api/select"):
            return handleSelect(body: body)
        case ("POST", "/api/refresh-models"):
            return handleRefreshModels(body: body)
        case ("POST", "/api/evaluate"):
            return handleEvaluate(body: body)
        case ("GET", "/api/webviews"):
            return handleWebviews()
        case ("POST", "/api/save-session"):
            return handleSaveSession(body: body)
        case ("GET", "/api/inspect"):
            return handleInspect()
        case ("POST", "/api/discover-models"):
            return handleDiscoverModels()
        case ("POST", "/api/add-account"):
            return handleAddAccount(body: body)
        default:
            return notFound()
        }
    }
    
    private func providersInfo() -> [String: Any] {
        guard __miCoderAppState != nil else { return ["error": "app not ready"] }
        var providers: [[String: Any]] = []
        
        // MiCoder Auto Free
        let autoFreeStore = MiCoderAutoFreeStore.shared
        providers.append([
            "id": MiCoderAutoFreeProvider.builtInID,
            "name": "MiCoder Auto Free",
            "isBuiltIn": true,
            "isEnabled": true,
            "isConnected": autoFreeStore.provider.isReady,
            "models": autoFreeStore.provider.models.map { ["id": $0.id, "name": $0.name, "isFree": $0.isFree] },
            "selectedModel": autoFreeStore.provider.selectedModel
        ])
        
        // Web providers
        let webConfigs = WebProviderStore.load()
        for config in webConfigs {
            providers.append([
                "id": "web:\(config.id)",
                "name": config.displayName,
                "vendor": config.vendor.id,
                "isConnected": WebProviderConnectivity.isConnected(config, homeDirectory: FileManager.default.homeDirectoryForCurrentUser),
                "models": config.allModels,
                "selectedModel": config.selectedModel
            ])
        }
        
        return ["providers": providers]
    }
    
    private func chatsInfo() -> [String: Any] {
        guard let appState = __miCoderAppState else { return ["error": "app not ready"] }
        let sessions = appState.sessions.map { session in
            [
                "id": session.id,
                "title": session.title,
                "directory": session.directory,
                "updatedAt": session.updatedAt.timeIntervalSince1970
            ]
        }
        return [
            "sessions": sessions,
            "selectedSessionId": appState.selectedSession?.id ?? "",
            "selectedProviderId": appState.selectedProviderID,
            "selectedModel": SendAPIResponseLogic.modelID(
                selectedModel: appState.selectedModel,
                effectiveModel: appState.effectiveSelectedModel()
            )
        ]
    }
    
    private func handleSend(body: String) -> String {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? String else {
            return jsonResponse(["error": "message is required"])
        }
        
        guard let appState = __miCoderAppState else {
            return jsonResponse(["error": "app not ready"])
        }
        
        let chatId = json["chatId"] as? String
        let providerId = json["providerId"] as? String
        let modelId = json["modelId"] as? String
        
        // Select provider/model if specified
        if let providerId = providerId {
            appState.selectProvider(providerId, persistPreference: false)
        }
        if let modelId = modelId, !modelId.isEmpty {
            // For MiCoder Auto Free, also update the store's selected model
            if providerId == MiCoderAutoFreeProvider.builtInID {
                DispatchQueue.main.async { MiCoderAutoFreeStore.shared.selectModel(modelId) }
            }
            appState.selectModel(modelId, persistPreference: false)
        }
        
        // Debug log
        Self.appendLog("🔍 After select: provider=\(appState.selectedProviderID), model=\(appState.selectedModel), effective=\(appState.effectiveSelectedModel()), session=\(appState.selectedSession?.id ?? "nil")")
        
        // Create or select session
        var targetSession: ChatSession?
        if let chatId = chatId {
            targetSession = appState.sessions.first(where: { $0.id == chatId })
            Self.appendLog("🔍 Existing session lookup: chatId=\(chatId), found=\(targetSession != nil)")
        }
        
        if targetSession == nil {
            // Create new temporary session
            let tempDir = FileManager.default.temporaryDirectory.path
            let newSession = ChatSession(
                id: UUID().uuidString,
                title: "API Chat",
                directory: tempDir,
                branch: nil
            )
            Self.appendLog("🔍 Creating new session: id=\(newSession.id)")
            appState.upsertSession(newSession)
            targetSession = appState.sessions.first(where: { $0.id == newSession.id }) ?? newSession
            Self.appendLog("🔍 After upsert: sessions=\(appState.sessions.count), targetID=\(targetSession?.id ?? "nil")")
        }
        
        if let session = targetSession {
            appState.selectedSession = session
            Self.appendLog("🔍 Selected session: \(session.id)")
        } else {
            Self.appendLog("❌ No session available")
        }
        
        // Trigger send via notification
        let responseModelID = SendAPIResponseLogic.modelID(
            selectedModel: appState.selectedModel,
            effectiveModel: appState.effectiveSelectedModel()
        )
        let apiChatId = appState.selectedSession?.id ?? ""
        let logMsg = "📤 API Send: message='\(message)', chatId=\(apiChatId), provider=\(appState.selectedProviderID), model=\(responseModelID)"
        os_log("%{public}@", log: apiLog, type: .info, logMsg)
        Self.appendLog(logMsg)
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("apiSendRequested"),
                object: nil,
                userInfo: ["message": message, "chatId": apiChatId]
            )
        }
        
        return jsonResponse([
            "status": "sent",
            "message": message,
            "chatId": appState.selectedSession?.id ?? "",
            "providerId": appState.selectedProviderID,
            "modelId": responseModelID
        ])
    }
    
    private func messagesInfo() -> [String: Any] {
        guard let appState = __miCoderAppState else { return ["error": "app not ready"] }
        guard let sessionID = appState.selectedSession?.id else { return ["messages": []] }
        
        let messages = DatabaseBridge.shared.loadMessages(sessionId: sessionID)
        let result = messages.map { msg in
            [
                "id": msg.id,
                "role": msg.role == .user ? "user" : "assistant",
                "content": msg.content,
                "isFinished": msg.isFinished,
                "isStreaming": msg.isStreaming
            ]
        }
        return ["messages": result, "sessionId": sessionID]
    }
    
    private func handleSelect(body: String) -> String {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let appState = __miCoderAppState else {
            return jsonResponse(["error": "invalid body or app not ready"])
        }
        
        if let providerId = json["providerId"] as? String {
            appState.selectProvider(providerId, persistPreference: false)
        }
        if let modelId = json["modelId"] as? String {
            appState.selectModel(modelId, persistPreference: false)
        }
        if let chatId = json["chatId"] as? String {
            if let session = appState.sessions.first(where: { $0.id == chatId }) {
                appState.selectedSession = session
            }
        }
        
        return jsonResponse(["status": "selected"])
    }
    
    private func jsonResponse(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
              let json = String(data: data, encoding: .utf8) else {
            return "HTTP/1.1 500 Internal Server Error\r\nContent-Type: application/json\r\n\r\n{\"error\":\"serialization failed\"}"
        }
        return "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(json.utf8.count)\r\n\r\n\(json)"
    }
    
    private func notFound() -> String {
        return "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\n\r\n{\"error\":\"not found\"}"
    }

    private func handleRefreshModels(body: String) -> String {
        guard let appState = __miCoderAppState else {
            return jsonResponse(["error": "app not ready"])
        }
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let providerId = json["providerId"] as? String else {
            return jsonResponse(["error": "providerId required"])
        }
        let configs = WebProviderStore.load()
        guard let config = configs.first(where: { "web:\($0.id)" == providerId }) else {
            return jsonResponse(["error": "provider not found"])
        }
        let semaphore = DispatchSemaphore(value: 0)
        var result: String = "timeout"
        Task { @MainActor in
            result = await appState.refreshWebModels(for: config)
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 60)
        let updated = WebProviderStore.load()
        let updatedConfig = updated.first(where: { $0.id == config.id })
        return jsonResponse(["message": result, "models": updatedConfig?.allModels ?? []])
    }

    private func handleEvaluate(body: String) -> String {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let script = json["script"] as? String else {
            return jsonResponse(["error": "script is required"])
        }
        guard let appState = __miCoderAppState else {
            return jsonResponse(["error": "app not ready"])
        }
        let semaphore = DispatchSemaphore(value: 0)
        var result: Any?
        Task { @MainActor in
            result = await appState.debugEvaluateJS(script)
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 15)
        if let result = result {
            if let dict = result as? [String: Any] {
                return jsonResponse(dict)
            } else if let arr = result as? [Any] {
                return jsonResponse(["result": arr])
            } else if let str = result as? String {
                return jsonResponse(["result": str])
            } else {
                return jsonResponse(["result": "\(result)"])
            }
        }
        return jsonResponse(["result": NSNull()])
    }

    private func handleWebviews() -> String {
        guard let appState = __miCoderAppState else {
            return jsonResponse(["error": "app not ready"])
        }
        let semaphore = DispatchSemaphore(value: 0)
        var result: [String: String] = [:]
        Task { @MainActor in
            result = appState.debugWebviewURLs()
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 10)
        return jsonResponse(result)
    }

    private func handleSaveSession(body: String) -> String {
        guard let appState = __miCoderAppState else {
            return jsonResponse(["error": "app not ready"])
        }
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let providerId = json["providerId"] as? String else {
            return jsonResponse(["error": "providerId required"])
        }
        let configs = WebProviderStore.load()
        guard let config = configs.first(where: { "web:\($0.id)" == providerId }) else {
            return jsonResponse(["error": "provider not found"])
        }
        let semaphore = DispatchSemaphore(value: 0)
        var cookies: [BrowserCookie] = []
        var errorRef: Error? = nil
        Task { @MainActor in
            do {
                let webView = appState.webView(for: config, projectID: "global", chatID: "provider-default")
                let catalogEntry = try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id)
                let selectors = WebVendorSelectors(
                    input: catalogEntry?.input ?? "textarea, div[contenteditable='true']",
                    sendButton: catalogEntry?.sendButton ?? "button[type='submit'], button[aria-label*='send']",
                    responseContainer: catalogEntry?.responseContainer ?? "div[class*='markdown']",
                    stopButton: catalogEntry?.stopButton ?? "button[aria-label*='stop']"
                )
                let bridge = WKWebViewBrowserBridge(webView: webView, selectors: selectors)
                do {
                    cookies = try await bridge.cookies()
                } catch {
                    errorRef = error
                }
                semaphore.signal()
            } catch {
                errorRef = error
                semaphore.signal()
            }
        }
        _ = semaphore.wait(timeout: .now() + 30)
        if let error = errorRef {
            return jsonResponse(["error": "failed to get cookies: \(error.localizedDescription)"])
        }
        guard !cookies.isEmpty else {
            return jsonResponse(["error": "no cookies found in browser"])
        }
        let sessionID = config.activeSessionID ?? WebSessionManager.defaultSessionID
        let store = WebSessionStore(
            cookies: cookies,
            localStorage: [:],
            savedAt: Date()
        )
        do {
            try WebSessionManager.persist(
                store,
                providerId: config.id,
                homeDirectory: FileManager.default.homeDirectoryForCurrentUser,
                sessionID: sessionID
            )
            return jsonResponse(["status": "saved", "cookieCount": cookies.count])
        } catch {
            return jsonResponse(["error": "failed to save session: \(error.localizedDescription)"])
        }
    }

    private func handleInspect() -> String {
        guard let appState = __miCoderAppState else {
            return jsonResponse(["error": "app not ready"])
        }
        let providerId = "web:56FA3447-A2EA-4FD1-84E3-B72767C8A376" // Kimi for now
        let configs = WebProviderStore.load()
        guard let config = configs.first(where: { "web:\($0.id)" == providerId }) else {
            return jsonResponse(["error": "provider not found"])
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var finalResult: [String: Any] = ["error": "timeout"]
        Task { @MainActor in
            do {
                let webView = appState.webView(for: config, projectID: "global", chatID: "provider-default")
                let catalogEntry = try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id)
                let selectors = WebVendorSelectors(
                    input: catalogEntry?.input ?? "textarea, div[contenteditable='true']",
                    sendButton: catalogEntry?.sendButton ?? "button[type='submit'], button[aria-label*='send']",
                    responseContainer: catalogEntry?.responseContainer ?? "div[class*='markdown']",
                    stopButton: catalogEntry?.stopButton ?? "button[aria-label*='stop']"
                )
                let bridge = WKWebViewBrowserBridge(webView: webView, selectors: selectors)
                
                // Restore cookies and navigate
                let sessionID = config.activeSessionID ?? WebSessionManager.defaultSessionID
                if let store = WebSessionManager.restore(providerId: config.id,
                                                         homeDirectory: FileManager.default.homeDirectoryForCurrentUser,
                                                         sessionID: sessionID),
                   !store.cookies.isEmpty,
                   !WebSessionManager.isExpired(store) {
                    let payload = WebSessionRestorationLogic.payload(from: store)
                    try await bridge.setCookies(payload.cookies)
                    try await bridge.navigate(to: config.chatURL)
                    if !payload.localStorage.isEmpty {
                        try await bridge.setLocalStorage(payload.localStorage)
                        try await bridge.navigate(to: config.chatURL)
                    }
                }
                
                // Wait for input to be ready
                for _ in 0..<30 {
                    if try await bridge.exists(selector: selectors.input) {
                        break
                    }
                    await bridge.wait(ms: 500)
                }
                
                // Now run the inspection JS
                let js = """
                (function(){
                    var url = window.location.href;
                    var title = document.title;
                    var modelDropdown = document.querySelector('.current-model');
                    var modelDropdownText = modelDropdown ? modelDropdown.innerText.trim() : '';
                    var popover = document.querySelector('.models-popover, .n-popover__content');
                    var popoverOpen = !!popover;
                    var modelItems = Array.from(document.querySelectorAll('.model-item')).map(function(el){
                        var name = el.querySelector('.model-name .name');
                        var desc = el.querySelector('.desc');
                        var checked = el.classList.contains('checked');
                        return {name: name ? name.textContent.trim() : el.innerText.trim().substring(0, 50), desc: desc ? desc.textContent.trim() : '', checked: checked};
                    });
                    var effortValue = document.querySelector('.effort-value');
                    var effortTitle = document.querySelector('.effort-title');
                    var input = document.querySelector('.chat-input-editor, textarea, div[contenteditable="true"]');
                    var sendBtn = document.querySelector('.send-button-container, .chat-editor-action button[class*="send"], button[type="submit"]');
                    var newChatBtn = document.querySelector('.new-chat-btn, [class*="new-chat"]');
                    return JSON.stringify({url: url, title: title, modelDropdownText: modelDropdownText, popoverOpen: popoverOpen, modelItems: modelItems, effort: {value: effortValue ? effortValue.textContent.trim() : '', title: effortTitle ? effortTitle.textContent.trim() : ''}, input: input ? {tag: input.tagName, cls: input.className.substring(0, 80)} : null, sendButton: sendBtn ? {tag: sendBtn.tagName, cls: sendBtn.className.substring(0, 80)} : null, newChatButton: newChatBtn ? {tag: newChatBtn.tagName, cls: newChatBtn.className.substring(0, 80), text: newChatBtn.innerText.trim().substring(0, 50)} : null});
                })();
                """
                let inspectResult = await appState.debugEvaluateJS(js)
                if let jsonStr = inspectResult as? String,
                   let data = jsonStr.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    finalResult = dict
                } else {
                    finalResult = ["error": "failed to inspect"]
                }
            } catch {
                finalResult = ["error": "failed to inspect: \(error.localizedDescription)"]
            }
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 30)
        return jsonResponse(finalResult)
    }

    private func handleDiscoverModels() -> String {
        guard let appState = __miCoderAppState else {
            return jsonResponse(["error": "app not ready"])
        }
        // Click model dropdown
        let clickScript = "document.querySelector('.current-model')?.click(); 'clicked'"
        let semaphore1 = DispatchSemaphore(value: 0)
        Task { @MainActor in
            _ = await appState.debugEvaluateJS(clickScript)
            semaphore1.signal()
        }
        _ = semaphore1.wait(timeout: .now() + 5)
        // Wait for popover
        Thread.sleep(forTimeInterval: 2)
        // Read model items
        let readScript = """
        (function(){
            var items = document.querySelectorAll('.model-item');
            var r = [];
            for (var i = 0; i < items.length; i++) {
                var el = items[i];
                var nameEl = el.querySelector('.model-name .name');
                var name = nameEl ? (nameEl.textContent || '').trim() : '';
                var desc = el.querySelector('.desc');
                var descText = desc ? desc.textContent.trim() : '';
                var checked = el.classList.contains('checked');
                if (name) r.push({name: name, desc: descText, checked: checked});
            }
            // Effort
            var effortEl = document.querySelector('.effort-value');
            var effort = effortEl ? effortEl.textContent.trim() : '';
            return JSON.stringify({models: r, effort: effort});
        })();
        """
        let semaphore2 = DispatchSemaphore(value: 0)
        var readResult: Any?
        Task { @MainActor in
            readResult = await appState.debugEvaluateJS(readScript)
            semaphore2.signal()
        }
        _ = semaphore2.wait(timeout: .now() + 5)
        if let jsonStr = readResult as? String,
           let data = jsonStr.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Save discovered models to config
            if let models = dict["models"] as? [[String: Any]] {
                let modelNames = models.compactMap { $0["name"] as? String }
                var configs = WebProviderStore.load()
                if let idx = configs.firstIndex(where: { $0.vendor.id == "kimi" }) {
                    var cfg = configs[idx]
                    cfg.discoveredModels = modelNames.map { WebProviderModel(name: $0) }
                    configs[idx] = cfg
                    WebProviderStore.save(configs)
                }
            }
            return jsonResponse(dict)
        }
        return jsonResponse(["error": "failed to read models"])
    }

    private func handleAddAccount(body: String) -> String {
        guard let appState = __miCoderAppState else {
            return jsonResponse(["error": "app not ready"])
        }
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let vendorStr = json["vendor"] as? String,
              let vendor = WebChatVendor(rawValue: vendorStr) else {
            return jsonResponse(["error": "vendor required (kimi, qwen, chatgpt)"])
        }
        var configs = WebProviderStore.load()
        // Find existing config for this vendor to clone settings from
        guard let existing = configs.first(where: { $0.vendor.id == vendorStr }) else {
            return jsonResponse(["error": "no existing config for vendor \(vendorStr)"])
        }
        // Create a new config with a different ID
        let newConfig = WebProviderConfig(
            id: UUID().uuidString,
            vendor: vendor,
            displayName: "\(existing.displayName) (Account \(configs.filter { $0.vendor.id == vendorStr }.count + 1))",
            transport: existing.transport,
            chatURL: existing.chatURL,
            systemPrompt: existing.systemPrompt,
            effort: existing.effort,
            toolCallDelayMs: existing.toolCallDelayMs,
            maxToolIterations: existing.maxToolIterations,
            acknowledgedToS: existing.acknowledgedToS
        )
        configs.append(newConfig)
        WebProviderStore.save(configs)
        return jsonResponse(["status": "added", "id": newConfig.id, "name": newConfig.displayName])
    }
}
