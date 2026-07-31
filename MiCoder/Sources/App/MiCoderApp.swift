import SwiftUI
import Foundation
import AppKit
#if canImport(WebKit)
import WebKit
#endif

@main
struct MiCoderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 900, idealWidth: 1200, maxWidth: .infinity,
                       minHeight: 600, idealHeight: 750, maxHeight: .infinity)
                .background(Color.mimo.background)
        }
        .defaultSize(width: 1200, height: 750)
        .commands {
            CommandGroup(replacing: .pasteboard) {
                Button("Cut") {
                    NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("x", modifiers: .command)

                Button("Copy") {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("c", modifiers: .command)

                Button("Paste") {
                    _ = ChatPasteCoordinator.shared.performPaste()
                }
                .keyboardShortcut("v", modifiers: .command)

                Divider()

                // Replacing .pasteboard removes the standard Select All item;
                // re-add it or Cmd+A is dead in every text field.
                Button("Select All") {
                    NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("a", modifiers: .command)
            }
            CommandGroup(replacing: .newItem) {
                Button("New Task") {
                    appState.startNewTask(in: appState.selectedWorkspace)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandMenu("Find") {
                Button("Search Tasks…") {
                    appState.showSearch = true
                }
                .keyboardShortcut("k", modifiers: .command)
            }
            CommandMenu("Actions") {
                Button("Undo Last File Change") {
                    if let sessionID = appState.selectedSession?.id {
                        // Try per-project undo first (Round 7), fall back to legacy global undo
                        if let projectUndo = appState.projectUndoManager {
                            _ = try? projectUndo.undoMostRecent(sessionId: sessionID)
                        } else {
                            _ = try? UndoRedoManager.shared.undo(sessionId: sessionID)
                        }
                    }
                }
                .keyboardShortcut("z", modifiers: [.command, .option])
                .disabled(appState.selectedSession == nil)
            }
        }
    }
}

class AppState: ObservableObject {
    /// The UserDefaults instance used for persistence.  Public so tests can
    /// inject a dedicated instance (e.g. `UserDefaults(suiteName:)`) instead
    /// of racing on the shared `.standard` domain.
    var defaults: UserDefaults = .standard

    @Published var selectedProject: Project?
    @Published var selectedTask: TaskItem?
    @Published var projects: [Project] = []
    @Published var sessions: [ChatSession] = []
    @Published var selectedSession: ChatSession?
    @Published var showTerminal = false
    @Published var showGoal = false
    /// Monotonic counter; incremented to move keyboard focus into the message input.
    @Published var inputFocusRequest = 0
    /// Enable the in-input command palette dropdown (plan Раздел 6 Блок 3 п.30).
    @Published var inputDropdownEnabled = true
    @Published var showSearch = false
    @Published var showProjectCreation = false
    @Published var isStreaming = false
    @Published var isLoading = false
    @Published var selectedModel = ""
    @Published var selectedProviderID = ""
    @Published var maxTokens = true
    @Published var askBeforeChanges = true
    @Published var sidebarVisible = true
    
    @Published var serverConnected = false
    @Published var serverHost = "127.0.0.1"
    @Published var serverPort = 4096
    var availableModels: [String] {
        ProviderSettingsLogic.mergeModelIDs(
            serverProviders: serverProviders,
            customProviders: customProviders
        )
    }
    @Published var serverProviders: [MimoProviderResponse] = []
    @Published var customProviders: [CustomProvider] = []
    
    @Published var workspaces: [Workspace] = []
    private var isNavigatingHistory = false
    
    @Published var selectedWorkspace: Workspace? {
        didSet {
            DatabaseBridge.shared.setActiveProject(path: selectedWorkspace?.path)

            guard let workspace = selectedWorkspace else { return }
            guard !isNavigatingHistory else { return }
            
            if navigationHistory.isEmpty || navigationHistory.last?.id != workspace.id {
                // Atomically recompute the safe truncation point to avoid an
                // out-of-range removeSubrange when navigationIndex was mutated
                // by a concurrent didSet (Round 10 crash fix).
                if navigationIndex >= 0 && navigationIndex < navigationHistory.count {
                    let cutoff = navigationIndex + 1
                    if cutoff < navigationHistory.count {
                        navigationHistory.removeSubrange(cutoff..<navigationHistory.count)
                    } else {
                        navigationHistory = [navigationHistory[navigationIndex]]
                    }
                }
                navigationHistory.append(workspace)
                navigationIndex = navigationHistory.count - 1
            }
        }
    }
    @Published var navigationHistory: [Workspace] = []
    @Published var navigationIndex: Int = -1

    /// Reset navigation to a safe state (used when the workspace is cleared,
    /// e.g. during a storage reset) so the UI can't observe an out-of-bounds
    /// index into navigationHistory. Internal so extensions (AppState+Database)
    /// can call it.
    func clearNavigationHistory() {
        navigationHistory = []
        navigationIndex = -1
    }
    @Published var settings = AppSettings.load() {
        didSet {
            settings.save()
        }
    }

    var appLanguage: AppLanguage {
        AppLanguage.from(stored: settings.language)
    }

    func updateSettings(_ mutate: (inout AppSettings) -> Void) {
        var copy = settings
        mutate(&copy)
        settings = copy
    }

    func setLanguage(_ language: AppLanguage) {
        updateSettings { $0.language = language.rawValue }
    }
    @Published var accessLevel: AccessLevel = .askBeforeChanges {
        didSet {
            guard !isSyncingAccessLevel else { return }
            defaults.set(accessLevel.rawValue, forKey: "com.micoder.accessLevel")
            Task { await applyAccessLevelToServer() }
        }
    }
    @Published var selectedVariant: String = "high" {
        didSet {
            defaults.set(selectedVariant, forKey: "com.micoder.selectedVariant")
        }
    }
    @Published var agentMode: AgentMode = .build {
        didSet {
            defaults.set(agentMode.rawValue, forKey: "com.micoder.agentMode")
        }
    }
    @Published var showSettings = false
    @Published var showRemoteConnection = false
    @Published var settingsTab: SettingsTab = .general
    @Published var currentSteps: [TaskStep] = []
    @Published var pendingQuestionRequest: PendingQuestionRequest?
    @Published var vcsChanges: [MimoVcsFileDiff] = []
    @Published var sessionGitTotals = SessionGitTotals(additions: 0, deletions: 0)
    @Published var gitBranch = "main"
    @Published var gitBranches: [String] = []
    @Published var gitStatusMessage: String?
    @Published var isGitBusy = false
    @Published var gitRepositoryPath: String?
    @Published var workspaceSortOrder: WorkspaceSortOrder = .recentUse
    @Published var workspaceViewMode: WorkspaceViewMode = .list
    @Published var workspaceFilterQuery: String = ""
    @Published var workspaceFilterPreset: WorkspaceFilterPreset = .all
    @Published var showWorkspaceSearchField = false
    @Published var workspacesSectionExpanded = true
    /// Sidebar Group/Project pill mode (plan Раздел 11 Блок 2).
    @Published var sidebarGroupingMode: SidebarGroupingMode = SidebarGroupingLogic.load() {
        didSet { SidebarGroupingLogic.save(sidebarGroupingMode) }
    }
    /// Quick archive popover from the sidebar (plan Раздел 11 Блок 2 п.16).
    @Published var showArchivePopover = false
    @Published var showNotifications = false
    @Published var showWorkspacesOverview = false
    @Published var showBranchPicker = false
    @Published var notificationService = NotificationService()
    
    var displayedWorkspaces: [Workspace] {
        let nameFiltered = SidebarWorkspaceLogic.filtered(workspaces, query: workspaceFilterQuery)
        let sessionFiltered = SidebarWorkspaceLogic.filteredBySessionCount(nameFiltered, sessions: sessions, preset: workspaceFilterPreset)
        return SidebarWorkspaceLogic.sorted(sessionFiltered, order: workspaceSortOrder, sessions: sessions)
    }
    
    var userDisplayName: String { UserProfileDisplay.displayName() }
    var userInitials: String { UserProfileDisplay.initials(from: userDisplayName) }
    @Published var appTheme: AppTheme = .dark {
        didSet {
            defaults.set(appTheme.rawValue, forKey: "com.micoder.theme")
            Color.mimo.setTheme(appTheme)
        }
    }
    
    var mimoClient: MimoServeClient
    private var isSyncingAccessLevel = false
    private let gitRefreshCoalescer = GitRefreshCoalescer()
    private var gitBusyCount = 0
    
    // Database integration
    private var dbBridge: DatabaseBridge {
        DatabaseBridge.shared
    }

    /// Per-project undo manager, created lazily when a workspace is active.
    /// Replaces the legacy global `UndoRedoManager` (Round 7).
    var projectUndoManager: ProjectUndoManager? {
        guard let path = selectedWorkspace?.path else { return nil }
        return try? ProjectUndoManager(projectPath: path)
    }
    
    // MiMo Serve connection manager (now optional)
    @Published var serverConnectionManager: MimoServeConnectionManager?

    init(host: String = "127.0.0.1", port: Int = 4096, defaults: UserDefaults = .standard) {
        self.serverHost = host
        self.serverPort = port
        self.mimoClient = MimoServeClient(host: host, port: port)
        self.serverConnectionManager = MimoServeConnectionManager(client: mimoClient)
        self.defaults = defaults

        // Load persisted values from the injected defaults domain
        selectedModel = defaults.string(forKey: "com.micoder.selectedModel") ?? ""
        selectedProviderID = defaults.string(forKey: "com.micoder.selectedProviderID") ?? ""
        selectedVariant = {
            if let saved = defaults.string(forKey: "com.micoder.selectedVariant"), !saved.isEmpty {
                return saved
            }
            let legacy = defaults.string(forKey: "com.micoder.thinkingLevel") ?? ""
            return ProviderSettingsLogic.migrateLegacyThinkingLevel(legacy) ?? "high"
        }()
        agentMode = {
            let raw = defaults.string(forKey: "com.micoder.agentMode") ?? ""
            return AgentMode(rawValue: raw) ?? .build
        }()
        accessLevel = {
            let raw = defaults.string(forKey: "com.micoder.accessLevel") ?? ""
            return AccessLevelPermissionLogic.migrateLegacyAccessLevel(raw: raw)
        }()
        appTheme = {
            let raw = defaults.string(forKey: "com.micoder.theme") ?? ""
            return AppTheme(rawValue: raw) ?? .dark
        }()
        // settings is already loaded by its own didSet-based persistence

        migrateLegacyPreferences()

        // One-time rebrand data migration ~/.mimocode -> ~/.micoder (Раздел 13 п.11).
        // Runs at most once, never overwrites newer data.
        _ = try? LegacyDataMigrator.migrate(
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser,
            defaults: defaults
        )

        // Initialize database and perform migrations
        Task {
            await initializeDatabase()
            // Attempt server connection (non-blocking)
            serverConnectionManager?.attemptConnection()
        }
    }

    private func migrateLegacyPreferences() {
        let rawAccess = defaults.string(forKey: "com.micoder.accessLevel") ?? ""
        if AccessLevelPermissionLogic.shouldSwitchToPlanAgent(legacyRaw: rawAccess) {
            agentMode = .plan
            defaults.set(AgentMode.plan.rawValue, forKey: "com.micoder.agentMode")
            defaults.set(AccessLevel.askBeforeChanges.rawValue, forKey: "com.micoder.accessLevel")
        }
    }
    
    func connectToServer() async {
        // Non-blocking connection check
        await serverConnectionManager?.checkAvailability()
        
        if serverConnectionManager?.isConnected == true {
            await syncAccessLevelFromServer()
        }
    }
    
    func loadSessionsFromServer() async {
        // Sessions come from the local DB, then optionally from a server the
        // user is already running on localhost. We NEVER spawn a `mimo` CLI or
        // launch `mimo serve` ourselves — the app is fully decoupled from MiMo.
        // 1. Load from the local database.
        await loadProjectsFromDatabase()

        // 2. Optionally sync with a server if the user has one running.
        if serverConnectionManager?.isConnected == true {
            let adapter = ServerToLocalMigrationAdapter(client: mimoClient)
            if let workspace = selectedWorkspace {
                let syncedSessions = await adapter.loadSessions(projectId: workspace.id)
                await MainActor.run {
                    if !syncedSessions.isEmpty {
                        self.sessions = syncedSessions
                    }
                }
            }
        }
    }
    
    func loadModelsFromServer() async {
        do {
            let providers = try await mimoClient.providers()
            await MainActor.run {
                self.serverProviders = providers
                self.validateAndReconcileSelections()
            }
        } catch {
            print("Failed to load models: \(error)")
        }
    }

    var providerOptions: [ProviderOption] {
        var options = ProviderSettingsLogic.allProviderOptions(
            serverProviders: serverProviders,
            customProviders: customProviders
        )
        // Local providers (Ollama/OpenCode/MiMo CLI) — plan Раздел 1.
        options += LocalProviderLogic.providerOptions(from: LocalProviderLogic.load())
        // Connected web providers (only after cookies captured) — plan Раздел 13 п.4.
        options += WebProviderConnectivity.providerOptions(
            WebProviderStore.load(),
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser
        )
        return options
    }

    var modelsForSelectedProvider: [String] {
        // Web provider selected → its real (discovered) models (plan Раздел 13 п.4).
        if let webID = WebProviderConnectivity.configID(fromOptionID: selectedProviderID),
           let cfg = WebProviderStore.load().first(where: { $0.id == webID }) {
            return WebProviderConnectivity.models(for: cfg)
        }
        // Local provider selected → its loaded models.
        if let local = LocalProviderLogic.load().first(where: { $0.id == selectedProviderID }) {
            return local.models
        }
        return ProviderSettingsLogic.models(
            for: selectedProviderID,
            in: serverProviders,
            customProviders: customProviders
        )
    }

    var supportsToolcallForSelection: Bool {
        ProviderCapabilityGates.canUseTools(
            modelID: selectedModel,
            providerID: selectedProviderID.isEmpty ? nil : selectedProviderID,
            providers: serverProviders,
            customProviders: customProviders
        )
    }

    /// The provider the user explicitly picked; survives fallbacks while the
    /// provider is offline and is restored once it reappears.
    var preferredProviderID: String {
        defaults.string(forKey: "com.micoder.preferredProviderID")
            ?? defaults.string(forKey: "com.micoder.selectedProviderID")
            ?? ""
    }

    var preferredModelID: String {
        defaults.string(forKey: "com.micoder.preferredModelID")
            ?? defaults.string(forKey: "com.micoder.selectedModel")
            ?? ""
    }

    func selectProvider(_ providerID: String, persistPreference: Bool = true) {
        selectedProviderID = providerID
        defaults.set(providerID, forKey: "com.micoder.selectedProviderID")
        if persistPreference {
            defaults.set(providerID, forKey: "com.micoder.preferredProviderID")
        }

        let result = ProviderSelectionLogic.cascade(
            to: providerID,
            currentModelID: selectedModel,
            currentVariant: selectedVariant.isEmpty ? nil : selectedVariant,
            serverProviders: serverProviders,
            customProviders: customProviders
        )
        selectedModel = result.modelID
        defaults.set(result.modelID, forKey: "com.micoder.selectedModel")
        selectedVariant = result.variant ?? ""

        if agentMode == .plan,
           !ProviderCapabilityGates.canSelectPlanAgent(
               modelID: selectedModel,
               providerID: providerID,
               providers: serverProviders,
               customProviders: customProviders
           ) {
            agentMode = .build
        }
    }

    func selectModel(_ modelID: String, persistPreference: Bool = true) {
        guard modelsForSelectedProvider.contains(modelID) else { return }
        selectedModel = modelID
        defaults.set(modelID, forKey: "com.micoder.selectedModel")
        if persistPreference {
            defaults.set(modelID, forKey: "com.micoder.preferredModelID")
        }
        selectedVariant = ProviderSettingsLogic.normalizedVariant(
            selectedVariant.isEmpty ? nil : selectedVariant,
            for: modelID,
            in: serverProviders,
            providerID: selectedProviderID.isEmpty ? nil : selectedProviderID,
            customProviders: customProviders
        ) ?? ""
    }

    func validateAndReconcileSelections() {
        let options = providerOptions
        if options.isEmpty {
            if selectedProviderID.isEmpty, let firstServer = serverProviders.first {
                selectProvider(firstServer.id, persistPreference: false)
            }
            return
        }

        // Restore the user's explicit choice as soon as it is available again.
        if let restored = SelectionRestoreLogic.resolvedProviderID(
            preferred: preferredProviderID,
            current: selectedProviderID,
            options: options.map(\.id)
        ) {
            selectProvider(restored, persistPreference: false)
            restorePreferredModelIfAvailable()
            return
        }

        if selectedProviderID.isEmpty || !options.contains(where: { $0.id == selectedProviderID }) {
            // Temporary fallback — must not overwrite the stored preference.
            selectProvider(options[0].id, persistPreference: false)
            return
        }

        restorePreferredModelIfAvailable()

        let result = ProviderSelectionLogic.cascade(
            to: selectedProviderID,
            currentModelID: selectedModel,
            currentVariant: selectedVariant.isEmpty ? nil : selectedVariant,
            serverProviders: serverProviders,
            customProviders: customProviders
        )
        selectedModel = result.modelID
        defaults.set(result.modelID, forKey: "com.micoder.selectedModel")
        selectedVariant = result.variant ?? ""
    }

    private func restorePreferredModelIfAvailable() {
        if let restoredModel = SelectionRestoreLogic.resolvedModelID(
            preferred: preferredModelID,
            current: selectedModel,
            options: modelsForSelectedProvider
        ) {
            selectModel(restoredModel, persistPreference: false)
        }
    }

    var availableVariantsForSelectedModel: [String] {
        ProviderSettingsLogic.availableVariants(
            for: selectedModel,
            in: serverProviders,
            providerID: selectedProviderID.isEmpty ? nil : selectedProviderID,
            customProviders: customProviders
        )
    }

    var supportsReasoningForSelectedModel: Bool {
        ProviderSettingsLogic.supportsReasoning(
            for: selectedModel,
            in: serverProviders,
            providerID: selectedProviderID.isEmpty ? nil : selectedProviderID,
            customProviders: customProviders
        )
    }

    /// Whether the currently selected provider is an ACP-enabled custom provider.
    var isSelectedACPProvider: Bool {
        guard let custom = customProviders.first(where: { $0.id == selectedProviderID }) else {
            return false
        }
        return custom.type == .acp && custom.acpEnabled
    }

    /// Returns an `ACPClient` for the currently selected ACP provider, or nil.
    var acpClient: ACPClient? {
        guard isSelectedACPProvider,
              let custom = customProviders.first(where: { $0.id == selectedProviderID }),
              let url = URL(string: custom.baseURL) else {
            return nil
        }
        let key = custom.apiKey
        return ACPClient(baseURL: url, apiKey: key)
    }

    func applySendSelections(_ selections: SessionSendSelections) {
        if let agentMode = selections.agentMode {
            self.agentMode = agentMode
        }
        if let providerID = selections.providerID, !providerID.isEmpty {
            if providerOptions.contains(where: { $0.id == providerID }) {
                selectProvider(providerID)
            }
        }
        if let modelID = selections.modelID, !modelID.isEmpty {
            if modelsForSelectedProvider.contains(modelID) {
                selectModel(modelID)
            } else if providerOptions.contains(where: { $0.id == selections.providerID ?? selectedProviderID }) {
                selectModel(modelID)
            }
        }
        if let variant = selections.variant, !variant.isEmpty {
            selectedVariant = ProviderSettingsLogic.normalizedVariant(
                variant,
                for: selectedModel,
                in: serverProviders,
                providerID: selectedProviderID.isEmpty ? nil : selectedProviderID,
                customProviders: customProviders
            ) ?? variant
        }
        if agentMode == .plan,
           !ProviderCapabilityGates.canSelectPlanAgent(
               modelID: selectedModel,
               providerID: selectedProviderID.isEmpty ? nil : selectedProviderID,
               providers: serverProviders,
               customProviders: customProviders
           ) {
            agentMode = .build
        }
    }

    func applyAccessLevelToServer() async {
        guard serverConnected else { return }
        let patch: [String: Any] = [
            "permission": AccessLevelPermissionLogic.permissionPatch(for: accessLevel)
        ]
        do {
            _ = try await mimoClient.updateGlobalConfig(patch)
        } catch {
            print("Failed to update permission config: \(error)")
        }
    }

    func syncAccessLevelFromServer() async {
        do {
            let config = try await mimoClient.globalConfig()
            let mapped = AccessLevelPermissionLogic.accessLevel(from: config.permission?.asDictionary)
            await MainActor.run {
                isSyncingAccessLevel = true
                self.accessLevel = mapped
                isSyncingAccessLevel = false
            }
        } catch {
            print("Failed to sync access level: \(error)")
        }
    }
    
    func navigateBack() {
        guard navigationIndex > 0 else { return }
        navigationIndex -= 1
        let ws = navigationHistory[navigationIndex]
        isNavigatingHistory = true
        selectedWorkspace = ws
        isNavigatingHistory = false
    }

    func navigateForward() {
        guard navigationIndex < navigationHistory.count - 1 else { return }
        navigationIndex += 1
        let ws = navigationHistory[navigationIndex]
        isNavigatingHistory = true
        selectedWorkspace = ws
        isNavigatingHistory = false
    }

    var canNavigateBack: Bool {
        navigationIndex > 0 && navigationIndex < navigationHistory.count
    }

    var canNavigateForward: Bool {
        navigationIndex < navigationHistory.count - 1 && navigationIndex >= 0 && navigationHistory.count > 0
    }
    
    func addCustomProvider(_ provider: CustomProvider) {
        // Save API key to Keychain and clear plain storage before saving to UserDefaults
        if !provider.apiKey.isEmpty {
            DatabaseBridge.shared.saveProviderAPIKey(providerId: provider.id, apiKey: provider.apiKey)
        }
        var cleanProvider = provider
        cleanProvider.apiKey = ""
        if let index = customProviders.firstIndex(where: { $0.id == provider.id }) {
            customProviders[index] = cleanProvider
        } else {
            customProviders.append(cleanProvider)
        }
        saveCustomProviders()
        if provider.isEnabled {
            loadModelsFromCustomProvider(provider)
        }
    }
    
    func removeCustomProvider(_ provider: CustomProvider) {
        DatabaseBridge.shared.deleteProviderAPIKey(providerId: provider.id)
        customProviders.removeAll { $0.id == provider.id }
        saveCustomProviders()
        validateAndReconcileSelections()
    }

    func updateCustomProvider(_ updated: CustomProvider) {
        guard let index = customProviders.firstIndex(where: { $0.id == updated.id }) else { return }
        // Save API key to Keychain and clear plain storage
        if !updated.apiKey.isEmpty {
            DatabaseBridge.shared.saveProviderAPIKey(providerId: updated.id, apiKey: updated.apiKey)
        }
        var cleanProvider = updated
        cleanProvider.apiKey = ""
        customProviders[index] = cleanProvider
        saveCustomProviders()
        if updated.isEnabled {
            loadModelsFromCustomProvider(updated)
        }
        validateAndReconcileSelections()
    }

    func testProvider(url: String, apiKey: String, type: ProviderType) async -> Bool {
        guard let testURL = URL(string: "\(url)/models") else { return false }
        var request = URLRequest(url: testURL)
        request.timeoutInterval = 10
        
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    private func loadModelsFromCustomProvider(_ provider: CustomProvider) {
        // Custom providers are stored locally and merged into the picker only.
        // MiMo Serve reads provider credentials from mimocode.json on disk; this
        // app does not push custom provider config to the server API.
        Task {
            guard let url = URL(string: "\(provider.baseURL)/models") else { return }
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            // Use Keychain-backed API key if available, fall back to plain storage
            let apiKey = provider.getSecureAPIKey() ?? ""
            if !apiKey.isEmpty {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let data = json["data"] as? [[String: Any]] {
                    let models = data.compactMap { $0["id"] as? String }
                    await MainActor.run {
                        if let index = customProviders.firstIndex(where: { $0.id == provider.id }) {
                            customProviders[index].models = models
                        }
                        if selectedProviderID == provider.id || selectedProviderID.isEmpty {
                            validateAndReconcileSelections()
                        }
                    }
                }
            } catch {
                print("Failed to load models from \(provider.name): \(error)")
            }
        }
    }
    
    private func saveCustomProviders() {
        // Strip apiKey fields before saving to UserDefaults — keys live in Keychain
        let cleanProviders = customProviders.map { provider -> CustomProvider in
            var clean = provider
            clean.apiKey = ""
            return clean
        }
        if let data = try? JSONEncoder().encode(cleanProviders) {
            defaults.set(data, forKey: "com.micoder.customProviders")
        }
    }
    
    /// Current session goal, shown in the TopBar (plan Раздел 5 Блок 1 п.9).
    #if canImport(WebKit)
    /// Persistent web views per web provider so the authenticated session is
    /// reused across turns (plan Раздел 12).
    private var webViews: [String: WKWebView] = [:]
    func webView(for config: WebProviderConfig) -> WKWebView {
        if let existing = webViews[config.id] { return existing }
        let wv = WKWebView(frame: .zero)
        webViews[config.id] = wv
        return wv
    }
    #endif

    /// Web providers whose chat session has already been seeded with the tool
    /// preamble this app run — so we send the preamble only on the first turn
    /// (audit P2). Reset when the session is (re)started/logged out.
    private var webSessionStarted: Set<String> = []
    func webSessionIsFirstTurn(_ providerID: String) -> Bool { !webSessionStarted.contains(providerID) }
    func markWebSessionStarted(_ providerID: String) { webSessionStarted.insert(providerID) }
    func resetWebSession(_ providerID: String) { webSessionStarted.remove(providerID) }

    /// Ids of enabled local providers (for send-routing / readiness checks).
    var localProviderIDs: [String] {
        LocalProviderLogic.load().filter { $0.isEnabled }.map { $0.id }
    }
    /// Ids of configured web providers (for send-routing / readiness checks).
    var webProviderIDs: [String] {
        WebProviderStore.load().map { $0.id }
    }

    var currentSessionGoal: String? { selectedSession?.sessionGoal }

    /// Set the goal on the selected session, persist in-memory and to the DB
    /// so it survives restarts (plan Раздел 5 Блок 1 п.10).
    func setCurrentSessionGoal(_ goal: String) {
        guard var session = selectedSession else { return }
        let value = goal.isEmpty ? nil : goal
        session.sessionGoal = value
        selectedSession = session
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx].sessionGoal = value
        }
        try? DatabaseManager.shared.setSessionGoal(sessionId: session.id, goal: value)
    }

    /// Build the data context for the in-input command dropdown (plan Раздел 6).
    /// Cached project file list for `@` mentions (audit P12).
    private var projectFilesCache: ProjectFilesCacheState?

    func inputDropdownContext() -> InputDropdownDataSource.Context {
        let skills = AgentResourcesLoader.loadSkills().map { $0.name }
        let sessionTitles = sessions.map { $0.title }
        let path = selectedWorkspace?.path ?? ""
        // Real project files for `@` — scan (cached, TTL) instead of empty list.
        if ProjectFilesCacheLogic.needsRescan(cache: projectFilesCache, currentPath: path) {
            let names = ProjectFileScanner.scan(root: path).map { $0.path }
            projectFilesCache = ProjectFilesCacheState(projectPath: path, fileNames: names, scannedAt: Date())
        }
        let fileNames = ProjectFilesCacheLogic.fileNames(cache: projectFilesCache, currentPath: path)
        return InputDropdownDataSource.Context(
            commands: SlashCommandRegistry.allCommands(),
            installedSkills: skills,
            fileNames: fileNames,
            sessionTitles: sessionTitles
        )
    }

    func loadCustomProviders() {
        if let data = defaults.data(forKey: "com.micoder.customProviders"),
           let providers = try? JSONDecoder().decode([CustomProvider].self, from: data) {
            customProviders = providers
            // Restore apiKey from Keychain for any provider that has been migrated
            for i in customProviders.indices {
                if customProviders[i].apiKey.isEmpty {
                    if let keychainKey = DatabaseBridge.shared.getProviderAPIKey(providerId: customProviders[i].id) {
                        customProviders[i].apiKey = keychainKey
                    }
                }
            }
        }
        for provider in customProviders where provider.isEnabled {
            loadModelsFromCustomProvider(provider)
        }
    }
    
    func connectToServe(hostname: String, port: Int) async {
        let newClient = MimoServeClient(host: hostname, port: port)
        
        await MainActor.run {
            self.serverHost = hostname
            self.serverPort = port
            self.mimoClient = newClient
        }
        
        do {
            let health = try await newClient.health()
            await MainActor.run {
                self.serverConnected = health.healthy
                if health.healthy {
                    self.notificationService.serverConnected()
                }
            }
            if health.healthy {
                await loadModelsFromServer()
                await syncAccessLevelFromServer()
            }
        } catch {
            print("Connection failed: \(error)")
            await MainActor.run {
                self.serverConnected = false
                self.notificationService.serverDisconnected()
            }
        }
    }
    
    func stopServe() {
        serverConnected = false
        notificationService.serverDisconnected()
        serverProviders = []
        if !customProviders.contains(where: { $0.id == selectedProviderID && $0.isEnabled }) {
            if let firstCustom = customProviders.first(where: { $0.isEnabled }) {
                selectProvider(firstCustom.id)
            } else {
                selectedProviderID = ""
                selectedModel = ""
                selectedVariant = ""
                defaults.set("", forKey: "com.micoder.selectedProviderID")
                defaults.set("", forKey: "com.micoder.selectedModel")
            }
        } else {
            validateAndReconcileSelections()
        }
    }
    
    func sessions(for workspace: Workspace) -> [ChatSession] {
        sessions
            .filter { $0.belongs(to: workspace) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func selectSession(_ session: ChatSession) {
        selectedSession = session
        if let workspace = workspaces.first(where: { session.belongs(to: $0) }) {
            selectedWorkspace = workspace
        }
        if SessionContextLoader.shouldOpenRightPanel(for: session) {
            showGoal = true
        }
        currentSteps = []
        vcsChanges = []
        sessionGitTotals = SessionGitTotals(additions: 0, deletions: 0)
        scheduleGitRefresh(sessionID: session.id)
        
        // Unarchive session if it was archived (so user can resume chatting)
        Task {
            try? DatabaseManager.shared.unarchiveSession(id: session.id)
        }
    }

    func scheduleGitRefresh(sessionID explicitSessionID: String? = nil) {
        Task { [weak self] in
            guard let self else { return }
            let sessionID = await MainActor.run {
                GitRefreshScheduler.resolvedSessionID(
                    explicit: explicitSessionID,
                    selected: self.selectedSession?.id
                )
            }
            if let sessionID {
                await self.loadSessionContext(sessionID: sessionID)
            } else {
                _ = await self.refreshGitFromLocal()
            }
        }
    }

    func loadSessionContext(sessionID: String) async {
        let context = await MainActor.run { () -> (directory: String?, summary: MimoSessionSummary?) in
            let session = self.sessions.first(where: { $0.id == sessionID }) ?? self.selectedSession
            let directory = SessionContextLoader.gitDirectoryPath(
                workspacePath: self.selectedWorkspace?.path,
                sessionDirectory: session?.directory
            )
            return (directory, session?.gitSummary)
        }

        let localResult = await refreshGitFromLocal(directory: context.directory)

        let shouldFetchRemote = SessionContextLoader.shouldFetchRemoteGit(
            localChangeCount: localResult.changeCount,
            localGitFailed: localResult.failed
        )
        guard shouldFetchRemote else { return }

        do {
            let diff = try await mimoClient.vcsDiff(directory: context.directory, mode: .git)
            let totals = SessionContextLoader.gitTotals(vcsFiles: diff.files, sessionSummary: context.summary)
            await MainActor.run {
                self.vcsChanges = diff.files
                self.sessionGitTotals = totals
                self.gitStatusMessage = nil
            }
        } catch {
            await MainActor.run {
                if let summary = context.summary {
                    self.sessionGitTotals = SessionContextLoader.gitTotals(vcsFiles: [], sessionSummary: summary)
                }
            }
            print("Failed to load session git context: \(error)")
        }
    }

    struct GitRefreshResult {
        let changeCount: Int
        let failed: Bool
    }

    @discardableResult
    func refreshGitFromLocal(directory: String? = nil) async -> GitRefreshResult {
        let key = directory ?? "__default__"
        return await gitRefreshCoalescer.run(key: key) {
            await self.performRefreshGitFromLocal(directory: directory)
        }
    }

    private func performRefreshGitFromLocal(directory: String?) async -> GitRefreshResult {
        let resolvedDirectory = await MainActor.run { () -> String? in
            if let directory {
                return directory
            }
            return SessionContextLoader.gitDirectoryPath(
                workspacePath: self.selectedWorkspace?.path,
                sessionDirectory: self.selectedSession?.directory
            )
        }

        guard let workspacePath = resolvedDirectory else {
            await MainActor.run {
                gitRepositoryPath = nil
            }
            return GitRefreshResult(changeCount: 0, failed: true)
        }

        await beginGitBusy()
        defer { Task { await self.endGitBusy() } }

        let snapshot = await Task.detached(priority: .utility) { () -> (result: GitRefreshResult, payload: GitRefreshPayload?) in
            do {
                let root = try GitRepository.repositoryRoot(for: workspacePath)
                let branch = try GitRepository.currentBranch(in: root)
                let branches = try GitRepository.branches(in: root)
                let localChanges = try GitRepository.workingTreeChanges(in: root)
                let vcs = GitRepository.toVcsFileDiffs(localChanges)
                return (
                    GitRefreshResult(changeCount: vcs.count, failed: false),
                    GitRefreshPayload(
                        root: root,
                        branch: branch,
                        branches: branches,
                        vcs: vcs,
                        errorMessage: nil
                    )
                )
            } catch {
                return (
                    GitRefreshResult(changeCount: 0, failed: true),
                    GitRefreshPayload(
                        root: nil,
                        branch: nil,
                        branches: nil,
                        vcs: nil,
                        errorMessage: error.localizedDescription
                    )
                )
            }
        }.value

        await MainActor.run {
            if let payload = snapshot.payload, let root = payload.root, let branch = payload.branch,
               let branches = payload.branches, let vcs = payload.vcs {
                self.gitRepositoryPath = root
                self.gitBranch = branch
                self.gitBranches = branches
                self.vcsChanges = vcs
                self.sessionGitTotals = SessionContextLoader.gitTotals(vcsFiles: vcs, sessionSummary: nil)
                self.gitStatusMessage = nil
                self.updateWorkspaceBranch(branch)
            } else if let message = snapshot.payload?.errorMessage {
                self.gitStatusMessage = message
            }
        }

        return snapshot.result
    }

    private struct GitRefreshPayload {
        let root: String?
        let branch: String?
        let branches: [String]?
        let vcs: [MimoVcsFileDiff]?
        let errorMessage: String?
    }

    private func beginGitBusy() async {
        await MainActor.run {
            gitBusyCount += 1
            isGitBusy = true
        }
    }

    private func endGitBusy() async {
        await MainActor.run {
            gitBusyCount = max(0, gitBusyCount - 1)
            isGitBusy = gitBusyCount > 0
        }
    }

    @discardableResult
    func commitGitChanges(message: String) async -> Bool {
        guard let repoPath = gitRepositoryPath ?? selectedWorkspace.flatMap({ try? GitRepository.repositoryRoot(for: $0.path) }) else {
            await MainActor.run { gitStatusMessage = "No git repository for this workspace" }
            return false
        }

        await beginGitBusy()
        await MainActor.run { gitStatusMessage = nil }
        defer { Task { await self.endGitBusy() } }

        do {
            let result = try await Task.detached(priority: .utility) {
                try GitRepository.commitAll(in: repoPath, message: message)
            }.value
            await MainActor.run {
                gitStatusMessage = result.output.isEmpty ? "Committed successfully" : result.output
                notificationService.gitOperationComplete(operation: "Commit", details: message.prefix(80).description)
            }
            await refreshGitFromLocal()
            return true
        } catch {
            await MainActor.run {
                gitStatusMessage = error.localizedDescription
            }
            return false
        }
    }

    func pushGitChanges() async {
        guard let repoPath = gitRepositoryPath else {
            await MainActor.run { gitStatusMessage = "No git repository for this workspace" }
            return
        }

        await beginGitBusy()
        await MainActor.run { gitStatusMessage = nil }
        defer { Task { await self.endGitBusy() } }

        do {
            let result = try await Task.detached(priority: .utility) {
                try GitRepository.push(in: repoPath)
            }.value
            await MainActor.run {
                gitStatusMessage = result.output.isEmpty ? "Pushed successfully" : result.output
                notificationService.gitOperationComplete(operation: "Push", details: result.output.isEmpty ? "Changes pushed to remote" : result.output)
            }
        } catch {
            await MainActor.run {
                gitStatusMessage = error.localizedDescription
            }
        }
    }

    func checkoutGitBranch(_ branch: String) async {
        guard let repoPath = gitRepositoryPath else { return }

        await beginGitBusy()
        defer { Task { await self.endGitBusy() } }

        do {
            _ = try await Task.detached(priority: .utility) {
                try GitRepository.checkout(branch: branch, in: repoPath)
            }.value
            await refreshGitFromLocal()
            await MainActor.run {
                gitStatusMessage = "Switched to \(branch)"
            }
        } catch {
            await MainActor.run {
                gitStatusMessage = error.localizedDescription
            }
        }
    }

    private func updateWorkspaceBranch(_ branch: String) {
        guard var workspace = selectedWorkspace else { return }
        workspace.branch = branch
        selectedWorkspace = workspace
        if let index = workspaces.firstIndex(where: { $0.id == workspace.id }) {
            workspaces[index].branch = branch
        }
        if var session = selectedSession {
            session.branch = branch
            selectedSession = session
            if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                sessions[index].branch = branch
            }
        }
    }

    func applySessionPlan(from serverMessages: [MimoMessageResponse]) {
        let steps = SessionPlanParser.steps(from: serverMessages)
        if !steps.isEmpty {
            currentSteps = steps
        }
    }
    
    func startNewTask(in workspace: Workspace? = nil) {
        if let workspace {
            selectedWorkspace = workspace
        }
        selectedSession = nil
        selectedTask = nil
        isLoading = false
        isStreaming = false
        currentSteps = []
        vcsChanges = []
        sessionGitTotals = SessionGitTotals(additions: 0, deletions: 0)
        showGoal = false
        inputFocusRequest += 1
    }
    
    func openSkillsSettings() {
        settingsTab = .skills
        showSettings = true
    }
    
    func openFolderInFinder(_ path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
    }
    
    func openSettings() {
        showSettings = true
    }
    
    func upsertSession(_ session: ChatSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.insert(session, at: 0)
        }
        selectedSession = session
    }
    
    func registerSessionFromServer(id: String, title: String, directory: String) {
        let session = ChatSession(
            id: id,
            title: title,
            directory: directory,
            branch: selectedWorkspace?.branch
        )
        upsertSession(session)
    }
    
    @discardableResult
    func addWorkspace(path: String, branch: String? = nil) -> Workspace {
        let normalized = ChatSession.normalizedPath(path)
        if let existing = workspaces.first(where: { ChatSession.normalizedPath($0.path) == normalized }) {
            selectedWorkspace = existing
            return existing
        }
        
        let workspace = Workspace(
            id: UUID().uuidString,
            name: (normalized as NSString).lastPathComponent,
            path: normalized,
            branch: branch,
            tasks: []
        )
        workspaces.append(workspace)
        selectedWorkspace = workspace
        return workspace
    }
    
    /// Создать новый проект: добавляет workspace и сохраняет в БД
    @MainActor
    func createNewProject(name: String, path: String) {
        let projectId = UUID().uuidString
        let normalizedPath = ChatSession.normalizedPath(path)
        
        // Сохраняем в БД
        createOrUpdateProject(id: projectId, name: name, path: normalizedPath)
        
        // Добавляем workspace если его ещё нет
        addWorkspace(path: normalizedPath)
    }
}
