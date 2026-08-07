import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebar()
            
            Divider()
            
            SettingsContent()
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.mimo.background)
        .preferredColorScheme(appState.appTheme.preferredColorScheme)
    }
}

struct SettingsSidebar: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { appState.showSettings = false }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .interfaceFont(size: 12)
                    Text(AppLocalization.string(.settingsBackToWorkspace, language: appState.appLanguage))
                        .interfaceFont(size: 13)
                }
                .foregroundColor(Color.mimo.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(SettingsTab.visibleCases) { tab in
                        SettingsTabRow(tab: tab)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
        }
        .frame(width: 220)
        .background(Color.mimo.backgroundAlt)
    }
}

struct SettingsTabRow: View {
    let tab: SettingsTab
    @EnvironmentObject var appState: AppState
    
    var isSelected: Bool { appState.settingsTab == tab }
    
    var body: some View {
        Button(action: { appState.settingsTab = tab }) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .interfaceFont(size: 14)
                    .foregroundColor(isSelected ? Color.mimo.textPrimary : Color.mimo.textMuted)
                    .frame(width: 20)
                
                Text(AppLocalization.settingsTabName(tab, language: appState.appLanguage))
                    .interfaceFont(size: 13)
                    .foregroundColor(isSelected ? Color.mimo.textPrimary : Color.mimo.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.mimo.surface : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}

struct SettingsContent: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch appState.settingsTab {
                    case .general:
                        GeneralSettingsView()
                    case .codePreview:
                        CodePreviewSettingsView()
                    case .modelSettings, .providers:
                        // Unified Providers tab (plan Раздел 1): model/provider
                        // selection columns + provider management + local providers.
                        UnifiedProvidersView(availableWidth: max(0, geometry.size.width - 64))
                    case .skills:
                        SkillsSettingsView()
                    case .mcpServers:
                        MCPServersSettingsView()
                    case .plugins:
                        PluginsSettingsView()
                    case .commands:
                        CommandsSettingsView()
                    case .indexing:
                        IndexingSettingsView()
                    case .storage:
                        StorageSettingsView()
                    case .usage:
                        UsageSettingsView()
                    }
                }
                .padding(32)
            }
        }
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState

    private var language: AppLanguage { appState.appLanguage }

    private var terminalFontBinding: Binding<String> {
        Binding(
            get: { appState.settings.terminalFont },
            set: { newValue in appState.updateSettings { $0.terminalFont = newValue } }
        )
    }

    private var inheritTerminalBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.inheritTerminalProfile },
            set: { newValue in appState.updateSettings { $0.inheritTerminalProfile = newValue } }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(AppLocalization.string(.settingsGeneralTitle, language: language))
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)
            
            HStack(spacing: 8) {
                Text(AppLocalization.string(.settingsGeneralTitle, language: language))
                    .interfaceFont(size: 12, weight: .medium)
                    .foregroundColor(Color.mimo.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.mimo.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.mimo.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text(appState.appTheme.rawValue)
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textSecondary)
                
                Text(appState.appLanguage.rawValue)
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textSecondary)
            }
            
            SettingsCard {
                SettingsRow(
                    title: AppLocalization.string(.settingsAppThemeTitle, language: language),
                    description: AppLocalization.string(.settingsAppThemeDescription, language: language)
                ) {
                    SettingsMenuLabel(title: appState.appTheme.rawValue) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Button(theme.rawValue) {
                                appState.appTheme = theme
                            }
                        }
                    }
                }
                
                SettingsRow(
                    title: AppLocalization.string(.settingsLanguageTitle, language: language),
                    description: AppLocalization.string(.settingsLanguageDescription, language: language)
                ) {
                    LanguagePickerDropdown(
                        selected: appState.appLanguage,
                        onSelect: { appState.setLanguage($0) }
                    )
                }
                
                SettingsRow(
                    title: AppLocalization.string(.settingsInterfaceZoomTitle, language: language),
                    description: AppLocalization.string(.settingsInterfaceZoomDescription, language: language)
                ) {
                    HStack(spacing: 0) {
                        ForEach(AppSettings.Zoom.allCases, id: \.self) { zoom in
                            Button(action: {
                                appState.updateSettings { $0.zoom = zoom }
                            }) {
                                Text(zoom.rawValue)
                                    .interfaceFont(size: 13, weight: appState.settings.zoom == zoom ? .semibold : .regular)
                                    .foregroundColor(appState.settings.zoom == zoom ? Color.mimo.textPrimary : Color.mimo.textMuted)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        appState.settings.zoom == zoom
                                            ? RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.mimo.surface)
                                            : nil
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(Color.mimo.backgroundAlt)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            SettingsCard {
                SettingsToggleRow(
                    title: AppLocalization.string(.settingsInheritTerminalTitle, language: language),
                    description: AppLocalization.string(.settingsInheritTerminalDescription, language: language),
                    isOn: inheritTerminalBinding
                )
                
                SettingsRow(
                    title: AppLocalization.string(.settingsTerminalFontTitle, language: language),
                    description: AppLocalization.string(.settingsTerminalFontDescription, language: language)
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        TextField(
                            AppLocalization.string(.settingsTerminalFontPlaceholder, language: language),
                            text: terminalFontBinding
                        )
                        .zcodeTextFieldStyle()
                        .interfaceFont(size: 13, design: .monospaced)

                        Text(TerminalFontResolver.displayLabel(settings: appState.settings, language: language))
                            .interfaceFont(size: 11, design: .monospaced)
                            .foregroundColor(Color.mimo.textMuted)
                    }
                }
            }
            
            SettingsCard {
                SettingsRow(title: "HTTP Proxy", description: "Route model, MCP, command-tool, and app renderer egress traffic through this proxy. Leave blank for direct connections; system environment variables are not read. Restart the app to take effect.") {
                    TextField("Leave blank for direct connection", text: $appState.settings.httpProxy)
                        .zcodeTextFieldStyle()
                        .interfaceFont(size: 13)
                }
            }
        }
    }
}

struct CodePreviewSettingsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Code preview")
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)
            
            SettingsCard {
                SettingsRow(title: "Light code theme", description: "Theme used for code blocks while the interface is in light mode.") {
                    SettingsMenuLabel(title: appState.settings.lightCodeTheme) {
                        ForEach(["GitHub Light", "GitHub Dark", "One Light", "Solarized Light"], id: \.self) { theme in
                            Button(theme) {
                                appState.updateSettings { $0.lightCodeTheme = theme }
                            }
                        }
                    }
                }
                
                SettingsRow(title: "Dark code theme", description: "Theme used for code blocks while the interface is in dark mode.") {
                    SettingsMenuLabel(title: appState.settings.darkCodeTheme) {
                        ForEach(["GitHub Dark", "GitHub Light", "One Dark", "Solarized Dark", "Dracula"], id: \.self) { theme in
                            Button(theme) {
                                appState.updateSettings { $0.darkCodeTheme = theme }
                            }
                        }
                    }
                }
                
                SettingsToggleRow(title: "Show line numbers", description: "Display line numbers in code previews.", isOn: $appState.settings.showLineNumbers)
                
                SettingsToggleRow(title: "Wrap long lines", description: "Wrap long content inside the preview area automatically.", isOn: $appState.settings.wrapLongLines)
                
                SettingsRow(title: "Code font size", description: "Adjust the default font size used by code previews.") {
                    HStack {
                        Slider(value: Binding(
                            get: { Double(appState.settings.codeFontSize) },
                            set: { appState.settings.codeFontSize = Int($0) }
                        ), in: 8...24, step: 1)
                        Text("\(appState.settings.codeFontSize)")
                            .interfaceFont(size: 12, design: .monospaced)
                            .foregroundColor(Color.mimo.textMuted)
                            .frame(width: 30)
                    }
                }
            }
        }
    }
}

struct ModelSettingsView: View {
    let availableWidth: CGFloat
    @EnvironmentObject var appState: AppState
    @State private var showAddProvider = false
    @State private var newProviderName = ""
    @State private var newProviderType: ProviderType = .openAI
    @State private var newProviderURL = ""
    @State private var newProviderKey = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Model settings")
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)
            
            Text("Configure model providers and manage available models.")
                .interfaceFont(size: 14)
                .foregroundColor(Color.mimo.textSecondary)
            
            ModelSettingsProviderColumns(
                showAddProvider: $showAddProvider,
                availableWidth: availableWidth
            )
        }
        .sheet(isPresented: $showAddProvider) {
            AddProviderSheet(
                isPresented: $showAddProvider,
                name: $newProviderName,
                type: $newProviderType,
                url: $newProviderURL,
                apiKey: $newProviderKey
            )
            .environmentObject(appState)
        }
    }

}

struct ModelSettingsProviderColumns: View {
    @EnvironmentObject var appState: AppState
    @Binding var showAddProvider: Bool
    let availableWidth: CGFloat
    @State private var detailProviderID: String = ""
    @State private var customAPIKeyDraft: String = ""
    @State private var customBaseURLDraft: String = ""

    private var options: [ProviderOption] {
        appState.providerOptions
    }

    private func webConfig(for providerID: String) -> WebProviderConfig? {
        guard let id = WebProviderConnectivity.configID(fromOptionID: providerID) else { return nil }
        return WebProviderStore.load().first(where: { $0.id == id })
    }

