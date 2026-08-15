import SwiftUI
import Foundation
import AppKit
#if canImport(WebKit)
import WebKit
#endif

/// Global reference for local API server access. Set during app startup.
var __miCoderAppState: AppState?

@main
struct MiCoderApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    __miCoderAppState = appState
                    MiCoderAPIServer.shared.start()
                }
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
                    appState.undoLastAction()
                }
                .keyboardShortcut("z", modifiers: [.command, .option])
                .disabled(appState.selectedSession == nil)
            }
        }
    }
}

class AppState: ObservableObject {
    let instanceID = UUID().uuidString.prefix(8)
    deinit {
        if let observer = autoFreeSwitchObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        MiCoderAPIServer.appendLog("💀 AppState.deinit: id=\(instanceID)")
    }
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
    @Published private(set) var providerConnectivity: [String: Bool] = [:]
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
    /// Per-provider result of the last model refresh. Exposed in Settings so a
    /// bad URL, authentication failure, or unsupported response is actionable
    /// instead of looking like a mysterious empty model list.
    @Published private(set) var providerModelLoadMessages: [String: String] = [:]
    
    @Published var workspaces: [Workspace] = []
    /// Lightweight registry snapshot used to reconcile sidebar visibility with
    /// Storage archive actions without hiding an unknown legacy workspace.
    @Published private(set) var projectRegistryEntries: [ProjectRegistryEntry] = []
    private var isNavigatingHistory = false
    /// Pending message from local API. ChatPanelView observes this to trigger sends.
    @Published var apiPendingMessage: String?
    
    /// Guards navigationHistory/navigationIndex mutations. The `selectedWorkspace`
    /// didSet can fire from any thread (tests, background init tasks), so the
    /// truncate+append must be atomic or removeSubrange races into an
    /// out-of-range fatal error (Round 10 crash, still reproduced under parallel
    /// test runs — now fixed with a real lock, not just a bounds check).
    private let navigationLock = NSLock()
    
