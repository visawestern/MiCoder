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
        default:
            return notFound()
        }
    }
    
    private func providersInfo() -> [String: Any] {
        guard let appState = __miCoderAppState else { return ["error": "app not ready"] }
        var providers: [[String: Any]] = []
        
        // MiMo Auto
        let mimoStore = MiMoAutoProviderStore.shared
        providers.append([
            "id": MiMoAutoProvider.builtInID,
            "name": "MiMo Auto",
            "isBuiltIn": true,
            "isEnabled": true,
            "isConnected": mimoStore.provider.isKeyValid || mimoStore.provider.isFreeTier,
            "models": mimoStore.provider.models.map { ["id": $0.id, "name": $0.name, "isFree": $0.isFree] },
            "selectedModel": mimoStore.provider.selectedModel
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
            "selectedModel": appState.selectedModel
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
            // For MiMo-Auto, also update the store's selected model
            if providerId == MiMoAutoProvider.builtInID {
                DispatchQueue.main.async { MiMoAutoProviderStore.shared.selectModel(modelId) }
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
        let logMsg = "📤 API Send: message='\(message)', chatId=\(appState.selectedSession?.id ?? "nil"), provider=\(appState.selectedProviderID), model=\(appState.selectedModel)"
        os_log("%{public}@", log: apiLog, type: .info, logMsg)
        Self.appendLog(logMsg)
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("apiSendRequested"),
                object: nil,
                userInfo: ["message": message]
            )
        }
        
        return jsonResponse([
            "status": "sent",
            "message": message,
            "chatId": appState.selectedSession?.id ?? "",
            "providerId": appState.selectedProviderID,
            "modelId": appState.selectedModel
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
}