    private func models(for providerID: String) -> [String] {
        if let web = webConfig(for: providerID) {
            return WebProviderConnectivity.models(for: web)
        }
        if let local = LocalProviderLogic.load().first(where: { $0.id == providerID }) {
            return local.models
        }
        return ProviderSettingsLogic.models(
            for: providerID,
            in: appState.serverProviders,
            customProviders: appState.customProviders
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Providers & models")
                    .interfaceFont(size: 16, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Spacer()
                Button(action: { showAddProvider = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add provider")
                    }
                    .interfaceFont(size: 13)
                    .foregroundColor(Color.mimo.brand)
                }
                .buttonStyle(.plain)
            }

            if layoutMode == .wide {
                HStack(alignment: .top, spacing: 12) {
                    providerListColumn
                        .frame(width: 200)
                    providerDetailColumn
                        .frame(width: 240)
                    modelsColumn
                        .frame(minWidth: 280, maxWidth: .infinity, alignment: .topLeading)
                        .layoutPriority(1)
                }
                // Custom-provider credentials and endpoint controls need more
                // room than the old 320pt card allowed; otherwise the Save /
                // Refresh actions were clipped and effectively unreachable.
                .frame(minHeight: 320, maxHeight: 480)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        providerListColumn
                            .frame(maxWidth: .infinity)
                        providerDetailColumn
                            .frame(maxWidth: .infinity)
                    }
                    .frame(minHeight: 180, maxHeight: 240)

                    modelsColumn
                        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
                }
            }
        }
        .onAppear {
            if detailProviderID.isEmpty {
                // Prefill so Details/Models are populated instead of blank.
                detailProviderID = appState.selectedProviderID.isEmpty
                    ? (options.first?.id ?? "")
                    : appState.selectedProviderID
            }
        }
        .onChange(of: appState.selectedProviderID) { newValue in
            if !newValue.isEmpty {
                detailProviderID = newValue
            }
        }
    }

    private var layoutMode: ModelSettingsLayoutMode {
        ModelSettingsLayoutLogic.mode(availableWidth: availableWidth)
    }

    private var providerListColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Providers")
                .interfaceFont(size: 12, weight: .semibold)
                .foregroundColor(Color.mimo.textMuted)
                .padding(.bottom, 8)

            if options.isEmpty {
                SettingsCardEmptyState(
                    icon: "server.rack",
                    title: "No providers yet",
                    hint: "Connect the local agent or add a custom provider to get started.",
                    actionTitle: L.t("Add provider"),
                    action: { showAddProvider = true }
                )
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(options) { option in
                            Button(action: {
                                detailProviderID = option.id
                                appState.selectProvider(option.id)
                            }) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(option.isConnected ? Color.mimo.success : Color.mimo.textMuted)
                                        .frame(width: 6, height: 6)
                                    Text(option.name)
                                        .interfaceFont(size: 12)
                                        .foregroundColor(Color.mimo.textPrimary)
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                    if appState.selectedProviderID == option.id {
                                        Image(systemName: "checkmark")
                                            .interfaceFont(size: 10)
                                            .foregroundColor(Color.mimo.brand)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    detailProviderID == option.id
                                        ? Color.mimo.subtleFill
                                        : Color.mimo.surface
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            detailProviderID == option.id ? Color.mimo.border : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .settingsCardFrame()
        .padding(12)
        .background(Color.mimo.surface)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var providerDetailColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .interfaceFont(size: 12, weight: .semibold)
                .foregroundColor(Color.mimo.textMuted)

            if let option = options.first(where: { $0.id == detailProviderID }) {
                Text(option.name)
                    .interfaceFont(size: 14, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                HStack(spacing: 6) {
                    Circle()
                        .fill(option.isConnected ? Color.mimo.success : Color.mimo.warning)
                        .frame(width: 8, height: 8)
                    Text(webConfig(for: option.id) != nil ? "Web session" : (option.isCustom ? "Custom provider" : "Local Agent"))
                        .interfaceFont(size: 12)
                        .foregroundColor(Color.mimo.textSecondary)
                }

                detailSummary(for: option)
                if option.isCustom, let custom = appState.customProviders.first(where: { $0.id == option.id }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Base URL")
                            .interfaceFont(size: 11, weight: .medium)
                            .foregroundColor(Color.mimo.textSecondary)
                        TextField("https://api.example.com/v1", text: $customBaseURLDraft)
                            .zcodeTextFieldStyle()
                            .interfaceFont(size: 11, design: .monospaced)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("API Key")
                            .interfaceFont(size: 11, weight: .medium)
                            .foregroundColor(Color.mimo.textSecondary)
                        SecureField(custom.type == .openModel ? "om-..." : "sk-...", text: $customAPIKeyDraft)
                            .zcodeTextFieldStyle()
                            .onAppear {
                                // Read from Keychain first, fall back to plain storage
                                customAPIKeyDraft = custom.getSecureAPIKey() ?? ""
                                customBaseURLDraft = custom.baseURL
                            }
                            .onChange(of: detailProviderID) { _ in
                                customAPIKeyDraft = custom.getSecureAPIKey() ?? ""
                                customBaseURLDraft = custom.baseURL
                            }
                        Button("Save configuration") {
                            let newKey = customAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            let newURL = customBaseURLDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                            // Save the endpoint and API key, then reload models.
                            var updated = custom
                            updated.apiKey = newKey
                            updated.baseURL = newURL
                            appState.updateCustomProvider(updated)
                        }
                        .buttonStyle(.bordered)
                        .disabled(customBaseURLDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  (customAPIKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines) == (custom.getSecureAPIKey() ?? "") &&
                                   customBaseURLDraft.trimmingCharacters(in: .whitespacesAndNewlines) == custom.baseURL))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Enable Tool Calling", isOn: Binding(
                            get: { custom.supportsTools },
                            set: { newValue in
                                var updated = custom
                                updated.supportsTools = newValue
                                appState.updateCustomProvider(updated)
                            }
                        ))
                        .toggleStyle(.switch)
                        .interfaceFont(size: 11)
                        Text("Enable function/tool calling support")
                            .interfaceFont(size: 10)
                            .foregroundColor(Color.mimo.textSecondary)
                    }

                    if custom.type == .acp {
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle("Enable ACP Protocol", isOn: Binding(
                                get: { custom.acpEnabled },
                                set: { newValue in
                                    var updated = custom
                                    updated.acpEnabled = newValue
                                    appState.updateCustomProvider(updated)
                                }
                            ))
                            .toggleStyle(.switch)
                            .interfaceFont(size: 11)
                            Text("Enable Agent Coder Protocol")
                                .interfaceFont(size: 10)
                                .foregroundColor(Color.mimo.textSecondary)
                        }
                    }

                    Button(role: .destructive) {
                        appState.removeCustomProvider(custom)
                    } label: {
                        Label(L.t("Remove provider"), systemImage: "trash")
                            .interfaceFont(size: 12)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color.mimo.error)

                    Button("Refresh models") {
                        appState.refreshModels(for: custom.id)
                    }
                    .buttonStyle(.bordered)

                    if let message = appState.providerModelLoadMessage(for: custom.id) {
                        Text(message)
                            .interfaceFont(size: 10)
                            .foregroundColor(message.hasPrefix("Loaded") ? Color.mimo.success : Color.mimo.warning)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if let web = webConfig(for: option.id) {
                    Text(web.chatURL)
                        .interfaceFont(size: 11, design: .monospaced)
                        .foregroundColor(Color.mimo.textMuted)
                        .lineLimit(2)
                    Text(WebProviderConnectivity.connectionSummary(web, connected: true))
                        .interfaceFont(size: 10)
                        .foregroundColor(Color.mimo.textSecondary)
                    Button("Refresh web models") {
                        Task { _ = await appState.refreshWebModels(for: web) }
                    }
                    .buttonStyle(.bordered)
                }
                if !appState.supportsToolcallForSelection && appState.selectedProviderID == option.id {
                    Text("Tools unavailable for current model")
                        .interfaceFont(size: 11)
                        .foregroundColor(Color.mimo.warning)
                }
            } else {
                SettingsCardEmptyState(
                    icon: "slider.horizontal.3",
                    title: "No provider selected",
                    hint: "Pick a provider on the left to view its connection and settings."
                )
            }
        }
        .settingsCardFrame()
        .padding(12)
        .background(Color.mimo.surface)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func detailModelCount(for providerID: String) -> Int {
        models(for: providerID).count
    }

    @ViewBuilder
    private func detailSummary(for option: ProviderOption) -> some View {
        let modelCount = detailModelCount(for: option.id)
        let isActive = appState.selectedProviderID == option.id

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "cpu")
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)
                Text(modelCount == 1 ? "1 model" : "\(modelCount) models")
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textSecondary)
            }

            if isActive, !appState.selectedModel.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .interfaceFont(size: 10)
                        .foregroundColor(Color.mimo.brand)
                    Text(appState.selectedModel)
                        .interfaceFont(size: 11, weight: .medium)
                        .foregroundColor(Color.mimo.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.mimo.brand.opacity(0.08))
                .clipShape(Capsule())
            }
        }
        .padding(.top, 2)
    }

    /// Разделить modelID на префикс (провайдер) и имя модели
    /// Например "oc/deepseek" → ("oc", "deepseek"), "gpt-4" → (nil, "gpt-4")
    static func splitModelID(_ modelID: String) -> (prefix: String?, name: String) {
        if let slashIndex = modelID.firstIndex(of: "/") {
            let prefix = String(modelID[..<slashIndex])
            let name = String(modelID[modelID.index(after: slashIndex)...])
            return (prefix.isEmpty ? nil : prefix, name)
        }
        return (nil, modelID)
    }

    /// Сгруппировать модели по префиксу (провайдеру)
    static func groupedModels(
        _ models: [String],
        providerID: String,
        serverProviders: [MimoProviderResponse],
        customProviders: [CustomProvider]
    ) -> [(prefix: String?, models: [String])] {
        var grouped: [(String?, [String])] = []
        var seenPrefixes = Set<String>()
        
        for modelID in models {
            let (prefix, _) = splitModelID(modelID)
            let groupKey = prefix ?? ""
            if !seenPrefixes.contains(groupKey) {
                seenPrefixes.insert(groupKey)
                let groupModels = models.filter {
                    let (p, _) = splitModelID($0)
                    return (p ?? "") == groupKey
                }
                grouped.append((prefix, groupModels))
            }
        }
        
        return grouped
    }

    private var modelsColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Models")
                .interfaceFont(size: 12, weight: .semibold)
                .foregroundColor(Color.mimo.textMuted)

            let models = models(for: detailProviderID.isEmpty ? appState.selectedProviderID : detailProviderID)
            let providerID = detailProviderID.isEmpty ? appState.selectedProviderID : detailProviderID

            if models.isEmpty {
                SettingsCardEmptyState(
                    icon: "cpu",
                    title: "No models loaded",
                    hint: providerID.isEmpty
                        ? "Select a provider to browse its models."
                        : "Start the local agent or check the provider connection to load models."
                )
            } else {
                let groups = Self.groupedModels(models, providerID: providerID, serverProviders: appState.serverProviders, customProviders: appState.customProviders)

                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(groups.indices, id: \.self) { groupIndex in
                            let group = groups[groupIndex]
                            VStack(spacing: 2) {
                                if let prefix = group.prefix {
                                    modelGroupHeader(prefix: prefix, count: group.models.count)
                                }
                                ForEach(group.models, id: \.self) { modelID in
                                    compactModelCard(modelID: modelID, providerID: providerID, prefix: group.prefix)
                                }
                            }
                        }
                    }
                }
            }
        }
        .settingsCardFrame()
        .padding(12)
        .background(Color.mimo.surface)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func modelGroupHeader(prefix: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "cube.fill")
                .interfaceFont(size: 10)
                .foregroundColor(Color.mimo.textMuted)
            Text(prefix)
                .interfaceFont(size: 11, weight: .semibold, design: .monospaced)
                .foregroundColor(Color.mimo.textSecondary)
            Text("· \(count)")
                .interfaceFont(size: 10)
                .foregroundColor(Color.mimo.textMuted)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, groupStartPadding)
        .padding(.bottom, 2)
    }

    private var groupStartPadding: CGFloat {
        8
    }

    @ViewBuilder
    private func compactModelCard(modelID: String, providerID: String, prefix: String?) -> some View {
        let meta = ProviderSettingsLogic.model(
            for: modelID,
            in: appState.serverProviders,
            providerID: providerID.isEmpty ? nil : providerID
        )
        let isSelected = appState.selectedModel == modelID
        let shortName = Self.splitModelID(modelID).name

        HStack(spacing: 6) {
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.brand)
                    .frame(width: 14)
            } else {
                Circle()
                    .fill(Color.mimo.border)
                    .frame(width: 6, height: 6)
                    .padding(.horizontal, 4)
            }

            // Model name
            Text(shortName)
                .interfaceFont(size: 12, weight: isSelected ? .semibold : .regular, design: .monospaced)
                .foregroundColor(isSelected ? Color.mimo.brand : Color.mimo.textPrimary)
                .lineLimit(1)

            // Compact capability chips
            if meta?.capabilities?.reasoning == true {
                Text("R")
                    .interfaceFont(size: 8, weight: .bold, design: .monospaced)
                    .foregroundColor(Color.mimo.violet)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.mimo.violet.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            if meta?.capabilities?.toolcall != false {
                Text("T")
                    .interfaceFont(size: 8, weight: .bold, design: .monospaced)
                    .foregroundColor(Color.mimo.cyan)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.mimo.cyan.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            if let context = meta?.limit?.context {
                Text("\(context / 1000)k")
                    .interfaceFont(size: 9)
                    .foregroundColor(Color.mimo.textMuted)
                    .lineLimit(1)
            }

            if meta?.cost != nil {
                Text("$")
                    .interfaceFont(size: 8, weight: .bold, design: .monospaced)
                    .foregroundColor(Color.mimo.warning)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(Color.mimo.warning.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            Spacer(minLength: 4)

            // Three-dot menu
            Menu {
                Button(action: {
                    if !providerID.isEmpty {
                        appState.selectProvider(providerID)
                    }
                    appState.selectModel(modelID)
                }) {
                    Label(L.t("Select"), systemImage: isSelected ? "checkmark.circle.fill" : "circle")
                }

                Divider()

                Button(action: {
                    // Show model parameters in a popover/inline detail
                }) {
                    Label(L.t("Parameters"), systemImage: "slider.horizontal.3")
                }

                if let meta = meta {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        let info = """
                        Model: \(meta.id)
                        Name: \(meta.name ?? "—")
                        Provider: \(meta.providerID ?? providerID)
                        Context: \(meta.limit?.context.map { "\($0/1000)k" } ?? "—")
                        Output: \(meta.limit?.output.map { "\($0)" } ?? "—")
                        Reasoning: \(meta.capabilities?.reasoning == true ? "Yes" : "No")
                        Tools: \(meta.capabilities?.toolcall != false ? "Yes" : "No")
                        Plan: \(meta.capabilities?.plan == true ? "Yes" : "No")
                        Cost: \(meta.cost.map { "\(String(describing: $0.input))/\(String(describing: $0.output)) per 1K" } ?? "—")
                        """
                        NSPasteboard.general.setString(info, forType: .string)
                    }) {
                        Label(L.t("Copy info"), systemImage: "doc.on.doc")
                    }
                }

                // OmniRouter/agentRouter special config
                if isAgentRouterModel(modelID: modelID, providerID: providerID) {
                    Divider()
                    Button(action: {
                        toggleToolResultFix(for: modelID)
                    }) {
                        Label(
                            isToolResultFixEnabled(for: modelID) ? "Tool result fix: ON" : "Tool result fix: OFF",
                            systemImage: isToolResultFixEnabled(for: modelID) ? "checkmark.shield.fill" : "shield.slash"
                        )
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .interfaceFont(size: 12, weight: .bold)
                    .foregroundColor(Color.mimo.textMuted)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .onTapGesture { } // prevent menu from closing immediately
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? Color.mimo.subtleFill : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.mimo.brand.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
    }

    // MARK: - OmniRouter / agentRouter support

    /// Определяет, является ли модель agentRouter-совместимой
    private func isAgentRouterModel(modelID: String, providerID: String) -> Bool {
        let pid = providerID.lowercased()
        let mid = modelID.lowercased()
        return pid == "agentrouter" || pid == "omni" || pid == "omnirouter"
            || mid.contains("agentrouter") || mid.contains("omni")
    }

    /// Ключ UserDefaults для хранения включенности фикса формата tool result
    private func toolResultFixKey(for modelID: String) -> String {
        "com.micoder.toolResultFix.\(modelID)"
    }

    /// Проверить включен ли фикс для модели
    private func isToolResultFixEnabled(for modelID: String) -> Bool {
        UserDefaults.standard.bool(forKey: toolResultFixKey(for: modelID))
    }

    /// Переключить фикс для модели
    private func toggleToolResultFix(for modelID: String) {
        let key = toolResultFixKey(for: modelID)
        let current = UserDefaults.standard.bool(forKey: key)
        UserDefaults.standard.set(!current, forKey: key)
    }
}

struct CustomProviderCard: View {
    let provider: CustomProvider
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        SettingsCard {
            HStack {
                Image(systemName: provider.type.icon)
                    .interfaceFont(size: 20)
                Text(provider.name)
                    .interfaceFont(size: 14, weight: .semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(provider.type.rawValue)
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.mimo.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                if provider.isEnabled {
                    Circle().fill(Color.mimo.success).frame(width: 8, height: 8)
                } else {
                    Circle().fill(Color.mimo.textMuted).frame(width: 8, height: 8)
                }
                
                Button(action: {
                    appState.removeCustomProvider(provider)
                }) {
                    Image(systemName: "trash")
                        .interfaceFont(size: 12)
                        .foregroundColor(Color.mimo.error)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("URL:")
                        .interfaceFont(size: 11)
                        .foregroundColor(Color.mimo.textMuted)
                    Text(provider.baseURL)
                        .interfaceFont(size: 11, design: .monospaced)
                        .foregroundColor(Color.mimo.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                if !provider.models.isEmpty {
                    HStack {
                        Text("Models:")
                            .interfaceFont(size: 11)
                            .foregroundColor(Color.mimo.textMuted)
                        Text("\(provider.models.count) available")
                            .interfaceFont(size: 11)
                            .foregroundColor(Color.mimo.textSecondary)
                    }
                }
            }
        }
    }
}

struct AddProviderSheet: View {
    @Binding var isPresented: Bool
    @Binding var name: String
    @Binding var type: ProviderType
    @Binding var url: String
    @Binding var apiKey: String
    @EnvironmentObject var appState: AppState
    @State private var isTesting = false
    @State private var testResult: String?
    @State private var supportsTools = true
    @State private var acpEnabled = false
    @State private var requiresAPIKey = true
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add Provider")
                    .interfaceFont(size: 16, weight: .semibold)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .interfaceFont(size: 16)
                        .foregroundColor(Color.mimo.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Provider Type")
                            .interfaceFont(size: 13, weight: .medium)
                            .foregroundColor(Color.mimo.textPrimary)
                        
                        Picker("Type", selection: $type) {
                            ForEach(ProviderType.allCases) { t in
                                Label(t.rawValue, systemImage: t.icon).tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: type) { newType in
                            url = newType.defaultURL
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .interfaceFont(size: 13, weight: .medium)
                            .foregroundColor(Color.mimo.textPrimary)
                        TextField("e.g., My OpenRouter", text: $name)
                            .zcodeTextFieldStyle()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Base URL")
                            .interfaceFont(size: 13, weight: .medium)
                            .foregroundColor(Color.mimo.textPrimary)
                        TextField("API endpoint URL", text: $url)
                            .zcodeTextFieldStyle()
                            .interfaceFont(size: 12, design: .monospaced)
                    }
                    
                    if type != .ollama && type != .acp && requiresAPIKey {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Key")
                                .interfaceFont(size: 13, weight: .medium)
                                .foregroundColor(Color.mimo.textPrimary)
                            SecureField(type == .openModel ? "om-..." : "sk-...", text: $apiKey)
                                .zcodeTextFieldStyle()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Requires API Key", isOn: $requiresAPIKey)
                            .interfaceFont(size: 13, weight: .medium)
                        Text("Disable for local models or providers that don't need authentication")
                            .interfaceFont(size: 11)
                            .foregroundColor(Color.mimo.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Enable Tool Calling", isOn: $supportsTools)
                            .interfaceFont(size: 13, weight: .medium)
                        Text("Enable function/tool calling support for this provider")
                            .interfaceFont(size: 11)
                            .foregroundColor(Color.mimo.textSecondary)
                    }
                    
                    if type == .acp {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Enable ACP Protocol", isOn: $acpEnabled)
                                .interfaceFont(size: 13, weight: .medium)
                            Text("Enable Agent Coder Protocol for autonomous coding tasks")
                                .interfaceFont(size: 11)
                                .foregroundColor(Color.mimo.textSecondary)
                        }
                    }
                    
                    if let result = testResult {
                        HStack(spacing: 6) {
                            Image(systemName: result.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.contains("Success") ? Color.mimo.success : Color.mimo.error)
                            Text(result)
                                .interfaceFont(size: 12)
                                .foregroundColor(result.contains("Success") ? Color.mimo.success : Color.mimo.error)
                        }
                    }
                }
                .padding(16)
            }
            
            Divider()
            
            HStack {
                Button(action: {
                    isTesting = true
                    Task {
                        let success = await appState.testProvider(url: url, apiKey: apiKey, type: type)
                        await MainActor.run {
                            isTesting = false
                            testResult = success ? "Success! Provider is reachable." : "Failed to connect. Check URL and credentials."
                        }
                    }
                }) {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Test Connection")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(name.isEmpty || url.isEmpty)
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(Color.mimo.textSecondary)
                
                Button(action: {
                    let provider = CustomProvider(
                        id: UUID().uuidString,
                        name: name.isEmpty ? type.rawValue : name,
                        type: type,
                        baseURL: url,
                        apiKey: apiKey,
                        isEnabled: true,
                        models: [],
                        supportsTools: supportsTools,
                        acpEnabled: acpEnabled,
                        requiresAPIKey: requiresAPIKey
                    )
                    appState.addCustomProvider(provider)
                    isPresented = false
                    name = ""
                    url = ""
                    apiKey = ""
                    requiresAPIKey = true
                }) {
                    Text("Add Provider")
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(name.isEmpty || url.isEmpty ? Color.mimo.textMuted : Color.mimo.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(name.isEmpty || url.isEmpty)
            }
            .padding(16)
        }
        .frame(width: 480, height: 600)
        .background(Color.mimo.background)
    }
}

struct SkillsSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchQuery = ""
    @State private var skills: [SkillEntry] = []

    private var filtered: [SkillEntry] {
        AgentResourcesLoader.filterSkills(skills, query: searchQuery)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Skills")
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)

            Text("Browse the library and install skills in one click, or manage local skills under ~/.micoder/skills.")
                .interfaceFont(size: 14)
                .foregroundColor(Color.mimo.textSecondary)

            if !appState.supportsToolcallForSelection {
                Text("Tools unavailable for the current model or provider.")
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.warning)
            }

            TextField("Search skills...", text: $searchQuery)
                .zcodeTextFieldStyle()

            AgentResourceLibraryView(
                mode: .skills,
                searchQuery: searchQuery,
                onInstalled: reloadSkills
            )

            Text("Installed \(filtered.count)")
                .interfaceFont(size: 12, weight: .semibold)
                .foregroundColor(Color.mimo.textMuted)

            if filtered.isEmpty {
                emptyState("No skills installed yet", subtitle: "Pick a skill from the library above and tap Install.")
            } else {
                ForEach(filtered) { skill in
                    InstalledSkillRow(skill: skill, record: record(for: skill.id), onChanged: reloadSkills)
                }
            }
        }
        .onAppear(perform: reloadSkills)
    }

    @State private var records: [InstalledSkillRecord] = []

    private func record(for id: String) -> InstalledSkillRecord? {
        records.first { $0.id == id }
    }

    private func reloadSkills() {
        skills = AgentResourcesLoader.loadSkills()
        records = SkillRegistryManager.load(homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
    }
}

/// Installed skill row with full admin: version/source badges, enable/disable
/// toggle, remove (plan Раздел 3 Блок 4 п.37).
struct InstalledSkillRow: View {
    let skill: SkillEntry
    let record: InstalledSkillRecord?
    let onChanged: () -> Void

    @State private var showRemoveConfirmation = false

    private var home: URL { FileManager.default.homeDirectoryForCurrentUser }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(skill.name)
                        .interfaceFont(size: 13, weight: .medium)
                        .foregroundColor(Color.mimo.textPrimary)
                    badge(skill.source)
                    if let v = record?.version { badge("v\(v)") }
                    if let r = record, !r.isEnabled { badge("Disabled") }
                }
                Text(skill.path)
                    .interfaceFont(size: 11, design: .monospaced)
                    .foregroundColor(Color.mimo.textMuted)
                    .lineLimit(1)
            }
            Spacer()
            if let r = record {
                Button(r.isEnabled ? "Disable" : "Enable") {
                    _ = try? SkillRegistryManager.setEnabled(id: skill.id, enabled: !r.isEnabled, homeDirectory: home)
                    onChanged()
                }
                .interfaceFont(size: 11)
                .buttonStyle(.plain)
                .foregroundColor(r.isEnabled ? Color.mimo.textSecondary : Color.mimo.success)
            }
            Button(action: { showRemoveConfirmation = true }) {
                Image(systemName: "trash").interfaceFont(size: 12).foregroundColor(Color.mimo.error)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.mimo.surface)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .alert("Remove skill?", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) { remove() }
        } message: {
            Text("This deletes \"\(skill.name)\" from \(home.appendingPathComponent(".micoder/skills").path)/ and its registry entry. This cannot be undone.")
        }
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .interfaceFont(size: 9, weight: .medium)
            .foregroundColor(Color.mimo.textMuted)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(Color.mimo.backgroundAlt.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private func remove() {
        // Remove the skill directory + registry record.
        for base in [".micoder/skills"] {
            let dir = home.appendingPathComponent("\(base)/\(skill.id)")
            try? FileManager.default.removeItem(at: dir)
        }
        _ = try? SkillRegistryManager.remove(id: skill.id, homeDirectory: home)
        onChanged()
    }
}

struct MCPServersSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchQuery = ""
    @State private var servers: [MCPServerEntry] = []

    private var filtered: [MCPServerEntry] {
        AgentResourcesLoader.filterEntries(servers, query: searchQuery) { $0.name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("MCP Servers")
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)

            Text("Browse the library and install MCP servers in one click. Configurations are saved to ~/.micoder/mcp.json.")
                .interfaceFont(size: 14)
                .foregroundColor(Color.mimo.textSecondary)

            if !appState.supportsToolcallForSelection {
                Text("Tools unavailable for the current model or provider.")
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.warning)
            }

            TextField("Search MCP servers...", text: $searchQuery)
                .zcodeTextFieldStyle()

            AgentResourceLibraryView(
                mode: .mcpServers,
                searchQuery: searchQuery,
                onInstalled: reloadServers
            )

            Text("Configured \(filtered.count)")
                .interfaceFont(size: 12, weight: .semibold)
                .foregroundColor(Color.mimo.textMuted)

            if filtered.isEmpty {
                emptyState("No MCP servers configured", subtitle: "Pick a server from the library above and tap Install.")
            } else {
                ForEach(filtered) { server in
                    InstalledMCPRow(server: server, onChanged: reloadServers)
                }
            }
        }
        .onAppear(perform: reloadServers)
    }

    private func reloadServers() {
        servers = AgentResourcesLoader.loadMCPServers()
    }
}

