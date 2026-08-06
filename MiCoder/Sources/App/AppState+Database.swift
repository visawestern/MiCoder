// DatabaseManager integration extension for AppState
import Foundation

extension AppState {
    
    /// Получить доступ к DatabaseBridge
    private var db: DatabaseBridge {
        DatabaseBridge.shared
    }
    
    /// Инициализация базы данных
    @MainActor
    func initializeDatabase() async {
        // 1. Выполнить maintenance + авто-архивация
        DatabaseManager.shared.performMaintenanceIfNeeded()
        
        // 2. Загрузить проекты из БД
        await loadProjectsFromDatabase()
        
        // 3. Если есть выбранный проект, загрузить его сессии
        if let currentProjectId = selectedWorkspace?.id {
            await loadSessionsFromDatabase(projectId: currentProjectId)
        }
        
        print("✅ Database initialized successfully")
    }
    
    /// Загрузить проекты из локальной БД
    @MainActor
    func loadProjectsFromDatabase() async {
        let projects = db.loadProjects()
        
        // Convert to Workspace format (tasks will be populated from sessions)
        let workspacesList = projects.map { project in
            Workspace(
                id: project.id,
                name: project.name,
                path: project.path,
                branch: project.branch,
                tasks: [] // Will be populated from sessions
            )
        }
        
        self.workspaces = workspacesList
        
        print("✅ Loaded \(projects.count) projects from database")
    }
    
    /// Загрузить сессии проекта из БД
    @MainActor
    func loadSessionsFromDatabase(projectId: String) async {
        let sessions = db.loadSessions(projectId: projectId)
        
        // Update global sessions list
        self.sessions = sessions
        
        // Convert sessions to workspace tasks
        if let index = workspaces.firstIndex(where: { $0.id == projectId }) {
            let tasks = sessions.map { session in
                WorkspaceTask(
                    id: session.id,
                    title: session.title,
                    status: .inProgress,
                    duration: nil
                )
            }
            workspaces[index].tasks = tasks
        }
    }
    
    /// Создать новый проект/workspace в БД
    @MainActor
    func createOrUpdateProject(id: String, name: String, path: String, gitRemote: String? = nil, gitBranch: String? = nil) {
        db.upsertProject(
            id: id,
            name: name,
            path: path,
            gitRemote: gitRemote,
            gitBranch: gitBranch
        )
        
        // Reload projects
        Task {
            await loadProjectsFromDatabase()
        }
    }
    
    /// Создать новую сессию в БД
    @MainActor
    func createSessionInDatabase(
        id: String,
        projectId: String,
        title: String,
        directory: String,
        branch: String? = nil
    ) {
        db.createSession(
            id: id,
            projectId: projectId,
            title: title,
            directory: directory,
            branch: branch,
            agentMode: agentMode.rawValue,
            modelId: selectedModel.isEmpty ? nil : selectedModel,
            providerId: selectedProviderID.isEmpty ? nil : selectedProviderID
        )
        
        // Reload sessions
        Task {
            await loadSessionsFromDatabase(projectId: projectId)
        }
    }
    
    /// Архивировать сессию
    @MainActor
    func archiveSessionInDatabase(id: String) {
        db.archiveSession(id: id)
        
        // Reload current project sessions
        if let projectId = selectedWorkspace?.id {
            Task {
                await loadSessionsFromDatabase(projectId: projectId)
            }
        }
    }
    
    /// Toggle pin статус проекта
    @MainActor
    func toggleProjectPin(projectId: String) {
        db.toggleProjectPin(id: projectId)
        
        // Reload projects
        Task {
            await loadProjectsFromDatabase()
        }
    }
    
    /// Получить API key провайдера из Keychain
    func getProviderAPIKey(providerId: String) -> String? {
        return db.getProviderAPIKey(providerId: providerId)
    }
    
    /// Сохранить новый API key провайдера
    @MainActor
    func saveProviderAPIKey(providerId: String, apiKey: String) {
        db.saveProviderAPIKey(providerId: providerId, apiKey: apiKey)
        
        // Note: CustomProvider.apiKey is non-optional String, so we can't set it to nil
        // The key is now safely stored in Keychain and can be retrieved via getSecureAPIKey()
    }
    
