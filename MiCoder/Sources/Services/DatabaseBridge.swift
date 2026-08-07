import Foundation
import Combine

/// Bridge-слой для интеграции DatabaseManager с существующим AppState
/// Автоматическая синхронизация между памятью и БД
class DatabaseBridge: ObservableObject {
    static let shared = DatabaseBridge()
    
    private let db = DatabaseManager.shared
    private let keychain = KeychainManager.shared
    
    private var cancellables = Set<AnyCancellable>()

    /// The project currently selected in the UI (normalized absolute path).
    /// Session/message calls that don't carry an explicit project id
    /// (`saveMessage`, `loadMessages`, `archiveSession`) route to this
    /// project's own database instead of the legacy shared one. Kept in
    /// sync by `AppState` whenever `selectedWorkspace` changes.
    ///
    /// Guarded by a lock: `DatabaseBridge` is a singleton that can be
    /// touched from multiple `AppState` instances / threads (notably in
    /// tests), so plain unsynchronized mutation of this optional would be a
    /// data race.
    private let activeProjectLock = NSLock()
    private var _activeProjectPath: String?
    private var activeProjectPath: String? {
        activeProjectLock.lock()
        defer { activeProjectLock.unlock() }
        return _activeProjectPath
    }

    func setActiveProject(path: String?) {
        activeProjectLock.lock()
        defer { activeProjectLock.unlock() }
        guard let path, !path.isEmpty else {
            _activeProjectPath = nil
            return
        }
        _activeProjectPath = ChatSession.normalizedPath(path)
    }

    /// Resolves `candidatePath` to its per-project database, or `nil` if the
    /// path doesn't look like a real, existing project directory (e.g. a
    /// legacy non-path identifier, or a project whose folder is missing).
    private func resolveProjectDatabase(for candidatePath: String) -> ProjectDatabaseManager? {
        guard !candidatePath.isEmpty else { return nil }
        return try? ProjectDatabaseManager.manager(forProjectPath: candidatePath)
    }

    private func resolveActiveProjectDatabase() -> ProjectDatabaseManager? {
        guard let activeProjectPath else { return nil }
        return resolveProjectDatabase(for: activeProjectPath)
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
            
            if existing == nil {
                try db.insertProject(
                    id: id,
                    name: name,
                    path: path,
                    gitRemote: gitRemote,
                    gitBranch: gitBranch
                )
            } else {
                // Update last opened
                try db.updateProjectLastOpened(id: id)
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
    /// per-project БД (см. `ProjectDatabaseManager`); если `projectId` не
    /// похож на реальный путь проекта на диске, откатывается на устаревшую
    /// общую БД для обратной совместимости.
    func loadSessions(projectId: String) -> [ChatSession] {
        if let projectDB = resolveProjectDatabase(for: projectId) {
            do {
                let records = try projectDB.getAllSessions(includeArchived: false)
                return records.map { record in
                    ChatSession(
                        id: record.id,
                        title: record.title,
                        createdAt: record.createdAt,
                        updatedAt: record.updatedAt,
                        directory: record.directory,
                        branch: record.branch,
                        gitSummary: nil
                    )
                }
            } catch {
                print("❌ Failed to load sessions from project database: \(error)")
                return []
            }
        }

        do {
            let records = try db.getSessionsByProject(projectId: projectId)
            return records.map { record in
                ChatSession(
                    id: record.id,
                    title: record.title,
                    createdAt: record.createdAt,
                    updatedAt: record.updatedAt,
                    directory: record.directory,
                    branch: record.branch,
                    gitSummary: nil
                )
            }
        } catch {
            print("❌ Failed to load sessions: \(error)")
            return []
        }
    }
    
    /// Создать новую сессию (upsert — обновляет если существует). Пишет в
    /// per-project БД, резолвленную по `projectId`; сессии без каталога
    /// уходят в общий "unassigned" стор, а не теряются.
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
        if let projectDB = resolveProjectDatabase(for: projectId) {
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
            return
        }

        if directory.isEmpty, let unassignedDB = try? ProjectDatabaseManager.unassignedManager() {
            do {
                try unassignedDB.insertSession(
                    id: id,
                    title: title,
                    directory: directory,
                    branch: branch,
                    agentMode: agentMode,
                    modelId: modelId,
                    providerId: providerId
                )
            } catch {
                print("❌ Failed to create unassigned session: \(error)")
            }
            return
        }

        do {
            try db.insertSession(
                id: id,
                projectId: projectId,
                title: title,
                directory: directory,
                branch: branch,
                agentMode: agentMode,
                modelId: modelId,
                providerId: providerId
            )
        } catch DatabaseError.duplicateEntry {
            // Session already exists — update its timestamp
            do {
                try db.updateSessionTimestamp(id: id)
            } catch {
                print("⚠️ Failed to update session timestamp: \(error)")
            }
        } catch {
            print("❌ Failed to create session: \(error)")
        }
    }
    
    /// Архивировать сессию. Использует активный проект (см.
    /// `setActiveProject`); если он не задан, откатывается на общую БД.
    func archiveSession(id: String) {
        if let projectDB = resolveActiveProjectDatabase() {
            do {
                try projectDB.archiveSession(id: id)
            } catch {
                print("❌ Failed to archive session in project database: \(error)")
            }
            return
        }

        do {
            try db.archiveSession(id: id)
        } catch {
            print("❌ Failed to archive session: \(error)")
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

    /// Сохранить сообщение в БД. Пишет в активный проект (см.
    /// `setActiveProject`); если он не задан, откатывается на общую БД.
    func saveMessage(_ message: Message, sessionId: String) {
        if let projectDB = resolveActiveProjectDatabase() {
            do {
                try projectDB.insertMessage(
                    id: message.id,
                    sessionId: sessionId,
                    role: roleToString(message.role),
                    content: message.content,
                    reasoning: message.reasoning.isEmpty ? nil : message.reasoning
                )
                for (index, part) in message.parts.enumerated() {
                    try saveMessagePart(part, messageId: message.id, sequenceOrder: index, insert: projectDB.insertMessagePart)
                }
            } catch {
                print("❌ Failed to save message in project database: \(error)")
            }
            return
        }

        do {
            try db.insertMessage(
                id: message.id,
                sessionId: sessionId,
                role: roleToString(message.role),
                content: message.content,
                modelId: nil,
                providerId: nil,
                reasoning: message.reasoning.isEmpty ? nil : message.reasoning
            )
            for (index, part) in message.parts.enumerated() {
                try saveMessagePart(part, messageId: message.id, sequenceOrder: index, insert: db.insertMessagePart)
            }
        } catch {
            print("❌ Failed to save message: \(error)")
        }
    }
    
    /// Сохранить часть сообщения через переданный `insert` (глобальная или per-project БД).
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
    
    /// Загрузить сообщения сессии из БД. Читает из активного проекта (см.
    /// `setActiveProject`); если он не задан, откатывается на общую БД.
    func loadMessages(sessionId: String, limit: Int? = nil) -> [Message] {
        if let projectDB = resolveActiveProjectDatabase() {
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
            print("❌ Failed to load messages: \(error)")
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