/// Installed MCP row with full admin: health dot, enable/disable (writes the
/// `disabled` flag to mcp.json), remove (plan Раздел 4 Блок 4 п.37). The dot
/// reflects the *real* health probe (E11): green = alive, red = failing,
/// gray = disabled / not yet checked — never the enabled preference alone.
struct InstalledMCPRow: View {
    let server: MCPServerEntry
    let onChanged: () -> Void

    @State private var showRemoveConfirmation = false
    @State private var healthStatus: MCPHealthStatus = .unknown

    private var configURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".micoder/mcp.json")
    }
    private var home: URL { FileManager.default.homeDirectoryForCurrentUser }

    private var healthColor: Color {
        switch healthStatus {
        case .healthy: return Color.mimo.success
        case .unhealthy: return Color.mimo.error
        case .unknown: return Color.mimo.textMuted
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(healthColor)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 4) {
                Text(server.name)
                    .interfaceFont(size: 13, weight: .medium)
                    .foregroundColor(Color.mimo.textPrimary)
                if let command = server.command {
                    Text(command)
                        .interfaceFont(size: 11, design: .monospaced)
                        .foregroundColor(Color.mimo.textMuted)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button(server.isEnabled ? "Disable" : "Enable") {
                setDisabled(!server.isEnabled)
            }
            .interfaceFont(size: 11)
            .buttonStyle(.plain)
            .foregroundColor(server.isEnabled ? Color.mimo.textSecondary : Color.mimo.success)

            Button(action: { showRemoveConfirmation = true }) {
                Image(systemName: "trash").interfaceFont(size: 12).foregroundColor(Color.mimo.error)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.mimo.surface)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .alert("Remove MCP server?", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) { remove() }
        } message: {
            Text("This removes \"\(server.name)\" from \(configURL.path) and the registry. This cannot be undone.")
        }
        .task(id: server.id) {
            await refreshHealth()
        }
    }

    /// Runs a real health probe (HTTP GET or stdio PATH resolution) and maps
    /// the stored registry result into the dot, re-probing only when the last
    /// result is stale or absent.
    private func refreshHealth() async {
        let registryStatus = MCPRegistryManager.load(homeDirectory: home)
            .first(where: { $0.id == server.id })
        let mapped = MCPHealthCheckLogic.status(
            isEnabled: server.isEnabled,
            lastCheck: registryStatus?.lastHealthCheck,
            lastStatus: registryStatus?.lastHealthStatus
        )
        if mapped == .unknown {
            let checker = MCPHealthChecker()
            if let fresh = try? await checker.check(server, homeDirectory: home) {
                healthStatus = fresh ? .healthy : .unhealthy
                return
            }
            healthStatus = .unknown
        } else {
            healthStatus = mapped
        }
    }

    private func mutateConfig(_ transform: (inout [String: Any]) -> Void) {
        guard let data = try? Data(contentsOf: configURL),
              var root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              var servers = root["mcpServers"] as? [String: Any],
              var entry = servers[server.id] as? [String: Any] else { return }
        transform(&entry)
        servers[server.id] = entry
        root["mcpServers"] = servers
        if let out = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys]) {
            try? out.write(to: configURL, options: .atomic)
        }
    }

    private func setDisabled(_ disabled: Bool) {
        mutateConfig { $0["disabled"] = disabled }
        _ = try? MCPRegistryManager.setEnabled(id: server.id, enabled: !disabled, homeDirectory: home)
        onChanged()
    }

    private func remove() {
        guard let data = try? Data(contentsOf: configURL),
              var root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              var servers = root["mcpServers"] as? [String: Any] else { return }
        servers.removeValue(forKey: server.id)
        root["mcpServers"] = servers
        if let out = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys]) {
            try? out.write(to: configURL, options: .atomic)
        }
        _ = try? MCPRegistryManager.remove(id: server.id, homeDirectory: home)
        onChanged()
    }
}

