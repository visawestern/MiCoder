import Foundation
import SQLite

/// Централизованный менеджер SQLite базы данных для MiMo
/// Использует SQLite.swift для type-safe queries
class DatabaseManager {
    static let shared = DatabaseManager()
    
    /// Current schema version — increment when tables change
    private static let schemaVersion: Int = 2
    
    private var db: Connection?
    private let dbPath: String
    private let isInMemory: Bool
    private let queue = DispatchQueue(label: "com.mimo.database", qos: .userInitiated)
    
    // MARK: - Table Definitions
    
    // Projects table
    private let projects = Table("projects")
    private let projectId = Expression<String>("id")
    private let projectName = Expression<String>("name")
    private let projectPath = Expression<String>("path")
    private let projectCreatedAt = Expression<Int64>("created_at")
    private let projectLastOpenedAt = Expression<Int64>("last_opened_at")
    private let projectGitRemote = Expression<String?>("git_remote")
    private let projectGitBranch = Expression<String?>("git_branch")
    private let projectIsPinned = Expression<Bool>("is_pinned")
    private let projectColor = Expression<String?>("color")
    private let projectIcon = Expression<String?>("icon")
    private let projectMetadata = Expression<String?>("metadata")
    private let projectDefaultAccessLevel = Expression<String?>("default_access_level")
    private let projectCustomInstructions = Expression<String?>("custom_instructions")
    private let projectEnvVars = Expression<Data?>("env_vars_encrypted")
    /// Minted once when a project is first registered and never changed
    /// afterwards, independent of `id` (which, per the storage-reset fix,
    /// equals the project's normalized path and therefore changes if the
    /// project is ever re-linked at a new path after being moved/renamed).
    private let projectStableId = Expression<String?>("stable_id")
    /// Per-project opt-in for automatically re-importing session history
    /// from the `mimo` CLI's own global session store. Defaults to `false`
    /// so resetting the app's local cache can never silently repopulate
    /// itself from CLI history the user didn't ask to sync.
    private let projectAutoImportFromCLI = Expression<Bool>("auto_import_from_cli")
    
    // Sessions table
    private let sessions = Table("sessions")
    private let sessionId = Expression<String>("id")
    private let sessionProjectId = Expression<String>("project_id")
    private let sessionTitle = Expression<String>("title")
    private let sessionCreatedAt = Expression<Int64>("created_at")
    private let sessionUpdatedAt = Expression<Int64>("updated_at")
    private let sessionDirectory = Expression<String>("directory")
    private let sessionBranch = Expression<String?>("branch")
    private let sessionAgentMode = Expression<String>("agent_mode")
    private let sessionModelId = Expression<String?>("model_id")
    private let sessionProviderId = Expression<String?>("provider_id")
    private let sessionParentId = Expression<String?>("parent_session_id")
    private let sessionIsArchived = Expression<Bool>("is_archived")
    private let sessionTokensUsed = Expression<Int64>("tokens_used")
    private let sessionCostUsd = Expression<Double>("cost_usd")
    private let sessionActiveTimeSeconds = Expression<Int64>("active_time_seconds")
    private let sessionMetadata = Expression<String?>("metadata")
    private let sessionGoal = Expression<String?>("session_goal")
    
    // Messages table
    private let messages = Table("messages")
    private let messageId = Expression<String>("id")
    private let messageSessionId = Expression<String>("session_id")
    private let messageRole = Expression<String>("role")
    private let messageContent = Expression<String>("content")
    private let messageCreatedAt = Expression<Int64>("created_at")
    private let messageModelId = Expression<String?>("model_id")
    private let messageProviderId = Expression<String?>("provider_id")
    private let messagePromptTokens = Expression<Int64?>("prompt_tokens")
    private let messageCompletionTokens = Expression<Int64?>("completion_tokens")
    private let messageReasoning = Expression<String?>("reasoning")
    private let messageIsStreaming = Expression<Bool>("is_streaming")
    private let messageIsFinished = Expression<Bool>("is_finished")
    private let messageParentMessageId = Expression<String?>("parent_message_id")
    private let messageEditOfMessageId = Expression<String?>("edit_of_message_id")
    private let messageMetadata = Expression<String?>("metadata")
    
    // Message Parts table
    private let messageParts = Table("message_parts")
    private let partId = Expression<String>("id")
    private let partMessageId = Expression<String>("message_id")
    private let partType = Expression<String>("type")
    private let partContent = Expression<String?>("content")
    private let partToolName = Expression<String?>("tool_name")
    private let partToolArgs = Expression<String?>("tool_args")
    private let partToolResult = Expression<String?>("tool_result")
    private let partToolCallId = Expression<String?>("tool_call_id")
    private let partSequenceOrder = Expression<Int64>("sequence_order")
    
