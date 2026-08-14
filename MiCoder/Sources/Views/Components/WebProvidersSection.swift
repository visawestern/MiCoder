import SwiftUI
import WebKit

// Preference key for auto-sizing TextEditor height
private struct TextHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 28
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
/// Web-free provider management (Kimi/Qwen/ChatGPT) — plan Раздел 12 Блок 4.
/// Configure system prompt / model / effort / tool-call delay / keep-alive,
/// acknowledge ToS, and log in via an embedded web view that captures cookies.
struct WebProvidersSection: View {
    @EnvironmentObject var appState: AppState
    @State private var providers: [WebProviderConfig] = WebProviderStore.load()
    @State private var loginConfig: WebProviderConfig?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L.t(AppLocalizationKey.locWebProvidersBrowser))
                .interfaceFont(size: 18, weight: .semibold)
                .foregroundColor(Color.mimo.textPrimary)
            Text(L.t(AppLocalizationKey.locUseFreeWebModelsKimiQwenChatgptThroughControlle))
                .interfaceFont(size: 12)
                .foregroundColor(Color.mimo.textSecondary)

            HStack(spacing: 12) {
                ForEach([WebChatVendor.kimi, .qwen, .chatgpt]) { vendor in
                    Button(action: { addVendor(vendor) }) {
                        VStack(spacing: 6) {
                            Image(systemName: "globe")
                                .interfaceFont(size: 20).foregroundColor(Color.mimo.brand)
                            Text(vendor.displayName)
                                .interfaceFont(size: 12, weight: .medium)
                                .foregroundColor(Color.mimo.textPrimary)
                            Text(providers.contains { $0.vendor == vendor } ? L.t(AppLocalizationKey.locConfigured) : L.t(AppLocalizationKey.locAdd))
                                .interfaceFont(size: 10)
                                .foregroundColor(providers.contains { $0.vendor == vendor } ? Color.mimo.success : Color.mimo.textMuted)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(Color.mimo.surface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            ForEach($providers) { $cfg in
                WebProviderCard(config: $cfg,
                                onSave: { save() },
                                onLogin: { loginConfig = cfg },
                                onRemove: { remove(cfg) },
                                onRefreshModels: { await refreshModels(for: cfg) },
                                onRefreshEffort: { await refreshEffort(for: cfg) },
                                homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
            }
        }
        .sheet(item: $loginConfig) { cfg in
            WebProviderLoginView(config: cfg) { cookies in
                persistCookies(cookies, for: cfg)
                loginConfig = nil
            }
        }
    }

    private func addVendor(_ vendor: WebChatVendor) {
        guard !providers.contains(where: { $0.vendor == vendor }) else { return }
        providers.append(WebProviderConfig(vendor: vendor))
        save()
    }

    private func remove(_ cfg: WebProviderConfig) {
        providers.removeAll { $0.id == cfg.id }
        save()
        try? WebSessionManager.clear(providerId: cfg.id,
                                      homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
        if appState.selectedProviderID == "web:\(cfg.id)" {
            appState.selectProvider("")
        }
    }

    private func save() {
        WebProviderStore.save(providers)
    }

    private func persistCookies(_ cookies: [BrowserCookie], for cfg: WebProviderConfig) {
        let store = WebSessionStore(cookies: cookies, localStorage: [:], savedAt: Date())
        try? WebSessionManager.persist(store, providerId: cfg.id,
                                       homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
        // Round 9 A: refresh the real model list now that the session is live,
        // so the picker isn't stuck showing hardcoded defaults until first send.
        Task { await refreshModels(for: cfg) }
    }

    /// Discover the vendor's real models from the page after connect (Round 9 A).
    private func refreshModels(for cfg: WebProviderConfig) async -> String? {
        #if canImport(WebKit)
        let message = await appState.refreshWebModels(for: cfg)
        providers = WebProviderStore.load()
        return message
        #else
        return L.t(AppLocalizationKey.locWebRequiresWebKit)
        #endif
    }

    /// Refresh the available effort/thinking levels for a web provider.
    private func refreshEffort(for cfg: WebProviderConfig) async -> String? {
        #if canImport(WebKit)
        let message = await appState.refreshWebEffort(for: cfg)
        providers = WebProviderStore.load()
        return message
        #else
        return L.t(AppLocalizationKey.locWebRequiresWebKit)
        #endif
    }
}

/// Editable card for one web provider (plan Раздел 12 Блок 4 п.43-47).
struct WebProviderCard: View {
    @Binding var config: WebProviderConfig
    let onSave: () -> Void
    let onLogin: () -> Void
    let onRemove: () -> Void
    let onRefreshModels: () async -> String?
    let onRefreshEffort: () async -> String?
    let homeDirectory: URL

    @State private var isRefreshing = false
    @State private var lastRefreshError: String?
    @State private var lastRefreshCount: Int = 0
    @State private var showDiscoveredModels = false
    @State private var systemPromptHeight: CGFloat = 24
    @State private var showRemoveConfirmation = false

    private var isConnected: Bool {
        WebProviderConnectivity.isConnected(config, homeDirectory: homeDirectory)
    }

    // System prompt templates with tool-specific instructions
    private static let systemPromptTemplates: [(name: String, prompt: String)] = [
        ("Default", ""),
        ("Code Agent", """
You are a code-focused AI agent. You can:
- Read/write files in the project directory
- Run shell commands (bash)
- Search/replace in files
- List directories

Always prefer using tools over explaining. When asked to modify code, make the minimal necessary changes. Run tests after changes.
"""),
        ("Code Reviewer", """
You are a senior code reviewer. Focus on:
- Correctness and edge cases
- Security vulnerabilities
- Performance implications
- Code style and maintainability
- Test coverage

Be specific about issues and suggest concrete improvements.
"""),
        ("Debugging Assistant", """
You are a debugging expert. Help the user by:
- Analyzing error messages and stack traces
- Suggesting hypotheses for root causes
- Proposing minimal reproduction steps
- Recommending debugging strategies (logging, breakpoints, etc.)
- Verifying fixes with tests
"""),
        ("Documentation Writer", """
You are a technical writer. Create clear, concise documentation:
- API references with examples
- Architecture overviews
- Setup/installation guides
- Changelog entries

Use clear headings, code examples, and cross-references.
"""),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(isConnected ? Color.mimo.success : Color.mimo.error)
                        .frame(width: 8, height: 8)
                    Text(config.displayName)
                        .interfaceFont(size: 14, weight: .semibold)
                        .foregroundColor(Color.mimo.textPrimary)
                }
                Spacer()
                if !isConnected {
                    Button(L.t(AppLocalizationKey.locLogin)) { onLogin() }
                        .interfaceFont(size: 12).buttonStyle(.plain).foregroundColor(Color.mimo.brand)
                } else {
                    HStack(spacing: 8) {
                        // Compact model detection status
                        if !isRefreshing && lastRefreshCount > 0 {
                            Button(action: { showDiscoveredModels.toggle() }) {
                                Text("\(lastRefreshCount) models")
                                    .interfaceFont(size: 10)
                                    .foregroundColor(Color.mimo.success)
                            }
                            .buttonStyle(.plain)
                            .help("Tap to see discovered models")
                        } else if !isRefreshing && lastRefreshError != nil {
                            Label("Detection failed", systemImage: "exclamationmark.triangle")
                                .interfaceFont(size: 10).foregroundColor(Color.mimo.warning)
                        }

                        Button(action: {
                            isRefreshing = true
                            lastRefreshError = nil
                            Task {
                                let result = await onRefreshModels()
                                await MainActor.run {
                                    isRefreshing = false
                                    if let updated = WebProviderStore.load().first(where: { $0.id == config.id }) {
                                        lastRefreshCount = updated.discoveredModels.count
                                    }
                                    if let result {
                                        let lower = result.lowercased()
                                        if lower.contains("failed") || lower.contains("could not") || lower.contains("not found") || lower.contains("login") {
                                            lastRefreshError = result
                                        }
                                    }
                                }
                            }
                        }) {
                            if isRefreshing {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .interfaceFont(size: 12)
                            }
                        }
                        .interfaceFont(size: 12).buttonStyle(.plain).foregroundColor(Color.mimo.brand)
                        .disabled(isRefreshing)
                        .help(isRefreshing ? "Detecting models…" : "Detect models from web UI")

                        Button(action: {
                            isRefreshing = true
                            lastRefreshError = nil
                            Task {
                                let result = await onRefreshEffort()
                                await MainActor.run {
                                    isRefreshing = false
                                    if let result {
                                        let lower = result.lowercased()
                                        if lower.contains("failed") || lower.contains("could not") || lower.contains("not found") || lower.contains("login") {
                                            lastRefreshError = result
                                        }
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "brain.head.profile")
                                .interfaceFont(size: 12)
                        }
                        .interfaceFont(size: 12).buttonStyle(.plain).foregroundColor(Color.mimo.brand)
                        .help("Refresh effort/thinking levels from web UI")

                        if let err = lastRefreshError {
                            Text(err).interfaceFont(size: 10).foregroundColor(Color.mimo.error)
                        }
                    }
                }

                // Expandable discovered models list (compact)
                if showDiscoveredModels && !config.discoveredModels.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(config.discoveredModels.prefix(8)) { model in
                            Text(model.name).interfaceFont(size: 10).foregroundColor(Color.mimo.textMuted)
                        }
                        if config.discoveredModels.count > 8 {
                            Text("+ \(config.discoveredModels.count - 8) more")
                                .interfaceFont(size: 10).foregroundColor(Color.mimo.textMuted)
                        }
                    }
                    .frame(maxWidth: 200)
                    .padding(6)
                    .background(Color.mimo.surface)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mimo.border, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                Button(action: { showRemoveConfirmation = true }) {
                    Image(systemName: "trash").interfaceFont(size: 12).foregroundColor(Color.mimo.error)
                }
                .buttonStyle(.plain)
                .help("Remove this web provider and its saved session")
                .alert("Remove \(config.displayName)?", isPresented: $showRemoveConfirmation) {
                    Button("Remove", role: .destructive, action: onRemove)
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("The saved browser session and provider settings will be deleted.")
                }
            }

            // System prompt — compact when empty, grows with content
            if config.systemPrompt.isEmpty {
                HStack {
                    Text(L.t(AppLocalizationKey.locSystemPrompt)).interfaceFont(size: 11, weight: .medium).foregroundColor(Color.mimo.textMuted)
                    Spacer()
                    Menu {
                        ForEach(Self.systemPromptTemplates, id: \.name) { template in
                            Button(template.name) {
                                config.systemPrompt = template.prompt
                            }
                        }
                        Divider()
                        Button("Clear") { config.systemPrompt = "" }
                    } label: {
                        Label("Templates", systemImage: "doc.on.doc")
                            .interfaceFont(size: 10)
                            .foregroundColor(Color.mimo.brand)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L.t(AppLocalizationKey.locSystemPrompt)).interfaceFont(size: 11, weight: .medium).foregroundColor(Color.mimo.textMuted)
                        Spacer()
                        Button("Clear") { config.systemPrompt = "" }
                            .interfaceFont(size: 10).buttonStyle(.plain).foregroundColor(Color.mimo.error)
                    }
                    TextEditor(text: $config.systemPrompt)
                        .font(.system(size: 12))
                        .frame(minHeight: 24, maxHeight: 100)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mimo.border, lineWidth: 1))
                }
            }

            // Models are discovered from the authenticated page and selected
            // from the shared chat composer. Do not expose a second manual
            // browser model picker that can drift from the real web UI.
            VStack(alignment: .leading, spacing: 4) {
                Text(L.t(AppLocalizationKey.locModelEffortAreChosenTheChatInputAfterConnecting))
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
                HStack(spacing: 6) {
                    MiMoLogoMark(size: 16)
                    Text(config.discoveredModels.isEmpty
                         ? "MiCoder Auto Free will detect models after login"
                         : "MiCoder Auto Free detected \(config.allModels.count) models")
                        .interfaceFont(size: 10)
                        .foregroundColor(config.discoveredModels.isEmpty ? Color.mimo.textMuted : Color.mimo.success)
                }
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .interfaceFont(size: 11)
                    Text(config.discoveredEffortLevels.isEmpty
                         ? "Effort: not detected"
                         : "Effort: \(config.discoveredEffortLevels.map(\.displayName).joined(separator: ", "))")
                        .interfaceFont(size: 10)
                    if config.effortDropdown != nil {
                        Text("· selector available")
                            .interfaceFont(size: 10)
                            .foregroundColor(Color.mimo.success)
                    }
                }
                .foregroundColor(Color.mimo.textMuted)
            }

            // Delay + keep-alive
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("\(L.t(AppLocalizationKey.locToolCallDelay)): \(config.toolCallDelayMs) ms")
                        .interfaceFont(size: 11).foregroundColor(Color.mimo.textMuted)
                    Slider(value: Binding(get: { Double(config.toolCallDelayMs) },
                                          set: { config.toolCallDelayMs = Int($0) }),
                           in: 0...3000, step: 100)
                }
                VStack(alignment: .leading) {
                    Text("\(L.t(AppLocalizationKey.locKeepalive)): \(config.sessionKeepAliveSec)s")
                        .interfaceFont(size: 11).foregroundColor(Color.mimo.textMuted)
                    Slider(value: Binding(get: { Double(config.sessionKeepAliveSec) },
                                          set: { config.sessionKeepAliveSec = Int($0) }),
                           in: 30...600, step: 30)
                }
            }

            // The current production transport is the embedded WKWebView. Do
            // not expose a Chrome/CDP option that the send path cannot honor.
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .foregroundColor(Color.mimo.brand)
                Text("In-app browser")
                    .interfaceFont(size: 11, weight: .medium)
                Text("WKWebView")
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)
                Spacer()
            }
            .onAppear {
                if config.transport != .playwrightMCP {
                    config.transport = .playwrightMCP
                }
            }

        }
        .padding(12)
        .background(Color.mimo.surface)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onChange(of: config) { _ in onSave() }
    }
}

