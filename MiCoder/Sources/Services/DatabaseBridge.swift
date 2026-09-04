import Foundation
import Combine

/// Bridge-слой для интеграции DatabaseManager с существующим AppState
/// Автоматическая синхронизация между памятью и БД
class DatabaseBridge: ObservableObject {
    static let shared = DatabaseBridge()
    
    private let db = DatabaseManager.shared
    private let keychain = KeychainManager.shared
    
    private var cancellables = Set<AnyCancellable>()

    /// Session/message routing is keyed by session id. This prevents one
    /// selected workspace from changing the storage destination of another
    /// session while requests are in flight.
    private let activeProjectLock = NSLock()
    private var sessionProjectPaths: [String: String] = [:]

    private func projectPath(forSessionID sessionID: String) -> String? {
        activeProjectLock.lock()
        defer { activeProjectLock.unlock() }
        return sessionProjectPaths[sessionID]
    }

    private func rememberProject(_ path: String, forSessionID sessionID: String) {
        activeProjectLock.lock()
        sessionProjectPaths[sessionID] = path
        activeProjectLock.unlock()
    }

    private func resolveProjectDatabase(forSessionID sessionID: String) -> ProjectDatabaseManager? {
        guard let path = projectPath(forSessionID: sessionID) else { return nil }
        return resolveProjectDatabase(for: path)
    }

    /// Resolves `candidatePath` to its per-project database, or `nil` if the
    /// path doesn't point to a real, existing project directory.
    private func resolveProjectDatabase(for candidatePath: String) -> ProjectDatabaseManager? {
        guard !candidatePath.isEmpty else { return nil }
        return try? ProjectDatabaseManager.manager(forProjectPath: candidatePath)
    }

    // MARK: - Project Management
    
    /// Загрузить все проекты из БД
    func loadProjects() -> [Workspace] {
        do {
            let records = try db.getAllProjects()
            return records.map { record in
                Workspace(
                    id: record.id,
                    name: record.name,
                    path: record.path,
                    branch: record.gitBranch,
                    tasks: [] // Lazy load: sessions → tasks conversion happens in AppState
                )
            }
        } catch {
            print("❌ Failed to load projects: \(error)")
            return []
        }
    }
    
    /// Создать или обновить проект в БД
    func upsertProject(id: String, name: String, path: String, gitRemote: String? = nil, gitBranch: String? = nil) {
        do {
            // Проверяем существование
            let existing = try? db.getAllProjects().first(where: { $0.id == id })
            
            if let existing {
                // Update mutable fields on existing records (name, branch, remote)
                // instead of silently ignoring changes.
                try db.updateProject(
                    id: id,
                    name: name,
                    gitRemote: gitRemote ?? existing.gitRemote,
                    gitBranch: gitBranch ?? existing.gitBranch
                )
                try db.updateProjectLastOpened(id: id)
            } else {
                try db.insertProject(
                    id: id,
                    name: name,
                    path: path,
                    gitRemote: gitRemote,
                    gitBranch: gitBranch
                )
            }
        } catch {
            print("❌ Failed to upsert project: \(error)")
        }
    }
    
    /// Пометить проект как недавно открытый
    func markProjectAsOpened(id: String) {
        do {
            try db.updateProjectLastOpened(id: id)
        } catch {
            print("❌ Failed to mark project as opened: \(error)")
        }
    }
    
    /// Toggle pin статус проекта
    func toggleProjectPin(id: String) {
        do {
            try db.toggleProjectPin(id: id)
        } catch {
            print("❌ Failed to toggle pin: \(error)")
        }
    }
    
    // MARK: - Session Management
    
    /// Загрузить сессии проекта. Резолвит `projectId` в его собственную
    /// per-project БД (см. `ProjectDatabaseManager`). Проект обязан быть
    /// существующей директорией; невалидные идентификаторы не записываются.
    func loadSessions(projectId: String) -> [ChatSession] {
        if let projectDB = resolveProjectDatabase(for: projectId) {
            do {
                let records = try projectDB.getAllSessions(includeArchived: false)
                return records.map { record in
                    rememberProject(ChatSession.normalizedPath(projectId), forSessionID: record.id)
                    return ChatSession(
                        id: record.id,
                        title: record.title,
                        createdAt: record.createdAt,
                        updatedAt: record.updatedAt,
                        directory: record.directory,
                        branch: record.branch,
                        gitSummary: nil,
                        sessionGoal: record.sessionGoal
                    )
                }
            } catch {
                print("❌ Failed to load sessions from project database: \(error)")
                return []
            }
        }
        return []
    }
    