    // Tool Calls table
    private let toolCalls = Table("tool_calls")
    private let toolCallId = Expression<String>("id")
    private let toolCallMessageId = Expression<String>("message_id")
    private let toolCallName = Expression<String>("tool_name")
    private let toolCallArguments = Expression<String>("arguments")
    private let toolCallResult = Expression<String?>("result")
    private let toolCallStatus = Expression<String>("status")
    private let toolCallStartedAt = Expression<Int64>("started_at")
    private let toolCallCompletedAt = Expression<Int64?>("completed_at")
    private let toolCallErrorMessage = Expression<String?>("error_message")
    private let toolCallExecutionTimeMs = Expression<Int64?>("execution_time_ms")
    
    // File Changes table
    private let fileChanges = Table("file_changes")
    private let fileChangeId = Expression<String>("id")
    private let fileChangeToolCallId = Expression<String>("tool_call_id")
    private let fileChangePath = Expression<String>("file_path")
    private let fileChangeOperation = Expression<String>("operation")
    private let fileChangeContentBefore = Expression<Data?>("content_before_compressed")
    private let fileChangeContentAfter = Expression<Data?>("content_after_compressed")
    private let fileChangeDiff = Expression<String?>("diff")
    private let fileChangeTimestamp = Expression<Int64>("timestamp")
    
    // Undo Stack table
    private let undoStack = Table("undo_stack")
    private let undoId = Expression<String>("id")
    private let undoSessionId = Expression<String>("session_id")
    private let undoActionType = Expression<String>("action_type")
    private let undoTargetPath = Expression<String?>("target_path")
    private let undoSnapshotId = Expression<String?>("snapshot_id")
    private let undoMetadata = Expression<String?>("metadata")
    private let undoCreatedAt = Expression<Int64>("created_at")
    private let undoCanUndo = Expression<Bool>("can_undo")
    
    // Providers table
    private let providers = Table("providers")
    private let providerId = Expression<String>("id")
    private let providerName = Expression<String>("name")
    private let providerType = Expression<String>("type")
    private let providerApiKeyKeychainId = Expression<String?>("api_key_keychain_id")
    private let providerBaseUrl = Expression<String?>("base_url")
    private let providerIsEnabled = Expression<Bool>("is_enabled")
    private let providerSupportsToolcall = Expression<Bool>("supports_toolcall")
    private let providerSupportsAcp = Expression<Bool>("supports_acp")
    private let providerIsOnline = Expression<Bool>("is_online")
    private let providerLastHealthCheck = Expression<Int64?>("last_health_check")
    private let providerCreatedAt = Expression<Int64>("created_at")
    private let providerMetadata = Expression<String?>("metadata")
    
    // MARK: - Initialization
    
    private init() {
        self.isInMemory = false
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let mimoDir = homeDir.appendingPathComponent(".micoder")
        try? FileManager.default.createDirectory(at: mimoDir, withIntermediateDirectories: true)
        self.dbPath = mimoDir.appendingPathComponent("mimo.db").path
        initialize()
    }
    
    /// Create in-memory database for testing purposes
    static func createInMemory() -> DatabaseManager {
        let manager = DatabaseManager(inMemory: true)
        return manager
    }
    
    private init(inMemory: Bool) {
        self.isInMemory = true
        self.dbPath = ":memory:"
        initialize()
    }
    
    private func initialize() {
        do {
            db = try Connection(dbPath)
            db?.busyTimeout = 5.0
            try createTables()
            try createIndexes()
            try createFTS5Index()
            try runMigrationsIfNeeded()
        } catch {
            print("❌ DatabaseManager init error: \(error)")
        }
    }
    
    // MARK: - Table Creation
    