/// Editor for custom web-model ids. Users can add any model name manually;
/// it is appended to the provider's discoveredModels and persisted.
struct CustomModelEditor: View {
    @Binding var config: WebProviderConfig
    let onSave: () -> Void
    @State private var newModelName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L.t(AppLocalizationKey.locCustomModels))
                .interfaceFont(size: 11, weight: .medium)
                .foregroundColor(Color.mimo.textMuted)

            // Existing manually added models with remove buttons. Discovered
            // vendor models are read-only and must not expose a no-op delete.
            if !config.manuallyAddedModels.isEmpty {
                ForEach(config.manuallyAddedModels, id: \.self) { model in
                    HStack(spacing: 6) {
                        Text(model)
                            .interfaceFont(size: 11)
                            .foregroundColor(Color.mimo.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Button(action: {
                            config.removeCustomModel(model)
                            onSave()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .interfaceFont(size: 12)
                                .foregroundColor(Color.mimo.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Add new custom model
            HStack(spacing: 6) {
                TextField(L.t(AppLocalizationKey.locAddModel), text: $newModelName)
                    .interfaceFont(size: 11)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addModel()
                    }
                Button("Add") {
                    addModel()
                }
                .interfaceFont(size: 11)
                .buttonStyle(.plain)
                .foregroundColor(Color.mimo.brand)
                .disabled(newModelName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addModel() {
        let name = newModelName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        config.addCustomModel(name)
        newModelName = ""
        onSave()
    }
}

/// Embedded login: opens the vendor's chat URL; the user logs in once; on close
/// we capture cookies for session persistence (plan Раздел 12 Блок 3 п.35).
struct WebProviderLoginView: View {
    @State var config: WebProviderConfig
    let onCookies: ([BrowserCookie]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var webView = WKWebView()

    @State private var detectResult: DetectResult?
    @State private var capturedCookies: [BrowserCookie] = []

    // Capturing a valid logged-in session is independent from model discovery.
    // DOM discovery and AI-assisted discovery are optional helpers, not a gate.
    private var canCapture: Bool {
        // Capturing a valid logged-in session must not depend on model discovery.
        // Discovery can fail because a vendor changed its DOM while cookies are
        // still perfectly usable for chat.
        !capturedCookies.isEmpty || webView.url != nil ||
            !config.discoveredModels.isEmpty || config.customModelSelector != nil
    }

    enum DetectResult: Identifiable {
        case detecting, found([WebProviderModel]), failed(String)
        var id: String {
            switch self {
            case .detecting: return "detecting"
            case .found(let m): return "found-\(m.count)"
            case .failed(let e): return "failed-\(e)"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Compact header bar (Apple Design style) — shows real config status
            HStack(spacing: 8) {
                Text("\(L.t(AppLocalizationKey.locWebLoginTitle)) \(config.displayName)")
                    .interfaceFont(size: 13, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)

                Spacer()

                // Live status: cookies + detected models count
                if !capturedCookies.isEmpty {
                    Label("\(capturedCookies.count) cookies", systemImage: "lock.fill")
                        .interfaceFont(size: 10).foregroundColor(Color.mimo.success)
                } else {
                    Label(L.t(AppLocalizationKey.locNotConfigured), systemImage: "exclamationmark.circle")
                        .interfaceFont(size: 10).foregroundColor(Color.mimo.warning)
                }

                HStack(spacing: 4) {
                    Image(systemName: "bolt.horizontal.circle")
                        .interfaceFont(size: 14)
                    Text("Browser model detection")
                        .interfaceFont(size: 11)
                        .foregroundColor(Color.mimo.textSecondary)
                }
                .help("Choose how MiCoder reads model names from the authenticated web page")

                Button(action: findModelsBuiltIn) {
                    HStack(spacing: 4) {
                        if case .detecting = detectResult {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "bolt.horizontal.circle")
                                .interfaceFont(size: 14)
                        }
                        Text("Detect models")
                            .interfaceFont(size: 11)
                    }
                    .foregroundColor(Color.mimo.brand)
                }
                .buttonStyle(.plain)
                .disabled({
                    if case .detecting = detectResult { return true }
                    return false
                }())
                .help("Fast built-in DOM scraping; no AI request")

                Button(action: findModelsWithAI) {
                    HStack(spacing: 4) {
                        MiMoLogoMark(size: 14)
                        Text("Ask free AI")
                            .interfaceFont(size: 11)
                    }
                    .foregroundColor(Color.mimo.brand)
                }
                .buttonStyle(.plain)
                .disabled({
                    if case .detecting = detectResult { return true }
                    return !MiCoderAutoFreeStore.shared.provider.isReady
                }())
                .help("Ask MiCoder Auto Free to read the visible page text and list model names")

                // Capture only enabled when we have models OR user explicitly wants session
                Button(action: capture) {
                    Text(L.t(AppLocalizationKey.locWebCaptureSession))
                        .interfaceFont(size: 11)
                        .foregroundColor(canCapture ? Color.mimo.success : Color.mimo.textMuted)
                }
                .buttonStyle(.plain)
                .disabled(!canCapture)
                .help(canCapture ? "Save session & models" : "Detect models first")

                // Close button (always available)
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .interfaceFont(size: 12)
                        .foregroundColor(Color.mimo.textSecondary)
                }
                .buttonStyle(.plain)
                .help(L.t(AppLocalizationKey.locClose))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            // Inline detection result (compact, doesn't block the view)
            if let result = detectResult {
                detectionStatusBar(result)
            }

            Divider()
            ZStack {
                WebViewRepresentable(webView: webView, url: config.chatURL)
            }
        }
        .frame(width: 900, height: 640)
        .task(id: config.id) {
            // Pre-load existing cookies to show real status
            if let store = WebSessionManager.restore(providerId: config.id, homeDirectory: FileManager.default.homeDirectoryForCurrentUser) {
                capturedCookies = store.cookies
            }
            // Model discovery is explicit: the user can choose fast DOM scraping
            // or the separate free-AI-assisted mode above.
        }
    }

    @ViewBuilder
    private func detectionStatusBar(_ result: DetectResult) -> some View {
        HStack(spacing: 6) {
            switch result {
            case .detecting:
                ProgressView().controlSize(.mini)
                Text(L.t(AppLocalizationKey.locWebDetecting)).interfaceFont(size: 10)
            case .found(let models):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.mimo.success)
                Text("\(models.count) \(L.t(AppLocalizationKey.locWebModelsFound))")
                    .interfaceFont(size: 10).foregroundColor(Color.mimo.textSecondary)
                ForEach(models.prefix(3)) { m in
                    Text(m.name).interfaceFont(size: 9)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(Color.mimo.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                if models.count > 3 {
                    Text("+\(models.count - 3)").interfaceFont(size: 9)
                        .foregroundColor(Color.mimo.textMuted)
                }
            case .failed(let err):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color.mimo.warning)
                Text(err).interfaceFont(size: 10).foregroundColor(Color.mimo.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.mimo.surface)
    }

    private func findModelsBuiltIn() {
        Task {
            await MainActor.run { detectResult = .detecting }
            let bridge = WKWebViewBrowserBridge(webView: webView, selectors: WebVendorSelectors(input: "", sendButton: "", responseContainer: "", stopButton: ""))
            let dropdownSelector = config.customModelSelector
                ?? (try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id))?.modelDropdown
                ?? ""
            if dropdownSelector.isEmpty {
                await MainActor.run { detectResult = .failed("No selector found for this vendor.") }
                return
            }
            // Wait for full page hydration (up to 10s)
            for _ in 0..<40 {
                if (try? await bridge.exists(selector: dropdownSelector)) == true {
                    break
                }
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            // Try to discover models from the dropdown
            let models = await WebModelDiscovery.discover(using: bridge, dropdownSelector: dropdownSelector, vendor: config.vendor) ?? []
            await MainActor.run {
                if models.isEmpty {
                    detectResult = .failed("No models found in dropdown.")
                } else {
                    detectResult = .found(models)
                    // Save discovered models to store AND update local config
                    var updated = config
                    updated.discoveredModels = models
                    WebProviderStore.save(WebProviderStore.upsert(updated, in: WebProviderStore.load()))
                    // Update local config so canCapture becomes true
                    config = updated
                }
            }
        }
    }

    private func findModelsWithAI() {
        Task {
            await MainActor.run { detectResult = .detecting }
            let bridge = WKWebViewBrowserBridge(webView: webView, selectors: WebVendorSelectors(input: "", sendButton: "", responseContainer: "", stopButton: ""))
            do {
                let pageText = try await bridge.pageText()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard !pageText.isEmpty else {
                    await MainActor.run { detectResult = .failed("The authenticated page has no readable text.") }
                    return
                }

                let prompt = """
                Read the visible text from a \(config.displayName) web chat page below. Extract only selectable model names currently visible in its model menu. Return a JSON array of strings, with one exact model label per item and no explanations. If no model names are visible, return [].

                PAGE TEXT:
                \(String(pageText.prefix(20_000)))
                """
                var answer = ""
                let messages = [
                    MiCoderAutoFreeClient.Message(
                        role: "system",
                        content: "You extract UI model labels exactly. Never invent a model name. Return only valid JSON."
                    ),
                    MiCoderAutoFreeClient.Message(role: "user", content: prompt)
                ]
                for try await chunk in MiCoderAutoFreeStore.shared.streamChat(messages: messages) {
                    answer += chunk
                }
                let models = parseAIDetectedModels(answer)
                saveDetectedModels(models)
            } catch {
                await MainActor.run { detectResult = .failed("AI detection failed: \(error.localizedDescription)") }
            }
        }
    }

    private func parseAIDetectedModels(_ answer: String) -> [WebProviderModel] {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        if let data = trimmed.data(using: .utf8),
           let names = try? JSONSerialization.jsonObject(with: data) as? [String] {
            return uniqueModelNames(names)
        }

        // Be tolerant of a fenced JSON response from a provider-side wrapper.
        if let start = trimmed.firstIndex(of: "["),
           let end = trimmed.lastIndex(of: "]"), start <= end {
            let candidate = String(trimmed[start...end])
            if let data = candidate.data(using: .utf8),
               let names = try? JSONSerialization.jsonObject(with: data) as? [String] {
                return uniqueModelNames(names)
            }
        }
        return uniqueModelNames(trimmed.components(separatedBy: .newlines))
    }

    private func uniqueModelNames(_ rawNames: [String]) -> [WebProviderModel] {
        var seen = Set<String>()
        return rawNames.compactMap { raw in
            var name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            name = name.replacingOccurrences(of: "^[\\s`\\\"'•*-]+", with: "", options: .regularExpression)
            name = name.replacingOccurrences(of: "^[0-9]+[.)]\\s*", with: "", options: .regularExpression)
            name = name.replacingOccurrences(of: "[`\\\"']", with: "", options: .regularExpression)
            guard !name.isEmpty, name.count <= 100,
                  !name.contains(":"), !name.contains("\n"),
                  seen.insert(name.lowercased()).inserted else { return nil }
            return WebProviderModel(name: name)
        }
    }

    @MainActor
    private func saveDetectedModels(_ models: [WebProviderModel]) {
        guard !models.isEmpty else {
            detectResult = .failed("No model names were returned by the free AI.")
            return
        }
        detectResult = .found(models)
        var updated = config
        updated.discoveredModels = models
        WebProviderStore.save(WebProviderStore.upsert(updated, in: WebProviderStore.load()))
        config = updated
    }

    private func capture() {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            let mapped = cookies.map {
                BrowserCookie(name: $0.name, value: $0.value, domain: $0.domain, path: $0.path,
                              expiresEpoch: $0.expiresDate?.timeIntervalSince1970,
                              httpOnly: $0.isHTTPOnly, secure: $0.isSecure)
            }
            capturedCookies = mapped  // Update UI immediately
            onCookies(mapped)
            dismiss()
        }
    }
}

struct WebViewRepresentable: NSViewRepresentable {
    let webView: WKWebView
    let url: String

    func makeNSView(context: Context) -> WKWebView {
        if let u = URL(string: url) { webView.load(URLRequest(url: u)) }
        return webView
    }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}

/// Keeps the persistent chat WebView attached to the AppKit hierarchy so
/// WebKit loads pages and executes JavaScript. A cached but unattached WKWebView
/// can be created successfully while never becoming a usable browser surface.
struct WebChatWebViewHost: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView { webView }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