    @Published var selectedWorkspace: Workspace? {
        didSet {
            if ProjectFileIndexWatcherLifecycleLogic.shouldRestart(
                oldProjectPath: oldValue?.path,
                newProjectPath: selectedWorkspace?.path
            ) {
                updateProjectFileIndexWatcher(for: selectedWorkspace)
            }
            guard let workspace = selectedWorkspace else { return }

            // E04 (Раздел 8 п.48): open-time integrity check — a corrupted
            // per-project DB must surface an offer to restore the latest
            // backup instead of silently crashing or serving stale data.
            let path = workspace.path
            Task.detached(priority: .utility) {
                if case .corrupt(let message) = ProjectOpenIntegrity.checkOnOpen(projectPath: path) {
                    let alert = ProjectIntegrityAlert(projectPath: path, message: message)
                    await MainActor.run { self.projectIntegrityAlert = alert }
                }
            }

            guard !isNavigatingHistory else { return }

            navigationLock.lock()
            if navigationHistory.isEmpty || navigationHistory.last?.id != workspace.id {
                // Atomically recompute the safe truncation point under the lock:
                // both the bounds check AND the mutation now happen on the same
                // thread, so a concurrent didSet can't interleave.
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
            navigationLock.unlock()
        }
    }
    @Published var navigationHistory: [Workspace] = []
    @Published var navigationIndex: Int = -1

    /// Reset navigation to a safe state (used when the workspace is cleared,
    /// e.g. during a storage reset) so the UI can't observe an out-of-bounds
    /// index into navigationHistory. Internal so extensions (AppState+Database)
    /// can call it.
    func clearNavigationHistory() {
        navigationLock.lock()
        navigationHistory = []
        navigationIndex = -1
        navigationLock.unlock()
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
        LocalizationRuntime.currentLanguage = language
        // Force UI refresh by bumping the language counter
        objectWillChange.send()
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
    /// Set by slash commands (`/commit`, `/pr`, `/review`) to open the
    /// corresponding git dialog (E08, Раздел 5 п.13/15/16). ContentView
    /// presents one `.sheet(item:)` that switches on this value.
    @Published var pendingGitAction: GitUIAction?
    /// Set when a project is opened and its database fails the open-time
    /// integrity check (E04, Раздел 8 п.48). ContentView offers to restore
    /// the latest auto-backup.
    @Published var projectIntegrityAlert: ProjectIntegrityAlert?
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
    @Published var showRemoveProviderConfirmation = false
    @Published var pendingProviderToDelete: CustomProvider?
    @Published var notificationService = NotificationService()
    @Published var transientProviderNotification: AppNotification? = nil
    /// Short-lived feedback for shell actions such as Cmd+Option+Z.
    @Published var shellActionNotice: String?
    private var autoFreeSwitchObserver: NSObjectProtocol? = nil
    
    var displayedWorkspaces: [Workspace] {
        let visible = WorkspaceArchiveVisibilityLogic.visible(
            workspaces,
            registry: projectRegistryEntries,
            selectedPath: selectedWorkspace?.path
        )
        let nameFiltered = SidebarWorkspaceLogic.filtered(visible, query: workspaceFilterQuery)
        let sessionFiltered = SidebarWorkspaceLogic.filteredBySessionCount(nameFiltered, sessions: sessions, preset: workspaceFilterPreset)
        return SidebarWorkspaceLogic.sorted(sessionFiltered, order: workspaceSortOrder, sessions: sessions)
    }

    /// Reload the global project registry after Storage/Archive mutations so
    /// the sidebar reflects the action immediately instead of requiring a
    /// relaunch. Unknown registry rows remain non-destructive to workspaces.
    @MainActor
    func refreshProjectRegistry() {
        projectRegistryEntries = ProjectRegistryLogic.load(
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser
        )
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

    /// True when running under the test runner. Tests construct hundreds of
    /// AppState instances on arbitrary threads; the init-time registry dedup
    /// and the fire-and-forget DB task would (a) VACUUM/auto-archive the real
    /// `~/.micoder` database and dedup the real registry, and (b) mutate
    /// `@Published` state on the MainActor while test threads mutate the same
    /// instance — a data race that intermittently SIGSEGVs the full test suite
    /// at a random `@Published` accessor. Both are skipped under tests, which
    /// exercise `initializeDatabase()` explicitly.
    private static let isRunningTests: Bool = {
        if ProcessInfo.processInfo.environment["MIMO_TEST_MODE"] == "1" { return true }
        return NSClassFromString("XCTestCase") != nil
    }()

    // MiMo Serve connection manager (now optional)
    @Published var serverConnectionManager: MimoServeConnectionManager?

    init(host: String = "127.0.0.1", port: Int = 4096, defaults: UserDefaults = .standard) {
        self.serverHost = host
        self.serverPort = port
        self.mimoClient = MimoServeClient(host: host, port: port)
        self.serverConnectionManager = MimoServeConnectionManager(client: mimoClient)
        self.defaults = defaults
        MiCoderAPIServer.appendLog("🆕 AppState.init: id=\(instanceID)")

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
        // Sync LocalizationRuntime with the loaded language
        LocalizationRuntime.currentLanguage = appLanguage

        migrateLegacyPreferences()
        autoFreeSwitchObserver = NotificationCenter.default.addObserver(
            forName: .miCoderAutoFreeModelSwitched,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let appNotification = MiCoderAutoFreeNotificationLogic.make(
                userInfo: notification.userInfo ?? [:]
            )
            self.notificationService.add(appNotification)
            self.transientProviderNotification = appNotification
        }

        guard !Self.isRunningTests else { return }

        // Dedup the project registry (plan Раздел 8 п.47): the old single DB
        // could leave multiple rows per canonical path (UUID pileup, Блок 1 п.4).
        // Idempotent — a clean registry is untouched.
        ProjectRegistryLogic.deduplicateRegistry(
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser
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

        // The legacy anonymous provider was renamed after its Xiaomi channel sunset.
        // Preserve an existing explicit selection across the rename.
        for key in ["com.micoder.selectedProviderID", "com.micoder.preferredProviderID"] {
            if defaults.string(forKey: key) == "mimo-auto" {
                defaults.set(MiCoderAutoFreeProvider.builtInID, forKey: key)
            }
        }
    }
    
    func connectToServer() async {
        // Complete the health check before deciding whether server-backed
        // models may load. Previously the manager became connected while this
        // AppState boolean stayed false, so ContentView skipped model loading
        // on a healthy server during the first startup task.
        await serverConnectionManager?.checkAvailability()
        let managerConnected = serverConnectionManager?.isConnected == true
        serverConnected = ServerConnectionReadinessLogic.appStateConnectionState(
            isConnected: serverConnected,
            healthHealthy: managerConnected
        )

        if serverConnected {
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
        ).map { option in
            guard let custom = customProviders.first(where: { $0.id == option.id }),
                  custom.type == .openCodeZen else {
                return option
            }
            return ProviderOption(
                id: option.id,
                name: option.name,
                isCustom: true,
                isConnected: custom.isEnabled && !custom.models.isEmpty
            )
        }
        // Built-in MiCoder Auto Free provider (always present, non-removable).
        let autoFreeStore = MiCoderAutoFreeStore.shared
        options.append(ProviderOption(
            id: MiCoderAutoFreeProvider.builtInID,
            name: autoFreeStore.provider.displayName,
            isCustom: false,
            isConnected: autoFreeStore.provider.isReady
        ))
        // Local providers (Ollama/OpenCode/MiMo CLI) — plan Раздел 1.
        options += LocalProviderLogic.providerOptions(from: LocalProviderLogic.load())
        // Connected web providers (only after cookies captured) — plan Раздел 13 п.4.
        options += WebProviderConnectivity.providerOptions(
            WebProviderStore.load(),
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser
        )
        return options
    }

    /// Effective selected model — for web providers resolve from their config
    /// since AppState.selectedModel is empty for web providers.
    func effectiveSelectedModel() -> String {
        if let webID = WebProviderConnectivity.configID(fromOptionID: selectedProviderID),
           let cfg = WebProviderStore.load().first(where: { $0.id == webID }) {
            return WebProviderSelectionLogic.effectiveSelectedModel(for: cfg)
        }
        if selectedProviderID == MiCoderAutoFreeProvider.builtInID {
            return MiCoderAutoFreeStore.shared.provider.selectedModel
        }
        return selectedModel
    }

    var modelsForSelectedProvider: [String] {
        // Built-in MiCoder Auto Free provider.
        if selectedProviderID == MiCoderAutoFreeProvider.builtInID {
            return MiCoderAutoFreeStore.shared.provider.models.map { $0.id }
        }
        // Web provider selected → its real (discovered) models (plan Раздел 13 п.4).
        if let webID = WebProviderConnectivity.configID(fromOptionID: selectedProviderID),
           let cfg = WebProviderStore.load(defaults: defaults).first(where: { $0.id == webID }) {
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

    var selectedWebProviderConfig: WebProviderConfig? {
        guard let webID = WebProviderConnectivity.configID(fromOptionID: selectedProviderID) else { return nil }
        return WebProviderStore.load(defaults: defaults).first(where: { $0.id == webID })
    }

    var availableWebEffortsForSelectedProvider: [WebEffort] {
        guard let config = selectedWebProviderConfig else { return [] }
        return WebProviderSelectionLogic.availableEfforts(
            for: config,
            modelID: effectiveSelectedModel()
        )
    }

    var selectedWebEffort: WebEffort? {
        guard let config = selectedWebProviderConfig else { return nil }
        return WebSelectionReconciliationLogic.effortForModel(
            config: config,
            modelID: effectiveSelectedModel(),
            availableEfforts: availableWebEffortsForSelectedProvider
        )
    }

    private func updateWebProvider(_ configID: String,
                                   modelID: String? = nil,
                                   effort: WebEffort? = nil) {
        var providers = WebProviderStore.load(defaults: defaults)
        guard let index = providers.firstIndex(where: { $0.id == configID }) else { return }
        if let modelID {
            providers[index] = WebProviderSelectionLogic.selectingModel(
                modelID,
                in: providers[index],
                availableModels: WebProviderConnectivity.models(for: providers[index])
            )
        }
        if let effort {
            providers[index] = WebProviderSelectionLogic.selectingEffort(effort, in: providers[index])
        }
        WebProviderStore.save(providers, defaults: defaults)
    }

    func selectWebEffort(_ effort: WebEffort) {
        guard let webID = WebProviderConnectivity.configID(fromOptionID: selectedProviderID),
              availableWebEffortsForSelectedProvider.contains(effort) else { return }
        updateWebProvider(webID, effort: effort)
        if let config = WebProviderStore.load(defaults: defaults).first(where: { $0.id == webID }) {
            recordWebBrowserAction(action: "effort_selected",
                                   config: config,
                                   modelID: config.selectedModel,
                                   effort: effort,
                                   detail: "Composer effort selection")
        }
        objectWillChange.send()
    }

    var supportsToolcallForSelection: Bool {
        ProviderCapabilityGates.canUseTools(
            modelID: effectiveSelectedModel(),
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
        providerConnectivity[providerID] = false
        Task { await refreshProviderConnectivity(providerID) }
        defaults.set(providerID, forKey: "com.micoder.selectedProviderID")
        if persistPreference {
            defaults.set(providerID, forKey: "com.micoder.preferredProviderID")
        }

        // Web providers are persisted locally rather than returned by
        // `mimo serve`, so ProviderSelectionLogic cannot resolve their models.
        // Select their discovered model (or the clearly-labelled pre-discovery
        // fallback) directly instead of leaving the chat with an empty model.
        if let webID = WebProviderConnectivity.configID(fromOptionID: providerID),
           let config = WebProviderStore.load(defaults: defaults).first(where: { $0.id == webID }) {
            let models = WebProviderConnectivity.models(for: config)
            let preferred = WebSelectionReconciliationLogic.modelForRestore(
                config: config,
                globalPreferredModel: selectedModel,
                availableModels: models
            )
            selectedModel = preferred
            defaults.set(preferred, forKey: "com.micoder.selectedModel")
            selectedVariant = ""
            updateWebProvider(webID, modelID: preferred)
            return
        }

        if providerID == MiCoderAutoFreeProvider.builtInID {
            let autoFreeProvider = MiCoderAutoFreeStore.shared.provider
            let model = autoFreeProvider.models.contains(where: { $0.id == autoFreeProvider.selectedModel })
                ? autoFreeProvider.selectedModel
                : (autoFreeProvider.models.first?.id ?? MiCoderAutoFreeProvider.defaultModelID)
            selectedModel = model
            defaults.set(model, forKey: "com.micoder.selectedModel")
            selectedVariant = ""
            return
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
               modelID: effectiveSelectedModel(),
               providerID: providerID,
               providers: serverProviders,
               customProviders: customProviders
           ) {
            agentMode = .build
            Task { @MainActor in
                self.notificationService.info(
                    title: L.t(AppLocalizationKey.locModeSwitched),
                    message: L.t(AppLocalizationKey.locPlanNotSupported)
                )
            }
        }
    }

    @MainActor
    private func refreshProviderConnectivity(_ providerID: String) async {
        guard !providerID.isEmpty else { return }
        if serverConnected && serverProviders.contains(where: { $0.id == providerID }) {
            providerConnectivity[providerID] = true
            return
        }
        if let webID = WebProviderConnectivity.configID(fromOptionID: providerID),
           let config = WebProviderStore.load(defaults: defaults).first(where: { $0.id == webID }) {
            providerConnectivity[providerID] = WebProviderConnectivity.isConnected(
                config,
                homeDirectory: FileManager.default.homeDirectoryForCurrentUser
            )
            return
        }
        if let local = LocalProviderLogic.load().first(where: { $0.id == providerID && $0.isEnabled }) {
            providerConnectivity[providerID] = await probeProviderURL(local.healthURL)
            return
        }
        if let custom = customProviders.first(where: { $0.id == providerID && $0.isEnabled }) {
            let base = custom.baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            providerConnectivity[providerID] = await probeProviderURL("\(base)/models")
            return
        }
        providerConnectivity[providerID] = false
    }

    private func probeProviderURL(_ string: String) async -> Bool {
        guard let url = URL(string: string) else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let status = (response as? HTTPURLResponse)?.statusCode else { return false }
            return (200..<500).contains(status)
        } catch {
            return false
        }
    }

    func selectModel(_ modelID: String, persistPreference: Bool = true) {
        guard modelsForSelectedProvider.contains(modelID) else { return }
        selectedModel = modelID
        defaults.set(modelID, forKey: "com.micoder.selectedModel")
        if persistPreference {
            defaults.set(modelID, forKey: "com.micoder.preferredModelID")
        }
        if let webID = WebProviderConnectivity.configID(fromOptionID: selectedProviderID) {
            updateWebProvider(webID, modelID: modelID)
            if let config = WebProviderStore.load(defaults: defaults).first(where: { $0.id == webID }) {
                recordWebBrowserAction(action: "model_selected",
                                       config: config,
                                       modelID: modelID,
                                       effort: selectedWebEffort,
                                       detail: "Composer model selection")
            }
            selectedVariant = ""
            return
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

        // MiCoder Auto Free is the built-in free route. It becomes the initial
        // provider only after the anonymous OpenCode free catalog is ready.
        if selectedProviderID.isEmpty && preferredProviderID.isEmpty,
           MiCoderAutoFreeStore.shared.provider.isReady,
           options.contains(where: { $0.id == MiCoderAutoFreeProvider.builtInID }) {
            selectProvider(MiCoderAutoFreeProvider.builtInID, persistPreference: false)
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
        if let webID = WebProviderConnectivity.configID(fromOptionID: selectedProviderID),
           let config = WebProviderStore.load(defaults: defaults).first(where: { $0.id == webID }) {
            let resolved = WebSelectionReconciliationLogic.modelForRestore(
                config: config,
                globalPreferredModel: preferredModelID,
                availableModels: WebProviderConnectivity.models(for: config)
            )
            var providers = WebProviderStore.load(defaults: defaults)
            if let index = providers.firstIndex(where: { $0.id == webID }),
               providers[index].selectedModel != resolved {
                providers[index].selectedModel = resolved
                WebProviderStore.save(providers, defaults: defaults)
            }
            selectedModel = resolved
            defaults.set(resolved, forKey: "com.micoder.selectedModel")
            return
        }
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
        navigationLock.lock()
        guard navigationIndex > 0 else {
            navigationLock.unlock()
            return
        }
        navigationIndex -= 1
        let ws = navigationHistory[navigationIndex]
        navigationLock.unlock()
        isNavigatingHistory = true
        selectWorkspace(ws)
        isNavigatingHistory = false
    }

    func navigateForward() {
        navigationLock.lock()
        guard navigationIndex < navigationHistory.count - 1 else {
            navigationLock.unlock()
            return
        }
        navigationIndex += 1
        let ws = navigationHistory[navigationIndex]
        navigationLock.unlock()
        isNavigatingHistory = true
        selectWorkspace(ws)
        isNavigatingHistory = false
    }

    var canNavigateBack: Bool {
        navigationLock.lock()
        defer { navigationLock.unlock() }
        return navigationIndex > 0 && navigationIndex < navigationHistory.count
    }

    var canNavigateForward: Bool {
        navigationLock.lock()
        defer { navigationLock.unlock() }
        return navigationIndex < navigationHistory.count - 1 && navigationIndex >= 0 && navigationHistory.count > 0
    }
    
    func addOpenCodeZenProvider() {
        if let existing = customProviders.first(where: { $0.type == .openCodeZen }) {
            selectProvider(existing.id)
            return
        }
        let provider = CustomProvider(
            id: "opencode-zen",
            name: "OpenCode Zen",
            type: .openCodeZen,
            baseURL: OpenCodeZenCatalog.baseURL,
            apiKey: "",
            isEnabled: true,
            models: [],
            supportsTools: true,
            requiresAPIKey: false
        )
        addCustomProvider(provider)
        selectProvider(provider.id)
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
        guard let modelsURLString = ProviderEndpointLogic.modelsURL(for: url),
              let testURL = URL(string: modelsURLString) else { return false }
        var request = URLRequest(url: testURL)
        request.timeoutInterval = 10
        
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return ProviderConnectionValidationLogic.isValidModelsResponse(statusCode: http.statusCode, body: data)
        } catch {
            return false
        }
    }
    
    func refreshModels(for providerID: String) {
        guard let provider = customProviders.first(where: { $0.id == providerID }) else { return }
        loadModelsFromCustomProvider(provider)
    }

    func removeModel(_ modelID: String, from providerID: String) {
        guard let index = customProviders.firstIndex(where: { $0.id == providerID }) else { return }
        customProviders[index].models.removeAll { $0 == modelID }
        saveCustomProviders()
        if selectedProviderID == providerID && selectedModel == modelID {
            selectedModel = customProviders[index].models.first ?? ""
            defaults.set(selectedModel, forKey: "com.micoder.selectedModel")
            defaults.set(selectedModel, forKey: "com.micoder.preferredModelID")
            selectedVariant = ""
        }
        validateAndReconcileSelections()
    }

    func providerModelLoadMessage(for providerID: String) -> String? {
        providerModelLoadMessages[providerID]
    }

    private func loadModelsFromCustomProvider(_ provider: CustomProvider) {
        // Custom providers are stored locally and merged into the picker only.
        // MiMo Serve reads provider credentials from mimocode.json on disk; this
        // app does not push custom provider config to the server API.
        Task {
            let trimmedBaseURL = provider.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            guard let url = URL(string: trimmedBaseURL.hasSuffix("/models")
                                ? trimmedBaseURL
                                : "\(trimmedBaseURL)/models") else {
                await MainActor.run {
                    self.providerModelLoadMessages[provider.id] = "Invalid provider URL."
                }
                return
            }
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            // Use Keychain-backed API key if available, fall back to plain storage
            let apiKey = provider.getSecureAPIKey() ?? ""
            if !apiKey.isEmpty {
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200..<300).contains(http.statusCode) else {
                    let body = String(data: data, encoding: .utf8) ?? ""
                    await MainActor.run {
                        self.providerModelLoadMessages[provider.id] = "Model request failed (HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)): \(String(body.prefix(180)))"
                    }
                    return
                }
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    await MainActor.run {
                        self.providerModelLoadMessages[provider.id] = "The provider returned an invalid model-list response."
                    }
                    return
                }
                // OpenAI-compatible: { data: [{ id }] }; Ollama: { models:
                // [{ name }] }; Google: { models: [{ name: "models/..." }] }.
                let openAIModels = (json["data"] as? [[String: Any]])?.compactMap { $0["id"] as? String } ?? []
                let namedModels = (json["models"] as? [[String: Any]])?.compactMap {
                    ($0["id"] as? String) ?? ($0["name"] as? String)
                }.map { $0.replacingOccurrences(of: "models/", with: "") } ?? []
                let discoveredModels = Array(Set(openAIModels + namedModels)).sorted()
                let models: [String] = provider.type == .openCodeZen
                    ? OpenCodeZenCatalog.availableModels(from: discoveredModels, apiKey: apiKey)
                    : discoveredModels
                guard !models.isEmpty else {
                    await MainActor.run {
                        self.providerModelLoadMessages[provider.id] = "No models were found in this provider's response. Check its API base URL."
                    }
                    return
                }
                let providerID = provider.id
                let loadedModels = models
                let modelCount = loadedModels.count
                let modelLoadMessage = provider.type == .openCodeZen
                    ? "Loaded \(modelCount) OpenCode Zen model\(modelCount == 1 ? "" : "s") · \(OpenCodeZenCatalog.accessSummary(hasAPIKey: !apiKey.isEmpty))"
                    : "Loaded \(modelCount) model\(modelCount == 1 ? "" : "s")."
                await MainActor.run { [providerID, loadedModels, modelLoadMessage] in
                    if let index = customProviders.firstIndex(where: { $0.id == providerID }) {
                        customProviders[index].models = loadedModels
                        saveCustomProviders()
                    }
                    providerModelLoadMessages[providerID] = modelLoadMessage
                    if selectedProviderID == providerID || selectedProviderID.isEmpty {
                        validateAndReconcileSelections()
                    }
                }
            } catch {
                await MainActor.run {
                    self.providerModelLoadMessages[provider.id] = "Could not load models: \(error.localizedDescription)"
                }
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
    /// Lazy browser pool. Each project/chat/provider gets an isolated page;
    /// cookies remain shared through WKWebView's default data store. We never
    /// create 100 pages up front: the cap is a safety ceiling, not a target.
    private var webViews: [String: WKWebView] = [:]
    private var webViewLastUsed: [String: Date] = [:]
    private let maxWebBrowserInstances = 100

    @Published private(set) var webBrowserActionJournal: [WebBrowserActionRecord] = WebBrowserActionJournal.load()

    @MainActor
    func webView(for config: WebProviderConfig,
                 projectID: String? = nil,
                 chatID: String? = nil) -> WKWebView {
        let key = WebBrowserInstanceKey(
            projectID: projectID ?? selectedWorkspace?.id ?? "global",
            chatID: chatID ?? selectedSession?.id ?? "provider-default",
            providerID: config.id,
            activeSessionID: config.activeSessionID ?? WebSessionManager.defaultSessionID
        ).storageKey
        if let existing = webViews[key] {
            webViewLastUsed[key] = Date()
            return existing
        }
        if webViews.count >= maxWebBrowserInstances,
           let evictKey = webViewLastUsed.min(by: { $0.value < $1.value })?.key,
           let evicted = webViews.removeValue(forKey: evictKey) {
            evicted.stopLoading()
            evicted.removeFromSuperview()
            webViewLastUsed.removeValue(forKey: evictKey)
        }
        let wv = WKWebView(frame: .zero)
        webViews[key] = wv
        webViewLastUsed[key] = Date()
        return wv
    }

    @MainActor
    func recordWebBrowserAction(action: String,
                                config: WebProviderConfig,
                                projectID: String? = nil,
                                chatID: String? = nil,
                                modelID: String? = nil,
                                effort: WebEffort? = nil,
                                remoteChatID: String? = nil,
                                detail: String? = nil) {
        let record = WebBrowserActionRecord(
            action: action,
            projectID: projectID ?? selectedWorkspace?.id ?? "global",
            chatID: chatID ?? selectedSession?.id ?? "unknown-chat",
            providerID: config.id,
            providerName: config.displayName,
            modelID: modelID ?? config.selectedModel,
            effort: effort,
            remoteChatID: remoteChatID,
            detail: detail
        )
        webBrowserActionJournal = WebBrowserActionJournal.append(record, defaults: defaults)
    }

    @MainActor
    func webRemoteChatKey(for config: WebProviderConfig,
                          projectID: String,
                          chatID: String) -> WebRemoteChatKey {
        WebRemoteChatKey(providerID: config.id,
                         activeSessionID: config.activeSessionID ?? WebSessionManager.defaultSessionID,
                         projectID: projectID,
                         localChatID: chatID)
    }

    @MainActor
    func webRemoteChatMapping(for config: WebProviderConfig,
                              projectID: String,
                              chatID: String) -> WebRemoteChatMapping? {
        WebRemoteChatStore.mapping(for: webRemoteChatKey(for: config, projectID: projectID, chatID: chatID),
                                   defaults: defaults)
    }

    @MainActor
    func saveWebRemoteChatMapping(_ mapping: WebRemoteChatMapping) {
        WebRemoteChatStore.upsert(mapping, defaults: defaults)
    }

    @MainActor
    func clearWebRemoteChats(providerID: String, activeSessionID: String? = nil) {
        WebRemoteChatStore.clear(providerID: providerID, activeSessionID: activeSessionID, defaults: defaults)
    }

    /// Stop the active browser generation for a provider. This is separate from
    /// cancelling the Swift task: the vendor page must receive its own stop
    /// action or it can keep consuming tokens in the background.
    @MainActor
    func stopWebGeneration(providerID: String) async {
        guard let config = WebProviderStore.load(defaults: defaults).first(where: { $0.id == providerID }) else { return }
        let catalogEntry = try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id)
        let selectors = WebVendorSelectors(
            input: catalogEntry?.input ?? "textarea, div[contenteditable='true']",
            sendButton: catalogEntry?.sendButton ?? "button[type='submit']",
            responseContainer: catalogEntry?.responseContainer ?? "div[class*='message']",
            stopButton: catalogEntry?.stopButton ?? "button[aria-label*='stop' i], button[data-testid='stop-button']"
        )
        let bridge = WKWebViewBrowserBridge(webView: webView(for: config), selectors: selectors)
        try? await bridge.stopGeneration()
    }

    /// Refresh the *real* model list for an authenticated web provider. The
    /// login sheet uses a separate WKWebView, so this method first restores the
    /// captured cookies into the persistent chat web view, opens the vendor
    /// page, waits for its composer, then opens and reads the model dropdown.
    /// It returns an actionable message instead of silently leaving 0 models.
    @MainActor
    func refreshWebModels(for config: WebProviderConfig,
                          projectID: String? = nil,
                          chatID: String? = nil) async -> String {
        // Prefer the user-picked selector but always retain catalog fallbacks.
        // A stale custom selector must not hide the live model menu.
        let catalogEntry = try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id)
        let selector = [
            config.customModelSelector?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            catalogEntry?.modelDropdown ?? ""
        ].filter { !$0.isEmpty }.joined(separator: ", ")
        if selector.isEmpty {
            return L.t(AppLocalizationKey.locWebNoSelectorYet)
        }
        let sessionID = config.activeSessionID ?? WebSessionManager.defaultSessionID
        guard let store = WebSessionManager.restore(providerId: config.id,
                                                    homeDirectory: FileManager.default.homeDirectoryForCurrentUser,
                                                    sessionID: sessionID),
              !store.cookies.isEmpty,
              !WebSessionManager.isExpired(store) else {
            return L.t(AppLocalizationKey.locWebLoginFirst)
        }

        let selectors = WebVendorSelectors(
            input: "textarea, div[contenteditable='true']",
            sendButton: "button[type='submit'], button[aria-label*='send'], button[data-testid='send-button']",
            responseContainer: "div[data-message-author-role='assistant'], div[class*='markdown'], div[class*='message']",
            stopButton: "button[aria-label*='stop'], button[data-testid='stop-button'], button[class*='stop']"
        )
        let bridge = WKWebViewBrowserBridge(webView: webView(for: config, projectID: projectID, chatID: chatID), selectors: selectors)
        var localStorageWarning: String?
        do {
            let payload = WebSessionRestorationLogic.payload(from: store)
            try await bridge.setCookies(payload.cookies)
            try await bridge.navigate(to: config.chatURL)
            do {
                try await bridge.setLocalStorage(payload.localStorage)
                if !payload.localStorage.isEmpty {
                    try await bridge.navigate(to: config.chatURL)
                }
            } catch {
                localStorageWarning = " (localStorage restore unavailable: \(error.localizedDescription))"
            }
            var inputFound = false
            for _ in 0..<30 {
                if try await bridge.exists(selector: selectors.input) {
                    inputFound = true
                    break
                }
                await bridge.wait(ms: 500)
            }
            guard inputFound else {
                return L.t(AppLocalizationKey.locWebInputNotFound)
            }
            let models = await WebModelDiscovery.discoverAllModels(using: bridge,
                                                                    dropdownSelector: selector,
                                                                    vendor: config.vendor)
            guard let found = models else {
                return String(format: L.t(AppLocalizationKey.locWebModelListFailed), config.displayName)
            }
            let capabilityModels = await WebModelDiscovery.discoverModelCapabilities(
                using: bridge,
                dropdownSelector: selector,
                vendor: config.vendor,
                models: found,
                effortDropdownSelector: config.effortDropdown ?? catalogEntry?.effortDropdown
            )
            let resolvedModels = capabilityModels.isEmpty ? found : capabilityModels
            let discoveredEfforts = Array(Set(resolvedModels.flatMap(\.availableEfforts))).sorted { $0.rawValue < $1.rawValue }
            if !config.selectedModel.isEmpty {
                let itemSelector = catalogEntry?.modelItem ?? "[role='option'], [class*='model'], li"
                var restored = (try? await bridge.clickVisibleTextExact(selector: itemSelector, text: config.selectedModel)) == true
                if !restored {
                    for selector in ["[role='option']", "[role='menuitem']", "[class*='model-item']"] {
                        if (try? await bridge.clickVisibleTextExact(selector: selector, text: config.selectedModel)) == true {
                            restored = true
                            break
                        }
                    }
                }
                if restored { await bridge.wait(ms: 250) }
            }
            var updated = WebModelRefreshLogic.replacing(config: config, with: resolvedModels)
            updated.discoveredEffortLevels = discoveredEfforts
            WebProviderStore.save(WebProviderStore.upsert(updated, in: WebProviderStore.load()))
            if resolvedModels.isEmpty {
                return String(format: L.t(AppLocalizationKey.locWebModelListFailed), config.displayName)
            }
            if selectedProviderID == "web:\(config.id)" {
                selectProvider(selectedProviderID, persistPreference: false)
            }
            let count = resolvedModels.count
            let plural = count == 1 ? "" : "s"
            let message = String(format: L.t(AppLocalizationKey.locWebLoadedModels), count, plural, config.displayName)
            return message + (localStorageWarning ?? "")
        } catch {
            return String(format: L.t(AppLocalizationKey.locWebRefreshFailed), error.localizedDescription)
        }
    }
    #endif
    /// Refresh available effort/thinking levels for a web provider by reading
    /// the effort dropdown on the provider's web page.
    /// Returns a status message describing the result.
    @MainActor
    func refreshWebEffort(for config: WebProviderConfig,
                          projectID: String? = nil,
                          chatID: String? = nil) async -> String {
        #if canImport(WebKit)
        guard let effortSelector = try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id)?.effortDropdown else {
            return L.t(AppLocalizationKey.locWebEffortNoSelector)
        }
        let sessionID = config.activeSessionID ?? WebSessionManager.defaultSessionID
        guard let store = WebSessionManager.restore(providerId: config.id,
                                                    homeDirectory: FileManager.default.homeDirectoryForCurrentUser,
                                                    sessionID: sessionID),
              !store.cookies.isEmpty,
              !WebSessionManager.isExpired(store) else {
            return L.t(AppLocalizationKey.locWebEffortLoginFirst)
        }

        let selectors = WebVendorSelectors(
            input: "textarea, div[contenteditable='true']",
            sendButton: "button[type='submit'], button[aria-label*='send'], button[data-testid='send-button']",
            responseContainer: "div[data-message-author-role='assistant'], div[class*='markdown'], div[class*='message']",
            stopButton: "button[aria-label*='stop'], button[data-testid='stop-button'], button[class*='stop']"
        )
        let bridge = WKWebViewBrowserBridge(webView: webView(for: config, projectID: projectID, chatID: chatID), selectors: selectors)
        var localStorageWarning: String?
        do {
            let payload = WebSessionRestorationLogic.payload(from: store)
            try await bridge.setCookies(payload.cookies)
            try await bridge.navigate(to: config.chatURL)
            do {
                try await bridge.setLocalStorage(payload.localStorage)
                if !payload.localStorage.isEmpty {
                    try await bridge.navigate(to: config.chatURL)
                }
            } catch {
                localStorageWarning = " (localStorage restore unavailable: \(error.localizedDescription))"
            }
            var inputFound = false
            for _ in 0..<30 {
                if try await bridge.exists(selector: selectors.input) {
                    inputFound = true
                    break
                }
                await bridge.wait(ms: 500)
            }
            guard inputFound else {
                return L.t(AppLocalizationKey.locWebInputNotFound)
            }
            guard let efforts = await WebModelDiscovery.discoverEffort(using: bridge,
                                                                       effortDropdownSelector: effortSelector,
                                                                       vendor: config.vendor) else {
                return String(format: L.t(AppLocalizationKey.locWebEffortReadFailed), config.displayName)
            }
            var updated = config
            updated.effort = efforts.first ?? .medium
            updated.discoveredEffortLevels = efforts
            WebProviderStore.save(WebProviderStore.upsert(updated, in: WebProviderStore.load()))
            if selectedProviderID == "web:\(config.id)" {
                selectProvider(selectedProviderID, persistPreference: false)
            }
            let count = efforts.count
            let plural = count == 1 ? "" : "s"
            let message = String(format: L.t(AppLocalizationKey.locWebLoadedEffort), count, plural, config.displayName)
            return message + (localStorageWarning ?? "")
        } catch {
            return String(format: L.t(AppLocalizationKey.locWebEffortRefreshFailed), error.localizedDescription)
        }
        #else
        return L.t(AppLocalizationKey.locWebRequiresWebKit)
        #endif
    }

    /// Refresh the complete model capability snapshot. `refreshWebModels` already
    /// probes effort and parameter controls for every validated model; calling
    /// the older provider-global effort probe afterwards would overwrite the
    /// atomic per-model result with an ambiguous union.
    @MainActor
    func refreshWebModelsAndEffort(for config: WebProviderConfig,
                                   projectID: String? = nil,
                                   chatID: String? = nil) async -> (modelsMsg: String, effortMsg: String) {
        let modelsMsg = await refreshWebModels(for: config, projectID: projectID, chatID: chatID)
        let refreshedConfig = WebProviderStore.load().first(where: { $0.id == config.id }) ?? config
        let profiledCount = refreshedConfig.discoveredModels.filter { !$0.availableEfforts.isEmpty }.count
        let effortMsg = profiledCount == 0
            ? "No per-model effort controls were confirmed."
            : "Per-model effort detected for \(profiledCount) model(s)."
        return (modelsMsg, effortMsg)
    }


    /// Web providers whose chat session has already been seeded with the tool
    /// preamble this app run — so we send the preamble only on the first turn
    /// (audit P2). Reset when the session is (re)started/logged out.
    private var webSessionStarted: Set<String> = []
    func webSessionIsFirstTurn(_ providerID: String) -> Bool { !webSessionStarted.contains(providerID) }
    func markWebSessionStarted(_ providerID: String) { webSessionStarted.insert(providerID) }
    func resetWebSession(_ providerID: String) { webSessionStarted.remove(providerID) }

    func webSessionIsFirstTurn(_ key: WebRemoteChatKey) -> Bool { !webSessionStarted.contains(key.storageKey) }
    func markWebSessionStarted(_ key: WebRemoteChatKey) { webSessionStarted.insert(key.storageKey) }
    func resetWebSession(_ key: WebRemoteChatKey) { webSessionStarted.remove(key.storageKey) }

    /// Ids of enabled local providers (for send-routing / readiness checks).
    var localProviderIDs: [String] {
        LocalProviderLogic.load().filter { $0.isEnabled }.map { $0.id }
    }
    /// Ids of configured web providers (for send-routing / readiness checks).
    var webProviderIDs: [String] {
        WebProviderStore.load(defaults: defaults).map { $0.id }
    }

    var selectedProviderConnected: Bool {
        let webConnected: Bool?
        if let webID = WebProviderConnectivity.configID(fromOptionID: selectedProviderID),
           let config = WebProviderStore.load(defaults: defaults).first(where: { $0.id == webID }) {
            webConnected = WebProviderConnectivity.isConnected(
                config,
                homeDirectory: FileManager.default.homeDirectoryForCurrentUser
            )
        } else {
            webConnected = nil
        }
        let localEnabled = LocalProviderLogic.load().contains {
            $0.id == selectedProviderID && $0.isEnabled
        }
        let customReady = customProviders.contains {
            $0.id == selectedProviderID
                && $0.isEnabled
                && (!$0.requiresAPIKey || !$0.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        let autoFreeReady = selectedProviderID == MiCoderAutoFreeProvider.builtInID
            ? MiCoderAutoFreeStore.shared.provider.isReady
            : false
        return ProviderConnectionStatusLogic.isConnected(
            selectedID: selectedProviderID,
            serverProviderIDs: serverProviders.map(\.id),
            serverConnected: serverConnected,
            autoFreeID: MiCoderAutoFreeProvider.builtInID,
            autoFreeReady: autoFreeReady,
            webConnected: webConnected,
            localEnabled: localEnabled,
            customReady: customReady,
            remembered: providerConnectivity[selectedProviderID]
        )
    }

    var currentSessionGoal: String? { selectedSession?.sessionGoal }

    /// Undo the most recent project-scoped file change and make every outcome
    /// visible. The old command discarded both the Bool result and thrown
    /// errors, leaving users unable to tell whether anything happened.
    @MainActor
    func undoLastAction() {
        guard selectedSession != nil else {
            publishShellActionNotice(UndoActionFeedbackLogic.message(for: .nothingToUndo))
            return
        }
        guard let projectUndoManager else {
            publishShellActionNotice(UndoActionFeedbackLogic.message(for: .nothingToUndo))
            return
        }
        let result: UndoActionResult
        do {
            let didUndo = try projectUndoManager.undoMostRecent(sessionId: selectedSession?.id ?? "")
            result = didUndo ? .undone : .nothingToUndo
        } catch {
            result = .failed(error.localizedDescription)
        }
        publishShellActionNotice(UndoActionFeedbackLogic.message(for: result))
        if result == .undone {
            let directory = selectedWorkspace?.path
            Task { await refreshGitFromLocal(directory: directory) }
        }
    }

    @MainActor
    private func publishShellActionNotice(_ message: String) {
        shellActionNotice = message
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard self?.shellActionNotice == message else { return }
                self?.shellActionNotice = nil
            }
        }
    }

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
        DatabaseBridge.shared.setSessionGoal(sessionId: session.id, goal: value)
    }

    /// Build the data context for the in-input command dropdown (plan Раздел 6).
    /// Cached project file list for `@` mentions (audit P12).
    private var projectFilesCache: ProjectFilesCacheState?
    private var projectFileIndexWatcher: ProjectFileIndexWatcher?
    private var projectFileIndexGeneration: UInt64 = 0

    private func updateProjectFileIndexWatcher(for workspace: Workspace?) {
        projectFileIndexGeneration &+= 1
        projectFileIndexWatcher?.stop()
        projectFileIndexWatcher = nil
        projectFilesCache = nil
        guard let workspace, !workspace.path.isEmpty else { return }

        let path = workspace.path
        let generation = projectFileIndexGeneration
        let watcher = ProjectFileIndexWatcher(
            projectPath: path,
            generation: generation
        ) { [weak self] eventPath, eventGeneration in
            DispatchQueue.main.async {
                guard let self,
                      ProjectFileIndexWatcherLogic.shouldApply(
                          eventProjectPath: eventPath,
                          activeProjectPath: self.selectedWorkspace?.path ?? "",
                          eventGeneration: eventGeneration,
                          activeGeneration: self.projectFileIndexGeneration
                      ) else { return }
                self.projectFilesCache = nil
            }
        }
        projectFileIndexWatcher = watcher
        watcher.start()
    }

    func inputDropdownContext() -> InputDropdownDataSource.Context {
        let skills = AgentResourcesLoader.loadSkills().map { $0.name }
        let mcpServers = AgentResourcesLoader.loadMCPServers().map { $0.name }
        let sessionTitles = sessions.map { $0.title }
        let path = selectedWorkspace?.path ?? ""
        // Real project files for `@` — scan (cached, TTL) instead of empty list.
        if ProjectFilesCacheLogic.needsRescan(cache: projectFilesCache, currentPath: path) {
            let currentRecords = ProjectFileIndexStore.load(projectPath: path)
            let scannedRecords = ProjectFileScanner.scan(root: path)
            let records = ProjectFileIndexPersistenceLogic.applyDelta(current: currentRecords, scanned: scannedRecords)
            ProjectFileIndexStore.save(projectPath: path, records: records)
            projectFilesCache = ProjectFilesCacheState(
                projectPath: path,
                fileNames: records.map(\.path),
                scannedAt: Date()
            )
        }
        let fileNames = ProjectFilesCacheLogic.fileNames(cache: projectFilesCache, currentPath: path)
        return InputDropdownDataSource.Context(
            commands: SlashCommandRegistry.allCommands(),
            installedSkills: skills,
            fileNames: fileNames,
            sessionTitles: sessionTitles,
            mcpServers: mcpServers
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
        validateAndReconcileSelections()
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
    
    func selectWorkspace(_ workspace: Workspace, reloadSessions: Bool = true) {
        let previousID = selectedWorkspace?.id
        selectedWorkspace = workspace
        guard reloadSessions,
              WorkspaceSelectionLogic.shouldReloadSessions(previousID: previousID, newID: workspace.id) else {
            return
        }

        // Do not show the previous project's sessions while the new project's
        // database is loading. ChatPanel observes the nil selection and clears
        // its message store before the new session list arrives.
        selectedSession = nil
        sessions = []
        currentSteps = []
        vcsChanges = []
        sessionGitTotals = SessionGitTotals(additions: 0, deletions: 0)
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.loadSessionsFromDatabase(projectId: workspace.id)
        }
    }

    func selectSession(_ session: ChatSession) {
        if let workspace = workspaces.first(where: { session.belongs(to: $0) }) {
            selectWorkspace(workspace)
        }
        selectedSession = session
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

    /// Publishes the current workspace as a new GitHub repository via `gh`
    /// (shared by the publish wizard and the `/pr` slash command — E08).
    func publishWorkspaceToGitHub(ghPath: String, repoName: String, isPublic: Bool) async {
        guard let path = selectedWorkspace?.path else { return }
        guard GitPublishFlowLogic.isValidRepoName(repoName) else { return }

        await MainActor.run {
            isGitBusy = true
            gitStatusMessage = "Publishing to GitHub..."
        }

        do {
            let output = try await GitHubCLIService.createRepository(
                ghPath: ghPath,
                repoName: repoName,
                isPublic: isPublic,
                workspacePath: path
            )
            await MainActor.run {
                isGitBusy = false
                gitStatusMessage = output.isEmpty ? "Published to GitHub successfully!" : output
            }
            await refreshGitFromLocal()
        } catch {
            await MainActor.run {
                isGitBusy = false
                gitStatusMessage = "Failed to publish: \(error.localizedDescription)"
            }
        }
    }

    /// Creates a pull request for the current branch via `gh pr create`
    /// (Раздел 5 п.16 — real action for `/pr`).
    @discardableResult
    func createGitHubPullRequest(title: String, body: String) async -> Bool {
        guard let path = selectedWorkspace?.path,
              let ghPath = GitPublishFlowLogic.ghExecutablePath() else {
            await MainActor.run { gitStatusMessage = "GitHub CLI is not available — use the publish wizard." }
            return false
        }

        await MainActor.run {
            isGitBusy = true
            gitStatusMessage = "Creating pull request..."
        }
        defer { Task { await self.endGitBusy() } }

        do {
            let output = try await GitHubCLIService.createPullRequest(
                ghPath: ghPath,
                title: title,
                body: body,
                workspacePath: path
            )
            await MainActor.run {
                gitStatusMessage = output.isEmpty ? "Pull request created" : output
                notificationService.gitOperationComplete(operation: "PR", details: title)
            }
            return true
        } catch {
            await MainActor.run {
                gitStatusMessage = "Failed to create PR: \(error.localizedDescription)"
            }
            return false
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
            selectWorkspace(workspace)
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

    /// Create the local project-scoped session required before the first user
    /// or assistant message is appended. Serve used to create its remote
    /// session later, which meant the earlier MessageStore.append calls saw a
    /// nil currentSessionID and silently skipped local persistence.
    @MainActor
    func prepareLocalSessionForSend(title: String) -> String? {
        if let selectedID = selectedSession?.id {
            return selectedID
        }
        guard let workspace = selectedWorkspace else { return nil }
        let sessionID = UUID().uuidString
        let sessionTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "New Chat"
            : String(title.prefix(80))
        DatabaseBridge.shared.createSession(
            id: sessionID,
            projectId: workspace.path,
            title: sessionTitle,
            directory: workspace.path,
            branch: workspace.branch,
            agentMode: agentMode.rawValue,
            modelId: selectedModel.isEmpty ? nil : selectedModel,
            providerId: selectedProviderID.isEmpty ? nil : selectedProviderID
        )
        let session = ChatSession(
            id: sessionID,
            title: sessionTitle,
            directory: workspace.path,
            branch: workspace.branch
        )
        if !sessions.contains(where: { $0.id == sessionID }) {
            sessions.insert(session, at: 0)
        }
        return sessionID
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
        MiCoderAPIServer.appendLog("📝 upsertSession: id=\(session.id), sessions=\(sessions.count), selected=\(selectedSession?.id ?? "nil")")
    }
    
    func registerSessionFromServer(id: String, title: String, directory: String, select: Bool = true) {
        let session = ChatSession(
            id: id,
            title: title,
            directory: directory,
            branch: selectedWorkspace?.branch
        )
        if select {
            upsertSession(session)
        } else if !sessions.contains(where: { $0.id == id }) {
            sessions.insert(session, at: 0)
        }
    }
    
    @discardableResult
    @MainActor
    func addWorkspace(path: String, branch: String? = nil) -> Workspace {
        let normalized = ChatSession.normalizedPath(path)
        if let existing = workspaces.first(where: { ChatSession.normalizedPath($0.path) == normalized }) {
            createOrUpdateProject(id: existing.id, name: existing.name, path: normalized, gitBranch: existing.branch)
            selectWorkspace(existing)
            return existing
        }
        
        // Round 14 (п.17/п.18): a project's id is its canonical path — never a
        // fresh UUID, so the DB row, registry entry, sessions and navigation
        // all agree on ONE identity (the old code minted a second UUID here).
        let workspace = Workspace(
            id: ProjectIdentityLogic.projectID(for: normalized),
            name: (normalized as NSString).lastPathComponent,
            path: normalized,
            branch: branch,
            tasks: []
        )
        workspaces.append(workspace)
        selectWorkspace(workspace, reloadSessions: false)
        createOrUpdateProject(id: workspace.id, name: workspace.name, path: normalized, gitBranch: branch)

        // Round 14 (п.11/п.32): registering here fixes the orphaned registry —
        // without it the storage panel stayed empty in real use.
        let home = FileManager.default.homeDirectoryForCurrentUser
        let entries = ProjectRegistryLogic.load(homeDirectory: home)
        let updated = ProjectRegistryLogic.registerProject(path: normalized, name: workspace.name, into: entries)
        if updated != entries {
            try? ProjectRegistryLogic.save(updated, homeDirectory: home)
            try? StorageAuditLog.append(action: "registry.add",
                                        detail: normalized,
                                        homeDirectory: home)
        }
        return workspace
    }
    
    /// Создать новый проект: добавляет workspace и сохраняет в БД
    @MainActor
    func createNewProject(name: String, path: String) {
        let normalizedPath = ChatSession.normalizedPath(path)
        // Round 14 (п.18): the id must be the canonical path (same as
        // addWorkspace), NOT a random UUID — the two callers used to emit two
        // different ids for the same folder.
        let projectId = ProjectIdentityLogic.projectID(for: normalizedPath)
        
        // Сохраняем в БД
        createOrUpdateProject(id: projectId, name: name, path: normalizedPath)
        
        // Добавляем workspace если его ещё нет (addWorkspace also registers
        // the project in the registry — Round 14 п.11).
        addWorkspace(path: normalizedPath)
    }
}