    private func createTables() throws {
        guard let db = db else { return }
        
        // Projects table
        try db.run(projects.create(ifNotExists: true) { t in
            t.column(projectId, primaryKey: true)
            t.column(projectName)
            t.column(projectPath, unique: true)
            t.column(projectCreatedAt)
            t.column(projectLastOpenedAt)
            t.column(projectGitRemote)
            t.column(projectGitBranch)
            t.column(projectIsPinned, defaultValue: false)
            t.column(projectColor)
            t.column(projectIcon)
            t.column(projectMetadata)
            t.column(projectDefaultAccessLevel)
            t.column(projectCustomInstructions)
            t.column(projectEnvVars)
            t.column(projectStableId)
            t.column(projectAutoImportFromCLI, defaultValue: false)
        })
        
        // Sessions table
        try db.run(sessions.create(ifNotExists: true) { t in
            t.column(sessionId, primaryKey: true)
            t.column(sessionProjectId)
            t.column(sessionTitle)
            t.column(sessionCreatedAt)
            t.column(sessionUpdatedAt)
            t.column(sessionDirectory)
            t.column(sessionBranch)
            t.column(sessionAgentMode, defaultValue: "build")
            t.column(sessionModelId)
            t.column(sessionProviderId)
            t.column(sessionParentId)
            t.column(sessionIsArchived, defaultValue: false)
            t.column(sessionTokensUsed, defaultValue: 0)
            t.column(sessionCostUsd, defaultValue: 0.0)
            t.column(sessionActiveTimeSeconds, defaultValue: 0)
            t.column(sessionMetadata)
            t.column(sessionGoal)
            t.foreignKey(sessionProjectId, references: projects, projectId)
        })
        
        // Messages table
        try db.run(messages.create(ifNotExists: true) { t in
            t.column(messageId, primaryKey: true)
            t.column(messageSessionId)
            t.column(messageRole)
            t.column(messageContent)
            t.column(messageCreatedAt)
            t.column(messageModelId)
            t.column(messageProviderId)
            t.column(messagePromptTokens)
            t.column(messageCompletionTokens)
            t.column(messageReasoning)
            t.column(messageIsStreaming, defaultValue: false)
            t.column(messageIsFinished, defaultValue: true)
            t.column(messageParentMessageId)
            t.column(messageEditOfMessageId)
            t.column(messageMetadata)
            t.foreignKey(messageSessionId, references: sessions, sessionId, delete: .cascade)
        })
        
        // Message Parts table
        try db.run(messageParts.create(ifNotExists: true) { t in
            t.column(partId, primaryKey: true)
            t.column(partMessageId)
            t.column(partType)
            t.column(partContent)
            t.column(partToolName)
            t.column(partToolArgs)
            t.column(partToolResult)
            t.column(partToolCallId)
            t.column(partSequenceOrder)
            t.foreignKey(partMessageId, references: messages, messageId, delete: .cascade)
        })
        
        // Tool Calls table
        try db.run(toolCalls.create(ifNotExists: true) { t in
            t.column(toolCallId, primaryKey: true)
            t.column(toolCallMessageId)
            t.column(toolCallName)
            t.column(toolCallArguments)
            t.column(toolCallResult)
            t.column(toolCallStatus)
            t.column(toolCallStartedAt)
            t.column(toolCallCompletedAt)
            t.column(toolCallErrorMessage)
            t.column(toolCallExecutionTimeMs)
            t.foreignKey(toolCallMessageId, references: messages, messageId, delete: .cascade)
        })
        
        // File Changes table
        try db.run(fileChanges.create(ifNotExists: true) { t in
            t.column(fileChangeId, primaryKey: true)
            t.column(fileChangeToolCallId)
            t.column(fileChangePath)
            t.column(fileChangeOperation)
            t.column(fileChangeContentBefore)
            t.column(fileChangeContentAfter)
            t.column(fileChangeDiff)
            t.column(fileChangeTimestamp)
            t.foreignKey(fileChangeToolCallId, references: toolCalls, toolCallId, delete: .cascade)
        })
        
        // Undo Stack table
        try db.run(undoStack.create(ifNotExists: true) { t in
            t.column(undoId, primaryKey: true)
            t.column(undoSessionId)
            t.column(undoActionType)
            t.column(undoTargetPath)
            t.column(undoSnapshotId)
            t.column(undoMetadata)
            t.column(undoCreatedAt)
            t.column(undoCanUndo, defaultValue: true)
            t.foreignKey(undoSessionId, references: sessions, sessionId, delete: .cascade)
        })
        
        // Providers table
        try db.run(providers.create(ifNotExists: true) { t in
            t.column(providerId, primaryKey: true)
            t.column(providerName)
            t.column(providerType)
            t.column(providerApiKeyKeychainId)
            t.column(providerBaseUrl)
            t.column(providerIsEnabled, defaultValue: true)
            t.column(providerSupportsToolcall, defaultValue: true)
            t.column(providerSupportsAcp, defaultValue: false)
            t.column(providerIsOnline, defaultValue: false)
            t.column(providerLastHealthCheck)
            t.column(providerCreatedAt)
            t.column(providerMetadata)
        })
    }
    
    // MARK: - Index Creation
    