struct PluginsSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchQuery = ""
    @State private var plugins: [PluginEntry] = []

    private var filtered: [PluginEntry] {
        AgentResourcesLoader.filterEntries(plugins, query: searchQuery) { $0.name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Plugins")
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)

            Text("Enable or disable installed plugins. Plugins bundle skills, commands, and MCP servers.")
                .interfaceFont(size: 14)
                .foregroundColor(Color.mimo.textSecondary)

            if !appState.supportsToolcallForSelection {
                Text("Tools unavailable for the current model or provider.")
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.warning)
            }

            TextField("Search plugins...", text: $searchQuery)
                .zcodeTextFieldStyle()

            if filtered.isEmpty {
                emptyState("No plugins installed", subtitle: "Plugins live under ~/.micoder/plugins")
            } else {
                ForEach(filtered) { plugin in
                    HStack {
                        Text(plugin.name)
                            .interfaceFont(size: 13, weight: .medium)
                            .foregroundColor(Color.mimo.textPrimary)
                        Spacer()
                        Text(plugin.isEnabled ? "Enabled" : "Disabled")
                            .interfaceFont(size: 11)
                            .foregroundColor(plugin.isEnabled ? Color.mimo.success : Color.mimo.textMuted)
                    }
                    .padding(12)
                    .background(Color.mimo.surface)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .onAppear {
            plugins = AgentResourcesLoader.loadPlugins()
        }
    }
}