    /// Создать новую сессию (upsert — обновляет если существует). Пишет в
    /// per-project БД, резолвленную по `projectId`. Сессия без существующего
    /// project path отклоняется, чтобы история не попадала в другой store.
    func createSession(
        id: String,
        projectId: String,
        title: String,
        directory: String,
        branch: String? = nil,
        agentMode: String = "build",
        modelId: String? = nil,
        providerId: String? = nil
    ) {
        // A project may legitimately live under the OS temporary directory
        // (tests, scratch workspaces, and disposable clones). Use the global
        // database only when the directory is temporary AND projectId is not a
        // valid project root; a real project root always owns its per-project DB.
        let tempDir = FileManager.default.temporaryDirectory.path
        let isEphemeralSession = directory.hasPrefix(tempDir)
            && resolveProjectDatabase(for: projectId) == nil
        if isEphemeralSession {
            do {
                try db.insertSession(
                    id: id,
                    projectId: directory,
                    title: title,
                    directory: directory,
                    branch: branch,
                    agentMode: agentMode,
                    modelId: modelId,
                    providerId: providerId
                )
            } catch {
                print("❌ Failed to create temporary session: \(error)")
            }
            return
        }
        
        guard let projectDB = resolveProjectDatabase(for: projectId) else {
            print("❌ Cannot create session without a valid project directory: \(projectId)")
            return
        }
        rememberProject(ChatSession.normalizedPath(projectId), forSessionID: id)
        do {
            try projectDB.insertSession(
                id: id,
                title: title,
                directory: directory,
                branch: branch,
                agentMode: agentMode,
                modelId: modelId,
                providerId: providerId
            )
        } catch {
            print("❌ Failed to create session in project database: \(error)")
        }
    }
    
    /// Persist a session goal in the same project-scoped store used for reload.
    /// Legacy/temporary sessions retain the global DatabaseManager fallback.
    func setSessionGoal(sessionId id: String, goal: String?) {
        if let projectDB = resolveProjectDatabase(forSessionID: id) {
            do {
                try projectDB.setSessionGoal(id: id, goal: goal)
            } catch {
                print("❌ Failed to persist project session goal: \(error)")
            }
            return
        }
        do {
            try db.setSessionGoal(sessionId: id, goal: goal)
        } catch {
            print("❌ Failed to persist legacy session goal: \(error)")
        }
    }

    /// Архивировать сессию в базе проекта, которому она принадлежит.
    func archiveSession(id: String) {
        guard let projectDB = resolveProjectDatabase(forSessionID: id) else {
            print("❌ Cannot archive session without a registered project: \(id)")
            return
        }
        do {
            try projectDB.archiveSession(id: id)
        } catch {
            print("❌ Failed to archive session in project database: \(error)")
        }
    }
    
    // MARK: - Message Persistence

    /// Both `DatabaseManager` and `ProjectDatabaseManager` expose an
    /// `insertMessagePart` with the same shape; this closure lets
    /// `saveMessagePart` write to whichever one is active without
    /// duplicating the per-part-type switch for each backend.
    private typealias MessagePartInserter = (
        _ id: String,
        _ messageId: String,
        _ type: String,
        _ content: String?,
        _ toolName: String?,
        _ toolArgs: String?,
        _ toolResult: String?,
        _ toolCallId: String?,
        _ sequenceOrder: Int
    ) throws -> Void