    private func createIndexes() throws {
        guard let db = db else { return }
        
        // Projects indexes
        try db.run(projects.createIndex(projectLastOpenedAt, ifNotExists: true))
        try db.run(projects.createIndex(projectIsPinned, ifNotExists: true))
        
        // Sessions indexes
        try db.run(sessions.createIndex(sessionProjectId, ifNotExists: true))
        try db.run(sessions.createIndex(sessionUpdatedAt, ifNotExists: true))
        try db.run(sessions.createIndex(sessionIsArchived, ifNotExists: true))
        try db.run(sessions.createIndex([sessionProjectId, sessionUpdatedAt], ifNotExists: true))
        
        // Messages indexes
        try db.run(messages.createIndex(messageSessionId, ifNotExists: true))
        try db.run(messages.createIndex(messageCreatedAt, ifNotExists: true))
        try db.run(messages.createIndex([messageSessionId, messageCreatedAt], ifNotExists: true))
        
        // Message Parts indexes
        try db.run(messageParts.createIndex(partMessageId, ifNotExists: true))
        try db.run(messageParts.createIndex([partMessageId, partSequenceOrder], ifNotExists: true))
        
        // Tool Calls indexes
        try db.run(toolCalls.createIndex(toolCallMessageId, ifNotExists: true))
        try db.run(toolCalls.createIndex(toolCallStatus, ifNotExists: true))
        try db.run(toolCalls.createIndex(toolCallName, ifNotExists: true))
        
        // File Changes indexes
        try db.run(fileChanges.createIndex(fileChangeToolCallId, ifNotExists: true))
        try db.run(fileChanges.createIndex(fileChangePath, ifNotExists: true))
        try db.run(fileChanges.createIndex(fileChangeTimestamp, ifNotExists: true))
        
        // Undo Stack indexes
        try db.run(undoStack.createIndex(undoSessionId, ifNotExists: true))
        try db.run(undoStack.createIndex([undoSessionId, undoCreatedAt], ifNotExists: true))
    }
    
    // MARK: - FTS5 Full-Text Search
    
    private func createFTS5Index() throws {
        guard let db = db else { return }
        
        // Standalone FTS5 table (no external content mapping to avoid column mismatch issues)
        try db.execute("""
            CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(
                content,
                session_title,
                file_paths,
                tool_names
            );
        """)
        
        // Triggers for auto-sync FTS5 index with messages table
        try db.execute("""
            CREATE TRIGGER IF NOT EXISTS messages_ai AFTER INSERT ON messages BEGIN
                INSERT INTO messages_fts(rowid, content, session_title, file_paths, tool_names)
                VALUES (new.rowid, new.content, '', '', '');
            END;
        """)
        
        try db.execute("""
            CREATE TRIGGER IF NOT EXISTS messages_ad AFTER DELETE ON messages BEGIN
                DELETE FROM messages_fts WHERE rowid = old.rowid;
            END;
        """)
        
        try db.execute("""
            CREATE TRIGGER IF NOT EXISTS messages_au AFTER UPDATE ON messages BEGIN
                DELETE FROM messages_fts WHERE rowid = old.rowid;
                INSERT INTO messages_fts(rowid, content, session_title, file_paths, tool_names)
                VALUES (new.rowid, new.content, '', '', '');
            END;
        """)
    }
    
    // MARK: - Project Operations
    