struct CommandsSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchQuery = ""
    @State private var commands: [CommandEntry] = []

    private var filtered: [CommandEntry] {
        AgentResourcesLoader.filterEntries(commands, query: searchQuery) { $0.name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Commands")
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)

            Text("Manage MiCoder Agent .md command files. Commands can be invoked with /command-name in chat.")
                .interfaceFont(size: 14)
                .foregroundColor(Color.mimo.textSecondary)

            if !appState.supportsToolcallForSelection {
                Text("Tools unavailable for the current model or provider.")
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.warning)
            }

            TextField("Search commands...", text: $searchQuery)
                .zcodeTextFieldStyle()

            if filtered.isEmpty {
                emptyState("No user commands", subtitle: "Add .md files to ~/.micoder/commands")
            } else {
                ForEach(filtered) { command in
                    HStack {
                        Text("/\(command.name)")
                            .interfaceFont(size: 13, weight: .medium)
                            .foregroundColor(Color.mimo.textPrimary)
                        Spacer()
                        Text(command.path)
                            .interfaceFont(size: 10, design: .monospaced)
                            .foregroundColor(Color.mimo.textMuted)
                            .lineLimit(1)
                    }
                    .padding(12)
                    .background(Color.mimo.surface)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .onAppear {
            commands = AgentResourcesLoader.loadCommands()
        }
    }
}

@ViewBuilder
private func emptyState(_ title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        Text(title)
            .interfaceFont(size: 14)
            .foregroundColor(Color.mimo.textMuted)
        Text(subtitle)
            .interfaceFont(size: 12)
            .foregroundColor(Color.mimo.textSecondary)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.mimo.surface)
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
    .clipShape(RoundedRectangle(cornerRadius: 8))
}

struct IndexingSettingsView: View {
    @EnvironmentObject var appState: AppState
    
    private var indexNewFoldersBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.indexNewFolders },
            set: { newValue in appState.updateSettings { $0.indexNewFolders = newValue } }
        )
    }
    
    private var indexRepositoriesBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.indexRepositories },
            set: { newValue in appState.updateSettings { $0.indexRepositories = newValue } }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Indexing")
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)
            
            Text("Codebase")
                .interfaceFont(size: 14, weight: .semibold)
                .foregroundColor(Color.mimo.textMuted)
            
            SettingsCard {
                SettingsToggleRow(title: "Index new folders", description: "Automatically index any new folders with fewer than 50,000 files.", isOn: indexNewFoldersBinding)
                
                SettingsToggleRow(title: "Index repositories for instant grep (Beta)", description: "Automatically index repositories to speed up Grep searches. All data is stored locally.", isOn: indexRepositoriesBinding)
            }
        }
    }
}