    /// Удалить API key провайдера
    @MainActor
    func deleteProviderAPIKey(providerId: String) {
        db.deleteProviderAPIKey(providerId: providerId)
    }
    
    /// Поиск сообщений через FTS5
    func searchMessagesInDatabase(query: String) -> [String] {
        return db.searchMessages(query: query)
    }
    
    // MARK: - Storage Management
    
    /// Получить статистику хранилища
    @MainActor
    /// Real usage data points from the DB for statistics (plan Раздел 10).
    func loadUsageDataPoints() -> [UsageDataPoint] {
        (try? DatabaseManager.shared.usageDataPoints()) ?? []
    }

    func loadStorageStats() -> StorageStats {
        let dbSize = DatabaseManager.shared.databaseFileSize()
        let snapSize = FileSnapshotManager.shared.snapshotsSizeBytes()
        let msgCount = (try? DatabaseManager.shared.messageCount()) ?? 0
        let sessionCounts = (try? DatabaseManager.shared.sessionCountsByProject()) ?? []
        
        return StorageStats(
            databaseSize: dbSize,
            snapshotSize: snapSize,
            messageCount: msgCount,
            sessionCountsByProject: sessionCounts
        )
    }
    
    /// Заархивировать сессии старше N дней
    func archiveOldSessions(days: Int) {
        try? StorageAuditLog.append(action: "sessions.archive_old",
                                    detail: "days=\(days)",
                                    homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
        try? DatabaseManager.shared.archiveSessionsOlderThan(days: days)
        Task { @MainActor in
            await loadProjectsFromDatabase()
        }
    }
    
    /// Удалить все архивированные сессии
    func deleteArchivedSessions() -> Int {
        try? StorageAuditLog.append(action: "sessions.delete_archived",
                                    detail: "all",
                                    homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
        let count = (try? DatabaseManager.shared.deleteArchivedSessions()) ?? 0
        if count > 0 {
            try? DatabaseManager.shared.vacuum()
            Task { @MainActor in
                await loadProjectsFromDatabase()
            }
        }
        return count
    }
    
    /// Удалить сессии старше N дней
    func deleteSessionsOlderThan(days: Int) -> Int {
        try? StorageAuditLog.append(action: "sessions.delete_older",
                                    detail: "days=\(days)",
                                    homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
        let count = (try? DatabaseManager.shared.deleteSessionsOlderThan(days: days)) ?? 0
        if count > 0 {
            try? DatabaseManager.shared.vacuum()
            Task { @MainActor in
                await loadProjectsFromDatabase()
            }
        }
        return count
    }
    
    /// Clears in-memory selection/navigation/sessions/projects (no DB I/O).
    /// Round 10 — the crash fix is verifiable without touching the real
    /// database, so tests never race on ~/.micoder/mimo.db.
    func clearInMemoryState() {
        selectedSession = nil
        selectedWorkspace = nil
        sessions = []
        projects = []
        clearNavigationHistory()
    }

    /// Reset storage by explicit scope (plan Раздел 8 Блок 1 п.10).
    /// Honest, predictable behavior: deletes exactly the planned paths and
    /// clears selection/navigation.
    ///
    /// Round 14 (test-safety): `homeDirectory` is injectable so tests sandbox
    /// the reset to a temp dir instead of the REAL user home (the old
    /// StorageResetCrashTests deleted the real ~/.micoder/mimo.db).
    /// `resetDatabase` is a closure so tests can substitute a no-op and never
    /// touch `DatabaseManager.shared`.
    func resetStorage(scope: StorageResetScope,
                      homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
                      resetDatabase: () -> Void = { try? DatabaseManager.shared.wipeAndReopen() }) {
        let home = homeDirectory
        let plan = StorageResetLogic.plan(for: scope, homeDirectory: home)

        // Audit the reset (plan Раздел 8 п.46) BEFORE the deletion so the log
        // survives any crash mid-reset.
        try? StorageAuditLog.append(action: "storage.reset",
                                    detail: "scope=\(plan.scope) paths=\(plan.deletesPaths.joined(separator: ", "))",
                                    homeDirectory: home)

        // Delete exactly the planned paths and their SQLite sidecars
        // (-journal/-wal/-shm). The live connection is still open for this
        // brief instant; the default `resetDatabase` closure immediately closes
        // it (wipeAndReopen) so the deleted inode can never poison later
        // statements, and `SQLiteSafeQuery` makes any transient error during
        // the window throw instead of crash (SIGILL).
        for path in plan.deletesPaths {
            try? FileManager.default.removeItem(atPath: path)
            for suffix in ["-journal", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: path + suffix)
            }
        }

        // Reinitialize the app database (recreates the cleared mimo.db on
        // disk). Default = wipeAndReopen(): closes the stale open handle to
        // the removed file, ensures the file+sidecars are gone, and opens a
        // brand-new empty database. Tests substitute a no-op closure so the
        // real singleton is never touched.
        resetDatabase()

        clearInMemoryState()

        Task { @MainActor in
            await loadProjectsFromDatabase()
        }
    }

    /// Сбросить базу данных
    func resetDatabase() {
        try? DatabaseManager.shared.reset()
        Task { @MainActor in
            await loadProjectsFromDatabase()
            sessions = []
        }
    }
    
    /// Сжать базу (VACUUM)
    func vacuumDatabase() {
        try? DatabaseManager.shared.vacuum()
    }

    /// Сжать per-project БД конкретного проекта (plan Раздел 8 п.28).
    /// Автобэкап перед VACUUM (plan Раздел 8 п.49) — на случай повреждения
    /// при сжатии остаётся рабочая копия.
    func vacuumProject(path: String) -> Bool {
        _ = try? ProjectAutoBackupLogic.createBackup(projectPath: path)
        _ = try? ProjectAutoBackupLogic.prune(projectPath: path)
        guard let db = try? ProjectDatabaseManager.manager(forProjectPath: path) else { return false }
        do {
            try db.vacuum()
            return true
        } catch {
            return false
        }
    }

    /// Export the current project's full history via ProjectHistoryExporter.
    /// This wires the exporter into live code so it is no longer an orphan
    /// (Round 7 orphan-wiring requirement).
    func exportProjectHistory() -> Data? {
        guard let path = selectedWorkspace?.path,
              let db = try? ProjectDatabaseManager.manager(forProjectPath: path) else { return nil }
        return try? ProjectHistoryExporter.export(from: db)
    }

    /// Import a previously exported project history bundle.
    @discardableResult
    func importProjectHistory(_ data: Data) -> ProjectHistoryExporter.ImportSummary? {
        guard let path = selectedWorkspace?.path,
              let db = try? ProjectDatabaseManager.manager(forProjectPath: path) else { return nil }
        return try? ProjectHistoryExporter.importBundle(data, into: db)
    }
    
    /// Архивировать сессию и обновить UI
    func archiveSessionInDatabaseUI(id: String) {
        db.archiveSession(id: id)
        if let projectId = selectedWorkspace?.id {
            Task { @MainActor in
                await loadSessionsFromDatabase(projectId: projectId)
            }
        }
    }
    
    /// Разархивировать сессию
    func unarchiveSessionInDatabase(id: String) {
        try? DatabaseManager.shared.unarchiveSession(id: id)
        if let projectId = selectedWorkspace?.id {
            Task { @MainActor in
                await loadSessionsFromDatabase(projectId: projectId)
            }
        }
    }
}

// MARK: - Models

struct StorageStats {
    let databaseSize: UInt64
    let snapshotSize: UInt64
    let messageCount: Int
    let sessionCountsByProject: [(projectId: String, active: Int, archived: Int)]
    
    var databaseSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(databaseSize), countStyle: .file)
    }
    
    var snapshotSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(snapshotSize), countStyle: .file)
    }
    
    var totalSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(databaseSize + snapshotSize), countStyle: .file)
    }
    
    var totalActiveSessions: Int {
        sessionCountsByProject.reduce(0) { $0 + $1.active }
    }
    
    var totalArchivedSessions: Int {
        sessionCountsByProject.reduce(0) { $0 + $1.archived }
    }
}

// MARK: - CustomProvider Extension для работы с Keychain

extension CustomProvider {
    /// Получить API key из Keychain вместо plain storage.
    /// Fallback на plain apiKey для обратной совместимости после миграции.
    func getSecureAPIKey() -> String? {
        if let keychainKey = DatabaseBridge.shared.getProviderAPIKey(providerId: self.id) {
            return keychainKey
        }
        // Fallback to plain storage for backward compatibility
        return apiKey.isEmpty ? nil : apiKey
    }
}
