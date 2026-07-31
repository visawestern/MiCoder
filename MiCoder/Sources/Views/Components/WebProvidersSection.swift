import SwiftUI
import WebKit

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
                                onRemove: { remove(cfg) })
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
        guard WebModelDiscovery.canRefresh(cfg),
              let selector = try? WebProviderCatalog.loadBundled().selectors(for: cfg.vendor.id)?.modelDropdown else { return }
        #if canImport(WebKit)
        let webView = appState.webView(for: cfg)
        let selectors = WebVendorSelectors(input: "", sendButton: "", responseContainer: "", stopButton: "")
        let bridge = WKWebViewBrowserBridge(webView: webView, selectors: selectors)
        if let models = await WebModelDiscovery.discover(using: bridge,
                                                         dropdownSelector: selector,
                                                         vendor: cfg.vendor) {
            var updated = cfg
            updated.discoveredModels = models
            providers = WebProviderStore.upsert(updated, in: providers)
            save()
        }
        #endif
    }
}

/// Editable card for one web provider (plan Раздел 12 Блок 4 п.43-47).
struct WebProviderCard: View {
    @Binding var config: WebProviderConfig
    let onSave: () -> Void
    let onLogin: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(config.displayName)
                    .interfaceFont(size: 14, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Spacer()
                Button("Log in") { onLogin() }
                    .interfaceFont(size: 12).buttonStyle(.plain).foregroundColor(Color.mimo.brand)
                Button(action: onRemove) {
                    Image(systemName: "trash").interfaceFont(size: 12).foregroundColor(Color.mimo.error)
                }
                .buttonStyle(.plain)
            }

            // System prompt
            Text("System prompt").interfaceFont(size: 11, weight: .medium).foregroundColor(Color.mimo.textMuted)
            TextEditor(text: $config.systemPrompt)
                .frame(height: 60)
                .font(.system(size: 12))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mimo.border, lineWidth: 1))

            // Model + effort are NOT chosen here (plan Раздел 13 п.5): the model
            // is picked in the chat input like any other provider, and effort is
            // determined dynamically from the model's capabilities.
            Text("Model & effort are chosen in the chat input after connecting.")
                .interfaceFont(size: 11)
                .foregroundColor(Color.mimo.textMuted)

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