struct StorageSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var stats = StorageStats(databaseSize: 0, snapshotSize: 0, messageCount: 0, sessionCountsByProject: [])
    // Round 12: two distinct confirmations — one for "delete older than N days"
    // and one for "delete all archived chats". They used to share the same
    // alert, which crashed / ran the wrong action (P2).
    @State private var showDeleteOlderConfirmation = false
    @State private var showDeleteArchivedConfirmation = false
    @State private var showResetConfirmation = false
    @State private var pendingResetScope: StorageResetScope = .appCacheOnly
    @State private var archiveDays: Double = 7
    @State private var deleteDays: Double = 30
    @State private var selectedProjectFilter = "All"
    @State private var projectEntries: [ProjectRegistryEntry] = []
    // Delete-project guard (plan Раздел 8 п.24/п.54): destructive action requires
    // typing the project name — GitHub "type repo name to delete" pattern.
    @State private var pendingDeleteEntry: ProjectRegistryEntry?
    @State private var deleteConfirmName = ""
    // Quota status (plan Раздел 8 п.50): informative warning when the sum of all
    // per-project DBs crosses the threshold — never blocks, always suggests.
    @State private var quota = ProjectStorageAdmin.StorageQuotaStatus(
        totalBytes: 0, thresholdBytes: 0, archivableBytes: 0, archivedBytes: 0
    )
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Storage & Database")
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)

            // Per-project administration (plan Раздел 8 Блок 3 п.21-24)
            projectsAdminSection

            // Statistics card
            SettingsCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Usage")
                        .interfaceFont(size: 13, weight: .semibold)
                        .foregroundColor(Color.mimo.textPrimary)
                    
                    HStack(spacing: 16) {
                        StorageStatView(title: "Database", value: stats.databaseSizeFormatted, icon: "externaldrive")
                        StorageStatView(title: "Snapshots", value: stats.snapshotSizeFormatted, icon: "clock.arrow.circlepath")
                        StorageStatView(title: "Total", value: stats.totalSizeFormatted, icon: "externaldrive.fill")
                    }
                    
                    Divider()
                    
                    HStack(spacing: 16) {
                        StorageStatView(title: "Messages", value: "\(stats.messageCount)", icon: "message")
                        StorageStatView(title: "Active chats", value: "\(stats.totalActiveSessions)", icon: "bubble.left")
                        StorageStatView(title: L.t("Archived"), value: "\(stats.totalArchivedSessions)", icon: "archivebox")
                    }
                    
                    if !stats.sessionCountsByProject.isEmpty {
                        Divider()
                        Text("Per project")
                            .interfaceFont(size: 11, weight: .medium)
                            .foregroundColor(Color.mimo.textMuted)
                        
                        ForEach(stats.sessionCountsByProject, id: \.projectId) { item in
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill")
                                    .interfaceFont(size: 10)
                                    .foregroundColor(Color.mimo.textMuted)
                                Text(item.projectId)
                                    .interfaceFont(size: 11, design: .monospaced)
                                    .lineLimit(1)
                                    .foregroundColor(Color.mimo.textSecondary)
                                Spacer()
                                Text("\(item.active) active")
                                    .interfaceFont(size: 10)
                                    .foregroundColor(Color.mimo.success)
                                Text("\(item.archived) archived")
                                    .interfaceFont(size: 10)
                                    .foregroundColor(Color.mimo.textMuted)
                            }
                        }
                    }
                }
                .padding(4)
            }
            
            // Auto-archive card
            SettingsCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Auto-archive")
                        .interfaceFont(size: 13, weight: .semibold)
                        .foregroundColor(Color.mimo.textPrimary)
                    
                    Text("Inactive chats are automatically archived after the selected period to save space. They are loaded on demand and unarchived when you send a new message.")
                        .interfaceFont(size: 11)
                        .foregroundColor(Color.mimo.textSecondary)
                    
                    HStack(spacing: 8) {
                        Text("Archive after:")
                            .interfaceFont(size: 12)
                            .foregroundColor(Color.mimo.textSecondary)
                        Picker("", selection: $archiveDays) {
                            Text("3 days").tag(3.0)
                            Text("7 days").tag(7.0)
                            Text("14 days").tag(14.0)
                            Text("30 days").tag(30.0)
                            Text("90 days").tag(90.0)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                        
                        Button("Archive now") {
                            appState.archiveOldSessions(days: Int(archiveDays))
                            refreshStats()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(4)
            }
            
            // Cleanup card
            SettingsCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cleanup")
                        .interfaceFont(size: 13, weight: .semibold)
                        .foregroundColor(Color.mimo.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text("Delete chats older than:")
                            .interfaceFont(size: 12)
                            .foregroundColor(Color.mimo.textSecondary)
                        Picker("", selection: $deleteDays) {
                            Text("7 days").tag(7.0)
                            Text("30 days").tag(30.0)
                            Text("90 days").tag(90.0)
                            Text("180 days").tag(180.0)
                            Text("1 year").tag(365.0)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                        
                        Button("Delete", role: .destructive) {
                            showDeleteOlderConfirmation = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    Divider()
                    
                    Button("Delete all archived chats") {
                        showDeleteArchivedConfirmation = true
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color.mimo.error)
                    .interfaceFont(size: 12)
                    
                    Divider()
                    
                    Button("Compress database (VACUUM)") {
                        appState.vacuumDatabase()
                        refreshStats()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color.mimo.brand)
                    .interfaceFont(size: 12)
                    
                    Divider()
                    
                    // Explicit reset scenario (plan Раздел 8 Блок 1 п.10):
                    // clear the app database. No CLI-history options — the
                    // app is HTTP-only (clean slate).
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(AppLocalization.string(.resetStorageTitle, language: appState.appLanguage))
                        .interfaceFont(size: 12, weight: .semibold)
                        .foregroundColor(Color.mimo.textPrimary)
                    Button(AppLocalization.string(.resetAppCache, language: appState.appLanguage)) {
                        pendingResetScope = .appCacheOnly; showResetConfirmation = true
                    }
                    .buttonStyle(.plain).foregroundColor(Color.mimo.error).interfaceFont(size: 12)
                }
            }
                }
                .padding(4)
            }
            .alert("Delete old chats?", isPresented: $showDeleteOlderConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    _ = appState.deleteSessionsOlderThan(days: Int(deleteDays))
                    refreshStats()
                }
            } message: {
                Text("This will permanently delete all chats older than \(Int(deleteDays)) days, including their messages. This action cannot be undone.")
            }
            .alert("Delete archived chats?", isPresented: $showDeleteArchivedConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    _ = appState.deleteArchivedSessions()
                    refreshStats()
                }
            } message: {
                Text("This will permanently delete ALL archived chats and their messages. This action cannot be undone.")
            }
            .alert(resetAlertTitle, isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    appState.resetStorage(scope: pendingResetScope)
                    refreshStats()
                }
            } message: {
                Text(resetAlertMessage)
            }
            .alert(
                "Delete project permanently?",
                isPresented: Binding(
                    get: { pendingDeleteEntry != nil },
                    set: { if !$0 { pendingDeleteEntry = nil } }
                )
            ) {
                TextField("Type \"\(pendingDeleteEntry?.name ?? "")\" to confirm", text: $deleteConfirmName)
                Button("Cancel", role: .cancel) { pendingDeleteEntry = nil }
                Button("Delete", role: .destructive) {
                    if let entry = pendingDeleteEntry { deleteProject(entry) }
                    pendingDeleteEntry = nil
                }
                .disabled(!ProjectDeleteConfirmation.isConfirmed(
                    projectName: pendingDeleteEntry?.name ?? "",
                    typed: deleteConfirmName
                ))
            } message: {
                Text(ProjectDeleteConfirmation.deletionDescription(
                    projectPath: pendingDeleteEntry?.path ?? ""
                ))
            }
        }
        .onAppear(perform: refreshStats)
    }

    private var resetAlertTitle: String {
        "Clear app cache?"
    }

    private var resetAlertMessage: String {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let plan = StorageResetLogic.plan(for: pendingResetScope, homeDirectory: home)
        return StorageResetLogic.summary(for: plan)
    }
    
    private var home: URL { FileManager.default.homeDirectoryForCurrentUser }

    private var projectsAdminSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Projects")
                    .interfaceFont(size: 16, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Spacer()
                Button("Archive inactive > \(Int(archiveDays)) days") {
                    mutateProjects { ProjectStorageAdmin.archiveAllInactive(days: Int(archiveDays), in: $0) }
                }
                .interfaceFont(size: 11).buttonStyle(.plain).foregroundColor(Color.mimo.brand)
                .help("Bulk-archive projects not opened in the selected number of days (plan Раздел 8 п.25)")
            }
            // Quota warning (plan Раздел 8 п.50): inform, never block.
            if quota.isOverQuota {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .interfaceFont(size: 12)
                        .foregroundColor(Color.mimo.warning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Storage quota exceeded")
                            .interfaceFont(size: 12, weight: .semibold)
                            .foregroundColor(Color.mimo.textPrimary)
                        Text("Total project databases use \(quota.totalBytes.formatted(.byteCount(style: .file))), above the \(quota.thresholdBytes.formatted(.byteCount(style: .file))) threshold. Archiving inactive projects would free \(quota.archivableBytes.formatted(.byteCount(style: .file))).")
                            .interfaceFont(size: 11)
                            .foregroundColor(Color.mimo.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Button("Archive inactive") {
                        mutateProjects { ProjectStorageAdmin.archiveAllInactive(days: Int(archiveDays), in: $0) }
                    }
                    .interfaceFont(size: 11)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.mimo.warning)
                }
                .padding(10)
                .background(Color.mimo.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }
            let active = ProjectRegistryLogic.active(projectEntries)
            let archived = ProjectRegistryLogic.archived(projectEntries)
            let orphans = ProjectRegistryLogic.orphaned(projectEntries)
            if active.isEmpty && archived.isEmpty && orphans.isEmpty {
                Text("No projects registered yet.")
                    .interfaceFont(size: 12).foregroundColor(Color.mimo.textMuted)
            }
            ForEach(active) { entry in
                projectRow(entry, archived: false)
            }
            if !archived.isEmpty {
                Text("Archived")
                    .interfaceFont(size: 11, weight: .semibold).foregroundColor(Color.mimo.textMuted)
                ForEach(archived) { entry in
                    projectRow(entry, archived: true)
                }
            }
            if !orphans.isEmpty {
                // Plan Раздел 8 п.31: registry entries whose path no longer exists
                // are shown explicitly, with "Find new path" (relink) or "Delete record".
                Text("Orphaned (path missing)")
                    .interfaceFont(size: 11, weight: .semibold).foregroundColor(Color.mimo.warning)
                ForEach(orphans) { entry in
                    orphanRow(entry)
                }
            }
        }
    }

    private func orphanRow(_ entry: ProjectRegistryEntry) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "questionmark.folder")
                .interfaceFont(size: 11).foregroundColor(Color.mimo.warning)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.name).interfaceFont(size: 12, weight: .medium).foregroundColor(Color.mimo.textPrimary)
                Text(entry.path).interfaceFont(size: 10).foregroundColor(Color.mimo.warning).lineLimit(1)
            }
            Spacer()
            Button("Find new path…") { relinkProject(entry) }
                .interfaceFont(size: 11).buttonStyle(.plain).foregroundColor(Color.mimo.brand)
            Button(action: {
                deleteConfirmName = ""
                pendingDeleteEntry = entry
            }) {
                Image(systemName: "trash").interfaceFont(size: 11).foregroundColor(Color.mimo.error)
            }
            .buttonStyle(.plain)
            .help("Delete record (requires typing its name)")
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.mimo.surface)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mimo.warning.opacity(0.5), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func relinkProject(_ entry: ProjectRegistryEntry) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.message = "Find the project folder at its new location"
        panel.prompt = "Relink"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        mutateProjects { ProjectRegistryLogic.relink(id: entry.id, toNewPath: url.path, in: $0) }
    }

    private func projectRow(_ entry: ProjectRegistryEntry, archived: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: archived ? "archivebox" : "folder")
                .interfaceFont(size: 11).foregroundColor(Color.mimo.textMuted)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.name).interfaceFont(size: 12, weight: .medium).foregroundColor(Color.mimo.textPrimary)
                Text(entry.path).interfaceFont(size: 10).foregroundColor(Color.mimo.textMuted).lineLimit(1)
            }
            Spacer()
            if archived {
                Button("Restore") { mutateProjects { ProjectRegistryLogic.restore(id: entry.id, in: $0) } }
                    .interfaceFont(size: 11).buttonStyle(.plain).foregroundColor(Color.mimo.brand)
            } else {
                Button("Archive") { mutateProjects { ProjectRegistryLogic.archive(id: entry.id, at: Date(), in: $0) } }
                    .interfaceFont(size: 11).buttonStyle(.plain).foregroundColor(Color.mimo.textSecondary)
            }
            Button(action: {
                deleteConfirmName = ""
                pendingDeleteEntry = entry
            }) {
                Image(systemName: "trash").interfaceFont(size: 11).foregroundColor(Color.mimo.error)
            }
            .buttonStyle(.plain)
            .help("Delete project (requires typing its name)")

            Button(action: {
                if appState.vacuumProject(path: entry.path) { refreshStats() }
            }) {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .interfaceFont(size: 11).foregroundColor(Color.mimo.brand)
            }
            .buttonStyle(.plain)
            .help("Compress this project's database (VACUUM)")

            Button(action: { exportProjectBackup(entry) }) {
                Image(systemName: "square.and.arrow.up")
                    .interfaceFont(size: 11).foregroundColor(Color.mimo.brand)
            }
            .buttonStyle(.plain)
            .help("Export this project's database + snapshots as a .zip backup")

            Button(action: { importProjectBackup(entry) }) {
                Image(systemName: "square.and.arrow.down")
                    .interfaceFont(size: 11).foregroundColor(Color.mimo.brand)
            }
            .buttonStyle(.plain)
            .help("Restore this project's database + snapshots from a .zip backup")
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.mimo.surface)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func exportProjectBackup(_ entry: ProjectRegistryEntry) {
        let plan = ProjectBackupLogic.plan(projectPath: entry.path)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = plan.archiveName
        panel.canCreateDirectories = true
        panel.prompt = "Export backup"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if ProjectBackupLogic.export(projectPath: entry.path, to: url) {
            refreshStats()
        }
    }

    private func importProjectBackup(_ entry: ProjectRegistryEntry) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.zip]
        panel.prompt = "Restore backup"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        if ProjectBackupLogic.importBackup(from: url, projectPath: entry.path) {
            refreshStats()
        }
    }

    private func loadProjectEntries() {
        projectEntries = ProjectRegistryLogic.load(homeDirectory: home)
    }

    private func mutateProjects(_ transform: ([ProjectRegistryEntry]) -> [ProjectRegistryEntry]) {
        let before = ProjectRegistryLogic.load(homeDirectory: home)
        let updated = transform(before)
        // Audit every registry mutation (plan Раздел 8 п.46) so destructive
        // operations are reconstructable later.
        if updated != before {
            let added = updated.filter { e in !before.contains { $0.id == e.id } }
            let removed = before.filter { e in !updated.contains { $0.id == e.id } }
            if !added.isEmpty {
                try? StorageAuditLog.append(action: "registry.add", detail: added.map(\.path).joined(separator: ", "), homeDirectory: home)
            }
            if !removed.isEmpty {
                try? StorageAuditLog.append(action: "registry.remove", detail: removed.map(\.path).joined(separator: ", "), homeDirectory: home)
            }
        }
        try? ProjectRegistryLogic.save(updated, homeDirectory: home)
        projectEntries = updated
    }

    private func deleteProject(_ entry: ProjectRegistryEntry) {
        // Auto-backup the project DB before deletion (plan Раздел 8 п.49).
        // The backup must SURVIVE the deletion, so it's moved to a global
        // deleted-backups area (inside .micoder it would be removed with it).
        _ = try? ProjectAutoBackupLogic.createBackup(projectPath: entry.path)
        _ = try? ProjectAutoBackupLogic.preserveForDeletion(projectPath: entry.path)
        try? StorageAuditLog.append(action: "project.delete",
                                    detail: "path=\(entry.path)",
                                    homeDirectory: home)
        // Remove only the project's .micoder data, never the user's files.
        try? FileManager.default.removeItem(at: ProjectDatabaseLocator.projectMimoDir(projectPath: entry.path))
        mutateProjects { ProjectRegistryLogic.remove(id: entry.id, in: $0) }
        // If the deleted project was the active selection, drop it so the UI
        // never points at a registry entry that no longer exists.
        if appState.selectedWorkspace?.path == entry.path {
            appState.clearNavigationHistory()
            appState.selectedWorkspace = nil
        }
    }

    private func refreshStats() {
        stats = appState.loadStorageStats()
        loadProjectEntries()
        // Recompute the quota against the 2GB informational threshold (п.50).
        quota = ProjectStorageAdmin.quotaStatus(
            projects: projectEntries,
            thresholdBytes: 2_000_000_000,
            inactiveDays: Int(archiveDays)
        )
    }
}