    /// Сохранить сообщение в базе проекта, которому принадлежит сессия.
    func saveMessage(_ message: Message, sessionId: String) {
        MiCoderAPIServer.appendLog("💾 saveMessage: id=\(message.id), session=\(sessionId), temp=\(isTemporarySession(sessionId))")
        // For temporary sessions, use global database
        if isTemporarySession(sessionId) {
            MiCoderAPIServer.appendLog("💾 saveMessage: using global db for temp session")
            do {
                try db.insertMessage(
                    id: message.id,
                    sessionId: sessionId,
                    role: roleToString(message.role),
                    content: message.content,
                    reasoning: message.reasoning.isEmpty ? nil : message.reasoning,
                    usage: message.usage
                )
                // Persist every part (text, reasoning, tool_call, steps, images)
                // exactly like project sessions, so temp sessions reload with
                // their tool calls intact instead of losing them.
                for (index, part) in message.parts.enumerated() {
                    try saveMessagePart(part, messageId: message.id, sequenceOrder: index, insert: db.insertMessagePart)
                }
                MiCoderAPIServer.appendLog("💾 saveMessage: insertMessage + \(message.parts.count) parts succeeded")
            } catch {
                MiCoderAPIServer.appendLog("❌ Failed to save temporary message: \(error)")
            }
            return
        }
        
        guard let projectDB = resolveProjectDatabase(forSessionID: sessionId) else {
            print("❌ Cannot save message without a registered project: \(sessionId)")
            return
        }
        do {
            try projectDB.insertMessage(
                id: message.id,
                sessionId: sessionId,
                role: roleToString(message.role),
                content: message.content,
                reasoning: message.reasoning.isEmpty ? nil : message.reasoning,
                usage: message.usage
            )
            for (index, part) in message.parts.enumerated() {
                try saveMessagePart(part, messageId: message.id, sequenceOrder: index, insert: projectDB.insertMessagePart)
            }
        } catch {
            print("❌ Failed to save message in project database: \(error)")
        }
    }
    
    private func isTemporarySession(_ sessionId: String) -> Bool {
        guard let path = projectPath(forSessionID: sessionId) else {
            // Sessions created without a valid project registration use the
            // legacy/global database (for example disposable send failures).
            return true
        }
        // A real project can live under /tmp. The registered project database,
        // not the filesystem prefix, is the source of truth for routing.
        return resolveProjectDatabase(for: path) == nil
    }
    
    /// Сохранить часть сообщения через переданный project database inserter.
    private func saveMessagePart(
        _ part: MessagePartContent,
        messageId: String,
        sequenceOrder: Int,
        insert: MessagePartInserter
    ) throws {
        let partId = UUID().uuidString
        
        switch part {
        case .text(let text):
            try insert(partId, messageId, "text", text, nil, nil, nil, nil, sequenceOrder)
            
        case .reasoning(let text):
            try insert(partId, messageId, "reasoning", text, nil, nil, nil, nil, sequenceOrder)
            
        case .toolCall(let name, let args, let result, let callId):
            try insert(partId, messageId, "tool_call", nil, name, args, result, callId, sequenceOrder)
            
        case .stepStart:
            try insert(partId, messageId, "step_start", nil, nil, nil, nil, nil, sequenceOrder)
            
        case .stepFinish:
            try insert(partId, messageId, "step_finish", nil, nil, nil, nil, nil, sequenceOrder)
            
        case .image(let base64, let mimeType):
            try insert(partId, messageId, "image", "\(mimeType)|\(base64)", nil, nil, nil, nil, sequenceOrder)
        }
    }
    
    /// Загрузить сообщения только из базы проекта, зарегистрированной для сессии.
    func loadMessages(sessionId: String, limit: Int? = nil) -> [Message] {
        // For temporary sessions, use global database
        if isTemporarySession(sessionId) {
            do {
                let records = try db.getMessagesBySession(sessionId: sessionId, limit: limit)
                return records.map { record in
                    let parts = (try? db.getMessageParts(messageId: record.id)) ?? []
                    return Message(
                        id: record.id,
                        role: stringToRole(record.role),
                        content: record.content,
                        isStreaming: false,
                        parts: parts.map { convertPartRecord($0) },
                        reasoning: record.reasoning ?? "",
                        isFinished: record.isFinished
                    )
                }
            } catch {
                print("❌ Failed to load temporary messages: \(error)")
                return []
            }
        }
        
        guard let projectDB = resolveProjectDatabase(forSessionID: sessionId) else {
            print("❌ Cannot load messages without a registered project: \(sessionId)")
            return []
        }
        do {
            let records = try projectDB.getMessages(sessionId: sessionId, limit: limit)
            return records.map { record in
                let parts = (try? projectDB.getMessageParts(messageId: record.id)) ?? []
                return Message(
                    id: record.id,
                    role: stringToRole(record.role),
                    content: record.content,
                    isStreaming: false,
                    parts: parts.map { convertProjectPartRecord($0) },
                    reasoning: record.reasoning ?? "",
                    isFinished: record.isFinished
                )
            }
        } catch {
            print("❌ Failed to load messages from project database: \(error)")
            return []
        }
    }
    