    func insertProject(
        id: String,
        name: String,
        path: String,
        gitRemote: String? = nil,
        gitBranch: String? = nil,
        stableId: String? = nil,
        autoImportFromCLI: Bool = false
    ) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        let now = Int64(Date().timeIntervalSince1970)
        try db.run(projects.insert(
            projectId <- id,
            projectName <- name,
            projectPath <- path,
            projectCreatedAt <- now,
            projectLastOpenedAt <- now,
            projectGitRemote <- gitRemote,
            projectGitBranch <- gitBranch,
            projectIsPinned <- false,
            projectStableId <- stableId ?? UUID().uuidString,
            projectAutoImportFromCLI <- autoImportFromCLI
        ))
    }
    
    func getAllProjects(limit: Int = 100) throws -> [ProjectRecord] {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        var results: [ProjectRecord] = []
        for row in try db.prepare(projects.order(projectLastOpenedAt.desc).limit(limit)) {
            results.append(ProjectRecord(
                id: row[projectId],
                name: row[projectName],
                path: row[projectPath],
                createdAt: Date(timeIntervalSince1970: TimeInterval(row[projectCreatedAt])),
                lastOpenedAt: Date(timeIntervalSince1970: TimeInterval(row[projectLastOpenedAt])),
                gitRemote: row[projectGitRemote],
                gitBranch: row[projectGitBranch],
                isPinned: row[projectIsPinned],
                stableId: row[projectStableId],
                autoImportFromCLI: row[projectAutoImportFromCLI]
            ))
        }
        return results
    }

    /// Looks up a registry entry by its path-independent `stable_id`. Used
    /// to recognize a project that was moved/renamed on disk: its
    /// `.micoder/project.db` (which moves with the folder) still reports
    /// the same stable id even though the registry's remembered path is now
    /// stale.
    func findProjectByStableId(_ stableId: String) throws -> ProjectRecord? {
        guard let db = db else { throw DatabaseError.notInitialized }
        guard let row = try db.pluck(projects.filter(projectStableId == stableId)) else { return nil }
        return ProjectRecord(
            id: row[projectId],
            name: row[projectName],
            path: row[projectPath],
            createdAt: Date(timeIntervalSince1970: TimeInterval(row[projectCreatedAt])),
            lastOpenedAt: Date(timeIntervalSince1970: TimeInterval(row[projectLastOpenedAt])),
            gitRemote: row[projectGitRemote],
            gitBranch: row[projectGitBranch],
            isPinned: row[projectIsPinned],
            stableId: row[projectStableId],
            autoImportFromCLI: row[projectAutoImportFromCLI]
        )
    }

    /// Re-points a registry entry at a new path after the project folder
    /// was moved/renamed outside the app. Since `id` is policy-defined to be
    /// the normalized path (see storage-reset fix), relinking replaces the
    /// row's id as well, while preserving `stableId`/`createdAt` so the
    /// project's identity and history provenance survive the move.
    @discardableResult
    func relinkProject(oldId: String, newPath: String, name: String) throws -> String {
        guard let db = db else { throw DatabaseError.notInitialized }
        let normalizedNewPath = ChatSession.normalizedPath(newPath)
        let existingRow = try db.pluck(projects.filter(projectId == oldId))
        let preservedStableId = existingRow?[projectStableId]
        let preservedAutoImport = existingRow?[projectAutoImportFromCLI] ?? false

        try db.run(projects.filter(projectId == oldId).delete())
        try insertProject(
            id: normalizedNewPath,
            name: name,
            path: normalizedNewPath,
            stableId: preservedStableId,
            autoImportFromCLI: preservedAutoImport
        )
        return normalizedNewPath
    }

    func setAutoImportFromCLI(projectId id: String, enabled: Bool) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        try db.run(projects.filter(projectId == id).update(projectAutoImportFromCLI <- enabled))
    }

    func isAutoImportFromCLIEnabled(projectId id: String) throws -> Bool {
        guard let db = db else { throw DatabaseError.notInitialized }
        guard let row = try db.pluck(projects.filter(projectId == id)) else { return false }
        return row[projectAutoImportFromCLI]
    }
    
    func updateProjectLastOpened(id: String) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        let project = projects.filter(projectId == id)
        let now = Int64(Date().timeIntervalSince1970)
        try db.run(project.update(projectLastOpenedAt <- now))
    }
    
    func toggleProjectPin(id: String) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        let project = projects.filter(projectId == id)
        if let row = try db.pluck(project) {
            let currentValue = row[projectIsPinned]
            try db.run(project.update(projectIsPinned <- !currentValue))
        }
    }
    
    // MARK: - Session Operations
    
    func insertSession(
        id: String,
        projectId: String,
        title: String,
        directory: String,
        branch: String? = nil,
        agentMode: String = "build",
        modelId: String? = nil,
        providerId: String? = nil
    ) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        let now = Int64(Date().timeIntervalSince1970)
        do {
            try db.run(sessions.insert(
                sessionId <- id,
                sessionProjectId <- projectId,
                sessionTitle <- title,
                sessionCreatedAt <- now,
                sessionUpdatedAt <- now,
                sessionDirectory <- directory,
                sessionBranch <- branch,
                sessionAgentMode <- agentMode,
                sessionModelId <- modelId,
                sessionProviderId <- providerId
            ))
        } catch let Result.error(_, code, _) where code == 19 {
            throw DatabaseError.duplicateEntry
        }
    }

    /// Persist a session's goal (plan Раздел 5 Блок 1 п.10). nil clears it.
    func setSessionGoal(sessionId id: String, goal: String?) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        try db.run(sessions.filter(sessionId == id).update(sessionGoal <- goal))
    }

    /// Read a session's persisted goal.
    func getSessionGoal(sessionId id: String) throws -> String? {
        guard let db = db else { throw DatabaseError.notInitialized }
        guard let row = try db.pluck(sessions.filter(sessionId == id)) else { return nil }
        return row[sessionGoal]
    }
    
    func getSessionsByProject(projectId: String, includeArchived: Bool = false) throws -> [SessionRecord] {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        var query = sessions.filter(sessionProjectId == projectId)
        if !includeArchived {
            query = query.filter(sessionIsArchived == false)
        }
        query = query.order(sessionUpdatedAt.desc)
        
        var results: [SessionRecord] = []
        for row in try db.prepare(query) {
            results.append(SessionRecord(
                id: row[sessionId],
                projectId: row[sessionProjectId],
                title: row[sessionTitle],
                createdAt: Date(timeIntervalSince1970: TimeInterval(row[sessionCreatedAt])),
                updatedAt: Date(timeIntervalSince1970: TimeInterval(row[sessionUpdatedAt])),
                directory: row[sessionDirectory],
                branch: row[sessionBranch],
                agentMode: row[sessionAgentMode],
                isArchived: row[sessionIsArchived],
                tokensUsed: Int(row[sessionTokensUsed]),
                costUsd: row[sessionCostUsd]
            ))
        }
        return results
    }
    
    /// Returns every session across every project, regardless of `project_id`.
    /// Used by `ProjectDatabaseMigrator` to distribute the legacy single-file
    /// database into per-project databases grouped by directory.
    func getAllSessionsAcrossProjects() throws -> [SessionRecord] {
        guard let db = db else { throw DatabaseError.notInitialized }

        var results: [SessionRecord] = []
        for row in try db.prepare(sessions.order(sessionUpdatedAt.desc)) {
            results.append(SessionRecord(
                id: row[sessionId],
                projectId: row[sessionProjectId],
                title: row[sessionTitle],
                createdAt: Date(timeIntervalSince1970: TimeInterval(row[sessionCreatedAt])),
                updatedAt: Date(timeIntervalSince1970: TimeInterval(row[sessionUpdatedAt])),
                directory: row[sessionDirectory],
                branch: row[sessionBranch],
                agentMode: row[sessionAgentMode],
                isArchived: row[sessionIsArchived],
                tokensUsed: Int(row[sessionTokensUsed]),
                costUsd: row[sessionCostUsd]
            ))
        }
        return results
    }

    func updateSessionTimestamp(id: String) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        let session = sessions.filter(sessionId == id)
        let now = Int64(Date().timeIntervalSince1970)
        try db.run(session.update(sessionUpdatedAt <- now))
    }
    
    func archiveSession(id: String) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        let session = sessions.filter(sessionId == id)
        try db.run(session.update(sessionIsArchived <- true))
    }
    
    // MARK: - Message Operations
    
    func insertMessage(
        id: String,
        sessionId: String,
        role: String,
        content: String,
        modelId: String? = nil,
        providerId: String? = nil,
        reasoning: String? = nil
    ) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        let now = Int64(Date().timeIntervalSince1970)
        try db.run(messages.insert(
            messageId <- id,
            messageSessionId <- sessionId,
            messageRole <- role,
            messageContent <- content,
            messageCreatedAt <- now,
            messageModelId <- modelId,
            messageProviderId <- providerId,
            messageReasoning <- reasoning,
            messageIsFinished <- true
        ))
        
        // Update session timestamp
        try updateSessionTimestamp(id: sessionId)
    }
    
    func getMessagesBySession(sessionId: String, limit: Int? = nil, offset: Int = 0) throws -> [MessageRecord] {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        var query = messages.filter(messageSessionId == sessionId).order(messageCreatedAt.asc)
        if let limit = limit {
            query = query.limit(limit, offset: offset)
        }
        
        var results: [MessageRecord] = []
        for row in try db.prepare(query) {
            results.append(MessageRecord(
                id: row[messageId],
                sessionId: row[messageSessionId],
                role: row[messageRole],
                content: row[messageContent],
                createdAt: Date(timeIntervalSince1970: TimeInterval(row[messageCreatedAt])),
                reasoning: row[messageReasoning],
                isFinished: row[messageIsFinished]
            ))
        }
        return results
    }
    
    func insertMessagePart(
        id: String,
        messageId: String,
        type: String,
        content: String? = nil,
        toolName: String? = nil,
        toolArgs: String? = nil,
        toolResult: String? = nil,
        toolCallId: String? = nil,
        sequenceOrder: Int
    ) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        try db.run(messageParts.insert(
            partId <- id,
            partMessageId <- messageId,
            partType <- type,
            partContent <- content,
            partToolName <- toolName,
            partToolArgs <- toolArgs,
            partToolResult <- toolResult,
            partToolCallId <- toolCallId,
            partSequenceOrder <- Int64(sequenceOrder)
        ))
    }
    
    func getMessageParts(messageId: String) throws -> [MessagePartRecord] {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        let query = messageParts.filter(partMessageId == messageId).order(partSequenceOrder.asc)
        
        var results: [MessagePartRecord] = []
        for row in try db.prepare(query) {
            results.append(MessagePartRecord(
                id: row[partId],
                messageId: row[partMessageId],
                type: row[partType],
                content: row[partContent],
                toolName: row[partToolName],
                toolArgs: row[partToolArgs],
                toolResult: row[partToolResult],
                toolCallId: row[partToolCallId],
                sequenceOrder: Int(row[partSequenceOrder])
            ))
        }
        return results
    }
    
    // MARK: - Full-Text Search
    
    func searchMessages(query: String, limit: Int = 50) throws -> [String] {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        let sql = """
            SELECT messages.id FROM messages_fts
            JOIN messages ON messages.rowid = messages_fts.rowid
            WHERE messages_fts MATCH ?
            ORDER BY rank
            LIMIT ?
        """
        
        var messageIds: [String] = []
        for row in try db.prepare(sql, [query, limit]) {
            if let id = row[0] as? String {
                messageIds.append(id)
            }
        }
        return messageIds
    }
    
    // MARK: - Schema Migrations
    
    private func runMigrationsIfNeeded() throws {
        guard let db = db else { return }
        
        // Create schema version table
        try db.execute("""
            CREATE TABLE IF NOT EXISTS schema_version (
                version INTEGER PRIMARY KEY,
                migrated_at INTEGER NOT NULL
            );
        """)
        
        let currentVersion = try db.scalar("SELECT COALESCE(MAX(version), 0) FROM schema_version") as? Int ?? 0
        
        guard currentVersion < Self.schemaVersion else { return }
        
        // Run migrations sequentially
        for version in (currentVersion + 1)...Self.schemaVersion {
            try runMigration(version)
            try db.run("INSERT OR IGNORE INTO schema_version (version, migrated_at) VALUES (?, ?)",
                      version, Int64(Date().timeIntervalSince1970))
            print("✅ Database migrated to schema version \(version)")
        }
    }
    
    private func runMigration(_ version: Int) throws {
        guard db != nil else { return }
        switch version {
        case 1:
            // Initial schema — all tables created in createTables()
            break
        case 2:
            // Registry evolution for the per-project storage + reset-bug
            // fix: `stable_id` survives a project being re-linked at a new
            // path, `auto_import_from_cli` replaces the old "reimport if
            // in-memory sessions look empty" heuristic with an explicit,
            // per-project, default-off opt-in.
            try addColumnIfMissing(table: "projects", column: "stable_id", definition: "TEXT")
            try addColumnIfMissing(table: "projects", column: "auto_import_from_cli", definition: "INTEGER NOT NULL DEFAULT 0")
            // Session goal set via /goal, shown in the TopBar (plan Раздел 5 Блок 1 п.10).
            try addColumnIfMissing(table: "sessions", column: "session_goal", definition: "TEXT")
        default:
            break
        }
    }

    private func addColumnIfMissing(table: String, column: String, definition: String) throws {
        guard let db = db else { return }
        let existingColumns = try db.prepare("PRAGMA table_info(\(table))").compactMap { row -> String? in
            row[1] as? String
        }
        guard !existingColumns.contains(column) else { return }
        try db.execute("ALTER TABLE \(table) ADD COLUMN \(column) \(definition)")
    }
    
    /// Reset database (for testing)
    func reset() throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        
        // Drop all tables
        try db.execute("DROP TABLE IF EXISTS undo_stack")
        try db.execute("DROP TABLE IF EXISTS file_changes")
        try db.execute("DROP TABLE IF EXISTS tool_calls")
        try db.execute("DROP TABLE IF EXISTS message_parts")
        try db.execute("DROP TABLE IF EXISTS messages")
        try db.execute("DROP TABLE IF EXISTS sessions")
        try db.execute("DROP TABLE IF EXISTS projects")
        try db.execute("DROP TABLE IF EXISTS providers")
        try db.execute("DROP TABLE IF EXISTS schema_version")
        try db.execute("DROP TABLE IF EXISTS messages_fts")
        
        // Recreate
        try createTables()
        try createIndexes()
        try createFTS5Index()
        try runMigrationsIfNeeded()
    }
    
    // MARK: - Maintenance
    
    func vacuum() throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        try db.execute("VACUUM")
    }
    
    // MARK: - Raw SQL Execution (for undo stack и других операций)
    
    /// Выполнить raw SQL запрос (INSERT/UPDATE/DELETE)
    func exec(_ sql: String) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        try db.execute(sql)
    }
    
    /// Выполнить raw SQL запрос и вернуть результаты
    func query(_ sql: String) throws -> [[Any]] {
        guard let db = db else { throw DatabaseError.notInitialized }
        var results: [[Any]] = []
        for row in try db.prepare(sql) {
            results.append(row as [Any])
        }
        return results
    }
    
    func getLastVacuumDate() -> Date? {
        UserDefaults.standard.object(forKey: "lastDatabaseVacuum") as? Date
    }
    
    func setLastVacuumDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: "lastDatabaseVacuum")
    }
    
    func performMaintenanceIfNeeded() {
        queue.async {
            // Vacuum
            if let lastVacuum = self.getLastVacuumDate() {
                let daysSinceVacuum = Date().timeIntervalSince(lastVacuum) / 86400
                if daysSinceVacuum > 7 {
                    try? self.vacuum()
                    self.setLastVacuumDate(Date())
                }
            } else {
                try? self.vacuum()
                self.setLastVacuumDate(Date())
            }
            
            // Auto-archive sessions older than 7 days
            try? self.archiveSessionsOlderThan(days: 7)
        }
    }
    
    // MARK: - Storage Management
    
    /// Archive sessions not updated in more than `days` days
    func archiveSessionsOlderThan(days: Int) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        let cutoff = Int64(Date().timeIntervalSince1970) - Int64(days * 86400)
        let oldSessions = sessions.filter(sessionUpdatedAt < cutoff && sessionIsArchived == false)
        try db.run(oldSessions.update(sessionIsArchived <- true))
    }
    
    /// Unarchive a session
    func unarchiveSession(id: String) throws {
        guard let db = db else { throw DatabaseError.notInitialized }
        let session = sessions.filter(sessionId == id)
        try db.run(session.update(sessionIsArchived <- false, sessionUpdatedAt <- Int64(Date().timeIntervalSince1970)))
    }
    
    /// Hard delete all archived sessions and their messages
    func deleteArchivedSessions() throws -> Int {
        guard let db = db else { throw DatabaseError.notInitialized }
        let archived = sessions.filter(sessionIsArchived == true)
        let count = try db.run(archived.delete())
        return count
    }
    
    /// Hard delete sessions older than N days (including their messages via FK cascade)
    func deleteSessionsOlderThan(days: Int) throws -> Int {
        guard let db = db else { throw DatabaseError.notInitialized }
        let cutoff = Int64(Date().timeIntervalSince1970) - Int64(days * 86400)
        let old = sessions.filter(sessionUpdatedAt < cutoff)
        let count = try db.run(old.delete())
        return count
    }
    
    /// Count messages in the database
    func messageCount() throws -> Int {
        guard let db = db else { throw DatabaseError.notInitialized }
        return try db.scalar(messages.count)
    }

    /// Read real per-message usage data points for statistics (plan Раздел 10
    /// Блок 2 п.13-14). Uses the existing model_id/provider_id/prompt_tokens/
    /// completion_tokens columns. Cost is not stored per message → nil (N/A).
    func usageDataPoints() throws -> [UsageDataPoint] {
        guard let db = db else { throw DatabaseError.notInitialized }
        var points: [UsageDataPoint] = []
        let query = messages.filter(messageRole == "assistant")
        for row in try db.prepare(query) {
            let prompt = Int(row[messagePromptTokens] ?? 0)
            let completion = Int(row[messageCompletionTokens] ?? 0)
            guard prompt > 0 || completion > 0 else { continue }
            let model = row[messageModelId] ?? "unknown"
            let provider = row[messageProviderId] ?? "unknown"
            let ts = Date(timeIntervalSince1970: TimeInterval(row[messageCreatedAt]))
            points.append(UsageDataPoint(
                timestamp: ts, model: model, provider: provider,
                promptTokens: prompt, completionTokens: completion, costUSD: nil
            ))
        }
        return points
    }
    
    /// Count sessions per project
    func sessionCountsByProject() throws -> [(projectId: String, active: Int, archived: Int)] {
        guard let db = db else { throw DatabaseError.notInitialized }
        var results: [(String, Int, Int)] = []
        // Active
        for row in try db.prepare("SELECT project_id, COUNT(*) FROM sessions WHERE is_archived = 0 GROUP BY project_id") {
            if let pid = row[0] as? String, let count = row[1] as? Int64 {
                results.append((pid, Int(count), 0))
            }
        }
        // Archived
        for row in try db.prepare("SELECT project_id, COUNT(*) FROM sessions WHERE is_archived = 1 GROUP BY project_id") {
            if let pid = row[0] as? String, let count = row[1] as? Int64 {
                if let idx = results.firstIndex(where: { $0.0 == pid }) {
                    results[idx] = (pid, results[idx].1, Int(count))
                } else {
                    results.append((pid, 0, Int(count)))
                }
            }
        }
        return results
    }
    
    /// Total database file size in bytes
    func databaseFileSize() -> UInt64 {
        guard !isInMemory else { return 0 }
        let path = dbPath
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path) else { return 0 }
        return (attrs[.size] as? UInt64) ?? 0
    }
}

// MARK: - Error Types

enum DatabaseError: Error {
    case notInitialized
    case recordNotFound
    case invalidData
    case duplicateEntry
}

// MARK: - Record Types

struct ProjectRecord {
    let id: String
    let name: String
    let path: String
    let createdAt: Date
    let lastOpenedAt: Date
    let gitRemote: String?
    let gitBranch: String?
    let isPinned: Bool
    let stableId: String?
    let autoImportFromCLI: Bool
}

struct SessionRecord {
    let id: String
    let projectId: String
    let title: String
    let createdAt: Date
    let updatedAt: Date
    let directory: String
    let branch: String?
    let agentMode: String
    let isArchived: Bool
    let tokensUsed: Int
    let costUsd: Double
}

struct MessageRecord {
    let id: String
    let sessionId: String
    let role: String
    let content: String
    let createdAt: Date
    let reasoning: String?
    let isFinished: Bool
}

struct MessagePartRecord {
    let id: String
    let messageId: String
    let type: String
    let content: String?
    let toolName: String?
    let toolArgs: String?
    let toolResult: String?
    let toolCallId: String?
    let sequenceOrder: Int
}