struct StorageStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .interfaceFont(size: 12)
                .foregroundColor(Color.mimo.textMuted)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .interfaceFont(size: 13, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Text(title)
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UsageSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedRange: UsageRange = .last30
    @State private var stats: StorageStats?
    @State private var points: [UsageDataPoint] = []
    
    enum UsageRange: String, CaseIterable {
        case last7 = "Last 7 days"
        case last30 = "Last 30 days"
        var days: Int { self == .last7 ? 7 : 30 }
    }

    private var filteredPoints: [UsageDataPoint] {
        UsageStatisticsAggregator.filter(points, range: .lastDays(selectedRange.days))
    }
    private var byModel: [UsageAggregate] {
        UsageStatisticsAggregator.aggregateByModel(filteredPoints)
    }
    private var totals: (tokens: Int, cost: Double?) {
        UsageStatisticsAggregator.totals(filteredPoints)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Usage")
                    .interfaceFont(size: 24, weight: .bold)
                    .foregroundColor(Color.mimo.textPrimary)
                Text("App usage")
                    .interfaceFont(size: 14)
                    .foregroundColor(Color.mimo.textMuted)
            }
            
            HStack(spacing: 8) {
                Text("Time range")
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textMuted)
                
                ForEach(UsageRange.allCases, id: \.self) { range in
                    SettingsSegmentButton(
                        title: range.rawValue,
                        isSelected: selectedRange == range
                    ) {
                        selectedRange = range
                    }
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                UsageStatCard(title: "Total tokens", value: formatTokens(totals.tokens), icon: "flame")
                UsageStatCard(title: "Total cost", value: UsageStatisticsAggregator.costLabel(totals.cost), icon: "dollarsign.circle")
                UsageStatCard(title: "Messages", value: formattedMessages, icon: "message")
                UsageStatCard(title: "Active days", value: "\(UsageStatisticsAggregator.activeDays(filteredPoints))", icon: "calendar")
                UsageStatCard(title: "Database size", value: stats?.databaseSizeFormatted ?? "—", icon: "internaldrive")
                UsageStatCard(title: "Favorite model",
                              value: UsageStatisticsAggregator.favoriteModel(filteredPoints) ?? "None",
                              subtitle: "by usage", icon: "brain")
            }

            // Per-model breakdown (plan Раздел 10 Блок 2 п.16)
            if !byModel.isEmpty {
                Text("By model")
                    .interfaceFont(size: 16, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                VStack(spacing: 6) {
                    ForEach(byModel, id: \.key) { agg in
                        HStack {
                            Text(agg.key)
                                .interfaceFont(size: 12, weight: .medium)
                                .foregroundColor(Color.mimo.textPrimary)
                            Spacer()
                            Text("\(agg.messageCount) msg")
                                .interfaceFont(size: 11).foregroundColor(Color.mimo.textMuted)
                            Text("\(formatTokens(agg.promptTokens))↑ \(formatTokens(agg.completionTokens))↓")
                                .interfaceFont(size: 11, design: .monospaced).foregroundColor(Color.mimo.textSecondary)
                            Text(UsageStatisticsAggregator.costLabel(agg.costUSD))
                                .interfaceFont(size: 11).foregroundColor(Color.mimo.textSecondary)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.mimo.surface)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mimo.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            } else {
                Text("No usage data for the selected period.")
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textMuted)
            }
        }
        .onAppear {
            stats = appState.loadStorageStats()
            points = appState.loadUsageDataPoints()
        }
    }

    private func formatTokens(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fk", Double(n) / 1_000) }
        return "\(n)"
    }

    private var formattedMessages: String {
        guard let stats else { return "—" }
        return "\(stats.messageCount)"
    }
}

struct UsageStatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textMuted)
                Text(title)
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textMuted)
            }
            
            Text(value)
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.mimo.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(16)
        .background(Color.mimo.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.mimo.border, lineWidth: Color.mimo.isLightTheme ? 1 : 0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SettingsRow<Trailing: View>: View {
    let title: String
    let description: String
    @ViewBuilder let trailing: Trailing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .interfaceFont(size: 14, weight: .medium)
                        .foregroundColor(Color.mimo.textPrimary)
                    Text(description)
                        .interfaceFont(size: 12)
                        .foregroundColor(Color.mimo.textMuted)
                }
                
                Spacer()
                
                trailing
            }
        }
        .padding(.vertical, 12)
        
        Divider()
    }
}

struct SettingsToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        SettingsRow(title: title, description: description) {
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}

// MARK: - Providers Settings View

/// Unified Providers tab (plan Раздел 1): the rich model/provider/details
/// columns from ModelSettingsView, the provider-management list from
/// ProvidersSettingsView, and a Local Providers section (Ollama / OpenCode /
/// MiCoder CLI) with auto-detect by address.
struct UnifiedProvidersView: View {
    @EnvironmentObject var appState: AppState
    let availableWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            ModelSettingsView(availableWidth: availableWidth)
            Divider().background(Color.mimo.border)
            LocalProvidersSection()
            Divider().background(Color.mimo.border)
            WebProvidersSection()
            Divider().background(Color.mimo.border)
            ProvidersSettingsView()
        }
    }
}

/// Local provider configuration + auto-detection by host:port (plan Раздел 1
/// Блок 4 + Раздел 9 Блок 3). Uses ProviderAutoDetector / LocalProviderLogic.
struct LocalProvidersSection: View {
    @EnvironmentObject var appState: AppState
    @State private var address: String = "localhost:11434"
    @State private var detecting = false
    @State private var detectResult: String = ""
    @State private var locals: [LocalProviderConfig] = LocalProviderLogic.load()
    // E23: auto-detection must never add a provider on its own — it presents
    // the finding and the user explicitly confirms or cancels.
    @State private var pendingDetection: PendingDetection?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Local providers")
                .interfaceFont(size: 18, weight: .semibold)
                .foregroundColor(Color.mimo.textPrimary)
            Text("Run models locally via Ollama, OpenCode, or MiCoder CLI/Serve. Enter an address to auto-detect the provider and load its models.")
                .interfaceFont(size: 13)
                .foregroundColor(Color.mimo.textSecondary)

            // Auto-detect by address
            HStack(spacing: 8) {
                TextField("localhost:11434 or 192.168.1.10:4096", text: $address)
                    .zcodeTextFieldStyle()
                    .interfaceFont(size: 13)
                Button(action: { runAutoDetect() }) {
                    HStack(spacing: 4) {
                        if detecting { ProgressView().controlSize(.small) }
                        Image(systemName: "wand.and.stars")
                        Text(detecting ? "Detecting…" : "Auto-detect")
                    }
                    .interfaceFont(size: 13)
                    .foregroundColor(Color.mimo.brand)
                }
                .buttonStyle(.plain)
                .disabled(detecting)
            }

            if !detectResult.isEmpty {
                Text(detectResult)
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textSecondary)
            }

            // Quick-add cards for the three local kinds
            HStack(spacing: 12) {
                ForEach(LocalProviderKind.allCases) { kind in
                    LocalProviderCard(kind: kind, isAdded: locals.contains { $0.kind == kind }) {
                        addLocal(kind: kind)
                    }
                }
            }

            // Configured local providers
            if !locals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(locals) { cfg in
                        LocalProviderRow(config: cfg,
                                         onRemove: { removeLocal(cfg) },
                                         onToggle: { toggleLocal(cfg) })
                    }
                }
                .padding(12)
                .background(Color.mimo.surface)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .alert(item: $pendingDetection) { pending in
            Alert(
                title: Text(LocalProviderConfirmLogic.title(for: pending.info)),
                message: Text(LocalProviderConfirmLogic.message(for: pending.info,
                                                                host: pending.host,
                                                                port: pending.port)),
                primaryButton: .default(Text("Confirm and add")) {
                    confirmPendingDetection()
                },
                secondaryButton: .cancel {
                    // E23: a cancel must not leave "Detected: …" on screen —
                    // nothing was added, so say so.
                    detectResult = AutoDetectStatusText.cancelled()
                    pendingDetection = nil
                }
            )
        }
    }

    private func parseAddress() -> (host: String, port: Int)? {
        let parts = address.split(separator: ":")
        guard parts.count == 2, let port = Int(parts[1]) else { return nil }
        return (String(parts[0]), port)
    }

    private func runAutoDetect() {
        guard let (host, port) = parseAddress() else {
            detectResult = AutoDetectStatusText.invalidAddress()
            return
        }
        // E24/п.34: keep the non-local warning visible — it used to be set here
        // and then immediately wiped by `detectResult = ""` below, so the
        // "is this really your local server?" warning never displayed.
        let warning = AutoDetectStatusText.warningForNonLocal(host)
        detecting = true
        detectResult = ""
        Task {
            let probe = URLSessionProviderProbe()
            let info = await ProviderAutoDetector.detect(host: host, port: port, probe: probe)
            await MainActor.run {
                detecting = false
                let line: String
                if let info = info {
                    line = AutoDetectStatusText.detected(info, host: host, port: port)
                    // E23: never add on our own — hold the finding for the
                    // user's explicit confirm/cancel decision.
                    pendingDetection = PendingDetection(info: info, host: host, port: port)
                } else {
                    line = AutoDetectStatusText.nothingDetected(host: host, port: port)
                }
                detectResult = [warning, line].compactMap { $0 }.joined(separator: " ")
            }
        }
    }

    private func confirmPendingDetection() {
        guard let pending = pendingDetection else { return }
        let cfg = LocalProviderConfirmLogic.config(from: pending.info, host: pending.host, port: pending.port)
        if !LocalProviderConfirmLogic.isDuplicate(locals, of: cfg) {
            locals.append(cfg)
            LocalProviderLogic.save(locals)
        }
        detectResult = AutoDetectStatusText.confirmed(pending.info, host: pending.host, port: pending.port)
        pendingDetection = nil
    }

    private func addLocal(kind: LocalProviderKind) {
        guard !locals.contains(where: { $0.kind == kind }) else { return }
        locals.append(LocalProviderConfig(kind: kind))
        LocalProviderLogic.save(locals)
    }

    private func removeLocal(_ cfg: LocalProviderConfig) {
        locals.removeAll { $0.id == cfg.id }
        LocalProviderLogic.save(locals)
    }

    private func toggleLocal(_ cfg: LocalProviderConfig) {
        if let idx = locals.firstIndex(where: { $0.id == cfg.id }) {
            locals[idx].isEnabled.toggle()
            LocalProviderLogic.save(locals)
        }
    }
}