    /// Конвертировать MessagePartRecord (общая БД) в MessagePartContent
    private func convertPartRecord(_ record: MessagePartRecord) -> MessagePartContent {
        switch record.type {
        case "text":
            return .text(record.content ?? "")
        case "reasoning":
            return .reasoning(record.content ?? "")
        case "tool_call":
            return .toolCall(
                name: record.toolName ?? "",
                args: record.toolArgs ?? "{}",
                result: record.toolResult,
                callID: record.toolCallId
            )
        case "step_start":
            return .stepStart
        case "step_finish":
            return .stepFinish
        case "image":
            if let content = record.content {
                let parts = content.split(separator: "|", maxSplits: 1)
                let mimeType = parts.count > 0 ? String(parts[0]) : "image/png"
                let base64 = parts.count > 1 ? String(parts[1]) : ""
                return .image(base64: base64, mimeType: mimeType)
            }
            return .text("")
        default:
            return .text("")
        }
    }

    /// Конвертировать ProjectMessagePartRecord (per-project БД) в MessagePartContent
    private func convertProjectPartRecord(_ record: ProjectMessagePartRecord) -> MessagePartContent {
        switch record.type {
        case "text":
            return .text(record.content ?? "")
        case "reasoning":
            return .reasoning(record.content ?? "")
        case "tool_call":
            return .toolCall(
                name: record.toolName ?? "",
                args: record.toolArgs ?? "{}",
                result: record.toolResult,
                callID: record.toolCallId
            )
        case "step_start":
            return .stepStart
        case "step_finish":
            return .stepFinish
        case "image":
            if let content = record.content {
                let parts = content.split(separator: "|", maxSplits: 1)
                let mimeType = parts.count > 0 ? String(parts[0]) : "image/png"
                let base64 = parts.count > 1 ? String(parts[1]) : ""
                return .image(base64: base64, mimeType: mimeType)
            }
            return .text("")
        default:
            return .text("")
        }
    }
    
    // MARK: - Provider & API Key Management
    
    /// Миграция провайдеров в БД + API keys в Keychain
    func migrateProvidersToSecureStorage(providers: [CustomProvider]) {
        for provider in providers {
            // Save API key to Keychain
            let apiKey = provider.apiKey
            if !apiKey.isEmpty {
                do {
                    try keychain.saveAPIKey(apiKey, for: provider.id)
                    print("✅ Migrated API key for provider: \(provider.id)")
                } catch {
                    print("❌ Failed to migrate API key for \(provider.id): \(error)")
                }
            }
            
            // Save provider metadata to DB (future implementation)
            // Provider table insert here
        }
    }
    
    /// Получить API key провайдера из Keychain
    func getProviderAPIKey(providerId: String) -> String? {
        do {
            return try keychain.getAPIKey(for: providerId)
        } catch {
            print("⚠️ No API key for provider \(providerId): \(error)")
            return nil
        }
    }
    
    /// Проверить наличие API key
    func hasProviderAPIKey(providerId: String) -> Bool {
        keychain.hasAPIKey(for: providerId)
    }
    
    /// Сохранить новый API key
    func saveProviderAPIKey(providerId: String, apiKey: String) {
        do {
            try keychain.saveAPIKey(apiKey, for: providerId)
        } catch {
            print("❌ Failed to save API key: \(error)")
        }
    }
    
    /// Удалить API key провайдера
    func deleteProviderAPIKey(providerId: String) {
        do {
            try keychain.deleteAPIKey(for: providerId)
        } catch {
            print("❌ Failed to delete API key: \(error)")
        }
    }
    
    // MARK: - Full-Text Search
    
    /// Поиск сообщений через FTS5
    func searchMessages(query: String) -> [String] {
        do {
            return try db.searchMessages(query: query, limit: 50)
        } catch {
            print("❌ Search failed: \(error)")
            return []
        }
    }
    
    // MARK: - Maintenance
    
    /// Выполнить maintenance если нужно (vacuum раз в неделю)
    func performMaintenanceIfNeeded() {
        db.performMaintenanceIfNeeded()
    }
    
    // MARK: - Helper Methods
    
    private func roleToString(_ role: MessageRole) -> String {
        switch role {
        case .user: return "user"
        case .assistant: return "assistant"
        case .system: return "system"
        }
    }
    
    private func stringToRole(_ string: String) -> MessageRole {
        switch string {
        case "user": return .user
        case "assistant": return .assistant
        case "system": return .system
        default: return .user
        }
    }
}
