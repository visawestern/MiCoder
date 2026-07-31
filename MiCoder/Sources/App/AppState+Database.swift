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
        try? DatabaseManager.shared.archiveSessionsOlderThan(days: days)
        Task { @MainActor in
            await loadProjectsFromDatabase()
        }
    }
    
    /// Удалить все архивированные сессии
    func deleteArchivedSessions() -> Int {
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
        let count = (try? DatabaseManager.shared.deleteSessionsOlderThan(days: days)) ?? 0
        if count > 0 {
            try? DatabaseManager.shared.vacuum()
            Task { @MainActor in
                await loadProjectsFromDatabase()
            }
        }
        return count
    }
    
    /// Reset storage by explicit scope (plan Раздел 8 Блок 1 п.10 / Блок 2 п.19).
    /// Honest, predictable behavior: deletes exactly the planned paths, clears
    /// selection/navigation, and (for clearNoAutoImport) disables CLI auto-import.
    func resetStorage(scope: StorageResetScope) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let cliRoot = home.appendingPathComponent(".local/share")
        let plan = StorageResetLogic.plan(for: scope, homeDirectory: home, cliStorageRoot: cliRoot)

        // Delete exactly the planned paths.
        for path in plan.deletesPaths {
            try? FileManager.default.removeItem(atPath: path)
        }
        // Reinitialize the app database (recreates the cleared mimo.db).
        try? DatabaseManager.shared.reset()

        // Clear in-memory selection/navigation so nothing silently reappears.
        selectedSession = nil
        selectedWorkspace = nil
        sessions = []
        projects = []

        // Disable CLI auto-import globally for the no-auto-import scenario.
        if plan.disablesAutoImport {
            let all = ProjectRegistryLogic.load(homeDirectory: home)
                .map { entry -> ProjectRegistryEntry in
                    var e = entry; e.autoImportFromCLI = false; return e
                }
            try? ProjectRegistryLogic.save(all, homeDirectory: home)
        }

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