/// A detected provider held for the user's explicit confirm/cancel decision
/// (E23). `Identifiable` so it can drive `.alert(item:)`.
struct PendingDetection: Identifiable {
    let id = UUID()
    let info: DetectedProviderInfo
    let host: String
    let port: Int
}

struct LocalProviderCard: View {
    let kind: LocalProviderKind
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            VStack(spacing: 6) {
                Image(systemName: kind.icon)
                    .interfaceFont(size: 20)
                    .foregroundColor(Color.mimo.brand)
                Text(kind.displayName)
                    .interfaceFont(size: 12, weight: .medium)
                    .foregroundColor(Color.mimo.textPrimary)
                Text(isAdded ? "Added" : "Add")
                    .interfaceFont(size: 10)
                    .foregroundColor(isAdded ? Color.mimo.success : Color.mimo.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.mimo.surface)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isAdded)
    }
}

struct LocalProviderRow: View {
    let config: LocalProviderConfig
    let onRemove: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: config.kind.icon)
                .interfaceFont(size: 14)
                .foregroundColor(Color.mimo.textSecondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(config.displayName)
                    .interfaceFont(size: 13, weight: .medium)
                    .foregroundColor(Color.mimo.textPrimary)
                Text("\(config.serveBaseURL) · \(config.models.count) models")
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
            }
            Spacer()
            Button(action: onToggle) {
                Text(config.isEnabled ? "Enabled" : "Disabled")
                    .interfaceFont(size: 11, weight: .medium)
                    .foregroundColor(config.isEnabled ? Color.mimo.success : Color.mimo.textMuted)
            }
            .buttonStyle(.plain)
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.error)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

struct ProvidersSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddProvider = false
    @State private var providerFilter = ""
    @State private var newProviderName = ""
    @State private var newProviderType: ProviderType = .openAI
    @State private var newProviderURL = ""
    @State private var newProviderKey = ""
    
    private var filteredProviders: [ProviderOption] {
        if providerFilter.isEmpty {
            return appState.providerOptions
        }
        return appState.providerOptions.filter {
            $0.name.localizedCaseInsensitiveContains(providerFilter)
        }
    }
    
    private var providerCount: Int {
        appState.providerOptions.count
    }
    
    private var modelCount: Int {
        appState.availableModels.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Providers")
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)
            
            Text("Manage custom model providers and view server-connected providers.")
                .interfaceFont(size: 14)
                .foregroundColor(Color.mimo.textSecondary)
            
            // Stats chips
            HStack(spacing: 16) {
                ProviderCountChip(title: L.t("Providers"), count: providerCount)
                ProviderCountChip(title: L.t("Models"), count: modelCount)
                Spacer()
            }
            
            // Search and add
            searchAndAddSection
            
            // Providers list
            providersList
            
            // Add provider sheet
            if showAddProvider {
                AddProviderSheet(
                    isPresented: $showAddProvider,
                    name: $newProviderName,
                    type: $newProviderType,
                    url: $newProviderURL,
                    apiKey: $newProviderKey
                )
                .environmentObject(appState)
            }
        }
    }
    
    private var searchAndAddSection: some View {
        HStack {
            TextField("Search providers...", text: $providerFilter)
                .zcodeTextFieldStyle()
                .interfaceFont(size: 13)
            
            Button(action: { showAddProvider = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add")
                }
                .interfaceFont(size: 13)
                .foregroundColor(Color.mimo.brand)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var providersList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Providers")
                .interfaceFont(size: 16, weight: .semibold)
                .foregroundColor(Color.mimo.textPrimary)
            
            if filteredProviders.isEmpty {
                Text("No providers configured")
                    .interfaceFont(size: 13)
                    .foregroundColor(Color.mimo.textMuted)
                    .padding(16)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(filteredProviders) { option in
                        ProviderRowView(option: option)
                    }
                }
                .padding(12)
                .background(Color.mimo.surface)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Provider Count Chip

struct ProviderCountChip: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: title == L.t("Providers") ? "server.rack" : "cpu")
                .interfaceFont(size: 10)
                .foregroundColor(Color.mimo.textMuted)
            Text(title)
                .interfaceFont(size: 10)
                .foregroundColor(Color.mimo.textSecondary)
            Text("\(count)")
                .interfaceFont(size: 12, weight: .semibold)
                .foregroundColor(Color.mimo.brand)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.mimo.backgroundAlt.opacity(0.5))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Provider Row View

struct ProviderRowView: View {
    let option: ProviderOption
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: option.isCustom ? "network.badge" : "server")
                    .interfaceFont(size: 14)
                    .foregroundColor(option.isCustom ? Color.mimo.brand : Color.mimo.textSecondary)
                
                Text(option.name)
                    .interfaceFont(size: 13, weight: .medium)
                    .foregroundColor(Color.mimo.textPrimary)
                
                Spacer()
                
                Circle()
                    .fill(option.isConnected ? Color.mimo.success : Color.mimo.textMuted)
                    .frame(width: 8, height: 8)
                
                Button(action: {
                    if option.isCustom,
                       let custom = appState.customProviders.first(where: { $0.id == option.id }) {
                        appState.removeCustomProvider(custom)
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .interfaceFont(size: 14)
                        .foregroundColor(Color.mimo.error.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help("Remove provider")
                .opacity(option.isCustom ? 1 : 0)
            }
            
            if option.isCustom,
               let custom = appState.customProviders.first(where: { $0.id == option.id }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(custom.baseURL)
                        .interfaceFont(size: 11, design: .monospaced)
                        .foregroundColor(Color.mimo.textMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    HStack {
                        Text("\(custom.models.count) models")
                            .interfaceFont(size: 11)
                            .foregroundColor(Color.mimo.textSecondary)
                        
                        if custom.supportsTools {
                            Image(systemName: "checkmark.circle")
                                .interfaceFont(size: 10)
                                .foregroundColor(Color.mimo.cyan)
                        }
                        
                        if custom.acpEnabled {
                            Image(systemName: "gearshape")
                                .interfaceFont(size: 10)
                                .foregroundColor(Color.mimo.violet)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color.mimo.surface)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Model Parameter Spoiler

struct ModelParameterSpoiler: View {
    let modelID: String
    let meta: MimoProviderModel?
    let providerID: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let meta = meta {
                VStack(alignment: .leading, spacing: 6) {
                    ParameterRow(label: "Context", value: "\(meta.limit?.context.map { "\($0/1000)k" } ?? "—")")
                    ParameterRow(label: "Output", value: "\(meta.limit?.output.map { "\($0)" } ?? "—")")
                    ParameterRow(label: "Reasoning", value: meta.capabilities?.reasoning == true ? "Yes" : "No")
                    ParameterRow(label: "Tools", value: meta.capabilities?.toolcall != false ? "Yes" : "No")
                    ParameterRow(label: "Plan", value: meta.capabilities?.plan == true ? "Yes" : "No")
                    
                    if let cost = meta.cost {
                        ParameterRow(label: "Cost", value: "\(cost.input ?? 0)/\(cost.output ?? 0) per 1K tokens")
                    }
                    
                    if let variants = meta.variants, !variants.isEmpty {
                        ParameterRow(label: "Variants", value: variants.keys.sorted().joined(separator: ", "))
                    }
                }
                .interfaceFont(size: 11)
            } else {
                Text("No parameters available")
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
            }
        }
        .padding(8)
        .background(Color.mimo.backgroundAlt.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private struct ParameterRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label + ":")
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)
                Spacer()
                Text(value)
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textPrimary)
            }
        }
    }
}

// MARK: - Model Detail Spoiler

struct ModelDetailSpoiler: View {
    let modelID: String
    let providerID: String
    let meta: MimoProviderModel?
    @EnvironmentObject var appState: AppState
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text("Model Details")
                        .interfaceFont(size: 12, weight: .semibold)
                        .foregroundColor(Color.mimo.textPrimary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .interfaceFont(size: 10)
                        .foregroundColor(Color.mimo.textMuted)
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded, let meta = meta {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Configuration")
                        .interfaceFont(size: 11, weight: .semibold)
                        .foregroundColor(Color.mimo.textSecondary)
                    
                    ParameterDetailRow(label: "ID", value: meta.id)
                    ParameterDetailRow(label: L.t("Name"), value: meta.name ?? "—")
                    ParameterDetailRow(label: "Provider", value: meta.providerID ?? providerID)
                    
                    if let context = meta.limit?.context {
                        ParameterDetailRow(label: "Context Length", value: "\(context)")
                    }
                    
                    if let capabilities = meta.capabilities {
                        ParameterDetailRow(label: "Reasoning", value: capabilities.reasoning == true ? "Supported" : "Not supported")
                        ParameterDetailRow(label: "Tool Calling", value: capabilities.toolcall != false ? "Supported" : "Not supported")
                        ParameterDetailRow(label: "Plan Mode", value: capabilities.plan == true ? "Supported" : "Not supported")
                    }
                    
                    if let variants = meta.variants, !variants.isEmpty {
                        ParameterDetailRow(label: "Variants", value: variants.keys.sorted().joined(separator: ", "))
                    }
                }
                .interfaceFont(size: 11)
                .padding(8)
                .background(Color.mimo.backgroundAlt)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
    
    private struct ParameterDetailRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
                Spacer()
                Text(value)
                    .interfaceFont(size: 11, weight: .medium)
                    .foregroundColor(Color.mimo.textPrimary)
                    .lineLimit(1)
            }
        }
    }
}
