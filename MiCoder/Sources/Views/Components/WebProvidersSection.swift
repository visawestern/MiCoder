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
            Text("Web providers (browser)")
                .interfaceFont(size: 18, weight: .semibold)
                .foregroundColor(Color.mimo.textPrimary)
            Text("Use free web models (Kimi, Qwen, ChatGPT) through a controlled browser. Tools (read_file/write_file/…) are emulated over the chat. Automating a third-party service may violate its Terms of Service — enable only if you accept that.")
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
                            Text(providers.contains { $0.vendor == vendor } ? "Configured" : "Add")
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
                                onRefreshModels: { Task { await refreshModels(for: cfg) } },
                                onRefreshEffort: { Task { await refreshEffort(for: cfg) } },
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
    private func refreshModels(for cfg: WebProviderConfig) async {
        #if canImport(WebKit)
        _ = await appState.refreshWebModels(for: cfg)
        providers = WebProviderStore.load()
        #endif
    }

    /// Refresh the available effort/thinking levels for a web provider.
    private func refreshEffort(for cfg: WebProviderConfig) async {
        #if canImport(WebKit)
        _ = await appState.refreshWebEffort(for: cfg)
        providers = WebProviderStore.load()
        #endif
    }
}

/// Editable card for one web provider (plan Раздел 12 Блок 4 п.43-47).
struct WebProviderCard: View {
    @Binding var config: WebProviderConfig
    let onSave: () -> Void
    let onLogin: () -> Void
    let onRemove: () -> Void
    let onRefreshModels: () -> Void
    let onRefreshEffort: () -> Void
    let homeDirectory: URL

    @State private var isRefreshing = false
    @State private var lastRefreshError: String?
    @State private var systemPromptHeight: CGFloat = 28
    @State private var showSaveConfirmation = false

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
                    Button("Log in") { onLogin() }
                        .interfaceFont(size: 12).buttonStyle(.plain).foregroundColor(Color.mimo.brand)
                } else {
                    HStack(spacing: 8) {
                        Button(action: {
                            isRefreshing = true
                            lastRefreshError = nil
                            Task {
                                onRefreshModels()
                                await MainActor.run {
                                    isRefreshing = false
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
                        .help(isRefreshing ? "Refreshing models…" : "Refresh models from web UI")
                        
                        Button(action: {
                            Task { onRefreshEffort() }
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
                Button(action: onRemove) {
                    Image(systemName: "trash").interfaceFont(size: 12).foregroundColor(Color.mimo.error)
                }
                .buttonStyle(.plain)
            }

            // System prompt
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("System prompt").interfaceFont(size: 11, weight: .medium).foregroundColor(Color.mimo.textMuted)
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
                    Spacer()
                    Button("Save") {
                        onSave()
                        withAnimation(.easeOut(duration: 0.15)) {
                            showSaveConfirmation = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { showSaveConfirmation = false }
                        }
                    }
                    .interfaceFont(size: 11).buttonStyle(.plain).foregroundColor(Color.mimo.success)
                    .opacity(showSaveConfirmation ? 1 : 0.5)
                    .disabled(config.systemPrompt.isEmpty)
                }

                // Auto-sizing TextEditor: starts at 1 line (~28pt), grows with content
                ZStack(alignment: .topLeading) {
                    if config.systemPrompt.isEmpty {
                        Text("Optional system prompt… templates available above")
                            .interfaceFont(size: 12)
                            .foregroundColor(Color.mimo.textMuted)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 6)
                    }
                    TextEditor(text: $config.systemPrompt)
                        .font(.system(size: 12))
                        .frame(minHeight: systemPromptHeight, maxHeight: 120)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mimo.border, lineWidth: 1))
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: TextHeightPreferenceKey.self, value: geo.size.height)
                            }
                        )
                        .onPreferenceChange(TextHeightPreferenceKey.self) { h in
                            systemPromptHeight = max(28, min(h + 8, 120))
                        }
                }
            }

            // Model + effort are NOT chosen here (plan Раздел 13 п.5): the model
            // is picked in the chat input like any other provider, and effort is
            // determined dynamically from the model's capabilities.
            Text("Model & effort are chosen in the chat input after connecting.")
                .interfaceFont(size: 11)
                .foregroundColor(Color.mimo.textMuted)

            // Custom models — manually add any model id (duplicates with
            // auto-discovered are allowed; they just become separate entries).
            CustomModelEditor(config: $config, onSave: onSave)

            // Delay + keep-alive
            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Tool-call delay: \(config.toolCallDelayMs) ms")
                        .interfaceFont(size: 11).foregroundColor(Color.mimo.textMuted)
                    Slider(value: Binding(get: { Double(config.toolCallDelayMs) },
                                          set: { config.toolCallDelayMs = Int($0) }),
                           in: 0...3000, step: 100)
                }
                VStack(alignment: .leading) {
                    Text("Keep-alive: \(config.sessionKeepAliveSec)s")
                        .interfaceFont(size: 11).foregroundColor(Color.mimo.textMuted)
                    Slider(value: Binding(get: { Double(config.sessionKeepAliveSec) },
                                          set: { config.sessionKeepAliveSec = Int($0) }),
                           in: 30...600, step: 30)
                }
            }

            // Transport + ToS
            Picker("Transport", selection: $config.transport) {
                Text("Managed browser").tag(WebTransport.playwrightMCP)
                Text("Existing Chrome (cookies)").tag(WebTransport.cdpCookies)
            }
            .pickerStyle(.segmented)

            Toggle("I understand this may violate the service's Terms of Service", isOn: $config.acknowledgedToS)
                .interfaceFont(size: 11)
                .foregroundColor(Color.mimo.textSecondary)
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
            Text("Custom models")
                .interfaceFont(size: 11, weight: .medium)
                .foregroundColor(Color.mimo.textMuted)

            // Existing custom models with remove buttons
            if !config.discoveredModels.isEmpty {
                ForEach(config.discoveredModels, id: \.self) { model in
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
                TextField("Add model name…", text: $newModelName)
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
    let config: WebProviderConfig
    let onCookies: ([BrowserCookie]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var webView = WKWebView()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Log in to \(config.displayName)")
                    .interfaceFont(size: 13, weight: .semibold)
                Spacer()
                Button("Capture session & close") { capture() }
                    .interfaceFont(size: 12)
            }
            .padding(10)
            Divider()
            WebViewRepresentable(webView: webView, url: config.chatURL)
        }
        .frame(width: 900, height: 640)
    }

    private func capture() {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            let mapped = cookies.map {
                BrowserCookie(name: $0.name, value: $0.value, domain: $0.domain, path: $0.path,
                              expiresEpoch: $0.expiresDate?.timeIntervalSince1970,
                              httpOnly: $0.isHTTPOnly, secure: $0.isSecure)
            }
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
