import SwiftUI

enum ModelSortOrder: String, CaseIterable, Identifiable {
    case name
    case context
    case reasoning
    case tools

    var id: String { rawValue }
    var title: String {
        switch self {
        case .name: return "Name"
        case .context: return "Context"
        case .reasoning: return "Reasoning"
        case .tools: return "Tools"
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
            Text(L.t(AppLocalizationKey.locModelSettings))
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)
            
            Text(L.t(AppLocalizationKey.locConfigureModelProvidersAndManageAvailableModels))
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
    @State private var parameterModelID: String = ""
    @State private var parameterProviderID: String = ""
    @State private var parameterTemperature: String = ""
    @State private var parameterMaxTokens: String = ""
    @State private var parameterTopP: String = ""
    @State private var parameterSystemPrompt: String = ""
    @State private var parameterError: String?
    @State private var modelSearchQuery: String = ""
    @State private var modelSortOrder: ModelSortOrder = .name
    @State private var collapsedProviderCategories: Set<String> = []
    @State private var collapsedModelGroups: Set<String> = []

    private var options: [ProviderOption] {
        appState.providerOptions
    }

    private func webConfig(for providerID: String) -> WebProviderConfig? {
        guard let id = WebProviderConnectivity.configID(fromOptionID: providerID) else { return nil }
        return WebProviderStore.load().first(where: { $0.id == id })
    }

    private func isMutableProvider(_ option: ProviderOption) -> Bool {
        option.isCustom || webConfig(for: option.id) != nil
    }

    private func selectProvider(_ option: ProviderOption) {
        detailProviderID = option.id
        appState.selectProvider(option.id)
    }

    private func removeProvider(_ option: ProviderOption) {
        if let custom = appState.customProviders.first(where: { $0.id == option.id }) {
            appState.removeCustomProvider(custom)
            return
        }
        if let web = webConfig(for: option.id) {
            var configs = WebProviderStore.load()
            configs.removeAll { $0.id == web.id }
            WebProviderStore.save(configs)
            try? WebSessionManager.clear(providerId: web.id,
                                         homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
            if appState.selectedProviderID == option.id { appState.selectProvider("") }
        }
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
                Text(L.t(AppLocalizationKey.locProvidersModels))
                    .interfaceFont(size: 16, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Spacer()
                Button(action: { appState.addOpenCodeZenProvider() }) {
                    Label("OpenCode Zen", systemImage: "sparkles")
                        .interfaceFont(size: 13)
                        .foregroundColor(Color.mimo.violet)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add or select OpenCode Zen")

                Button(action: { showAddProvider = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text(L.t(AppLocalizationKey.locAddProvider1))
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
                .frame(height: 480)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        providerListColumn
                            .frame(maxWidth: .infinity)
                        providerDetailColumn
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 240)

                    modelsColumn
                        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
                }
            }

            if !parameterModelID.isEmpty {
                modelParametersPanel
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

    private var providerGroups: [(key: String, options: [ProviderOption])] {
        let grouped = Dictionary(grouping: options) { providerCategory(for: $0) }
        return grouped.keys.sorted().map { key in
            (key: key, options: grouped[key, default: []].sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            })
        }
    }

    private func providerCategory(for option: ProviderOption) -> String {
        if let custom = appState.customProviders.first(where: { $0.id == option.id }),
           custom.type == .openCodeZen {
            return "OpenCode Zen"
        }
        if option.isCustom { return "Custom providers" }
        if WebProviderConnectivity.configID(fromOptionID: option.id) != nil { return "Web providers" }
        if LocalProviderLogic.load().contains(where: { $0.id == option.id }) { return "Local providers" }
        return "Built-in providers"
    }

    private func providerCategoryIcon(_ category: String) -> String {
        switch category {
        case "OpenCode Zen": return "sparkles"
        case "Custom providers": return "server.rack"
        case "Web providers": return "globe"
        case "Local providers": return "desktopcomputer"
        default: return "sparkles"
        }
    }

    private var providerListColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L.t(AppLocalizationKey.locProviders))
                .interfaceFont(size: 12, weight: .semibold)
                .foregroundColor(Color.mimo.textMuted)
                .padding(.bottom, 8)

            if options.isEmpty {
                SettingsCardEmptyState(
                    icon: "server.rack",
                    title: L.t(AppLocalizationKey.locProvidersYet),
                    hint: L.t(AppLocalizationKey.locConnectTheLocalAgentAddCustomProviderGetStarted),
                    actionTitle: L.t(AppLocalizationKey.locAddProvider),
                    action: { showAddProvider = true }
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(providerGroups.indices, id: \.self) { groupIndex in
                            let group = providerGroups[groupIndex]
                            let isCollapsed = collapsedProviderCategories.contains(group.key)
                            VStack(spacing: 4) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.16)) {
                                        if isCollapsed {
                                            collapsedProviderCategories.remove(group.key)
                                        } else {
                                            collapsedProviderCategories.insert(group.key)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: isCollapsed ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
                                            .interfaceFont(size: 12, weight: .semibold)
                                            .foregroundColor(Color.mimo.brand)
                                        Image(systemName: providerCategoryIcon(group.key))
                                            .interfaceFont(size: 11, weight: .semibold)
                                            .foregroundColor(Color.mimo.brand)
                                        Text(group.key)
                                            .interfaceFont(size: 11, weight: .semibold)
                                            .foregroundColor(Color.mimo.textSecondary)
                                        Text("· \(group.options.count)")
                                            .interfaceFont(size: 10)
                                            .foregroundColor(Color.mimo.textMuted)
                                        Spacer()
                                        Text(isCollapsed ? "Show" : "Hide")
                                            .interfaceFont(size: 10, weight: .medium)
                                            .foregroundColor(Color.mimo.brand)
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 7)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.mimo.backgroundAlt)
                                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.mimo.border, lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                }
                                .buttonStyle(.plain)
                                .help(isCollapsed ? "Show \(group.key)" : "Hide \(group.key)")

                                if !isCollapsed {
                                    VStack(spacing: 4) {
                                        ForEach(group.options) { option in
                                            providerOptionRow(option)
                                        }
                                    }
                                    .padding(.top, 2)
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

    private func providerOptionRow(_ option: ProviderOption) -> some View {
        HStack(spacing: 6) {
            Button(action: { selectProvider(option) }) {
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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isMutableProvider(option) {
                Button(action: { selectProvider(option) }) {
                    Image(systemName: "pencil")
                        .interfaceFont(size: 10, weight: .semibold)
                        .foregroundColor(Color.mimo.textSecondary)
                        .frame(width: 25, height: 25)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Edit \(option.name)")

                Button(role: .destructive, action: { removeProvider(option) }) {
                    Image(systemName: "trash")
                        .interfaceFont(size: 10, weight: .semibold)
                        .foregroundColor(Color.mimo.error)
                        .frame(width: 25, height: 25)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Delete \(option.name)")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(detailProviderID == option.id ? Color.mimo.subtleFill : Color.mimo.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(detailProviderID == option.id ? Color.mimo.border : Color.clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var providerDetailColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
            Text(L.t(AppLocalizationKey.locDetails))
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
                    Text(webConfig(for: option.id) != nil ? L.t(AppLocalizationKey.locWebSession) : (option.isCustom ? L.t(AppLocalizationKey.locCustomProvider) : L.t(AppLocalizationKey.locLocalAgent)))
                        .interfaceFont(size: 12)
                        .foregroundColor(Color.mimo.textSecondary)
                }

                detailSummary(for: option)
                if option.isCustom, let custom = appState.customProviders.first(where: { $0.id == option.id }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L.t(AppLocalizationKey.locBaseUrl))
                            .interfaceFont(size: 11, weight: .medium)
                            .foregroundColor(Color.mimo.textSecondary)
                        TextField("https://api.example.com/v1", text: $customBaseURLDraft)
                            .zcodeTextFieldStyle()
                            .interfaceFont(size: 11, design: .monospaced)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L.t(AppLocalizationKey.locApiKey))
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
                        Button(L.t(AppLocalizationKey.locSaveConfiguration)) {
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
                        Toggle(L.t(AppLocalizationKey.locEnableToolCalling), isOn: Binding(
                            get: { custom.supportsTools },
                            set: { newValue in
                                var updated = custom
                                updated.supportsTools = newValue
                                appState.updateCustomProvider(updated)
                            }
                        ))
                        .toggleStyle(.switch)
                        .interfaceFont(size: 11)
                        Text(L.t(AppLocalizationKey.locEnableFunctiontoolCallingSupport))
                            .interfaceFont(size: 10)
                            .foregroundColor(Color.mimo.textSecondary)
                    }

                    if custom.type == .openCodeZen {
                        HStack(spacing: 7) {
                            Image(systemName: "sparkles")
                                .foregroundColor(Color.mimo.violet)
                            Text(OpenCodeZenCatalog.accessSummary(hasAPIKey: !(custom.getSecureAPIKey() ?? "").isEmpty))
                                .interfaceFont(size: 10, weight: .medium)
                                .foregroundColor(Color.mimo.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(8)
                        .background(Color.mimo.violet.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    if custom.type == .acp {
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(L.t(AppLocalizationKey.locEnableACP), isOn: Binding(
                                get: { custom.acpEnabled },
                                set: { newValue in
                                    var updated = custom
                                    updated.acpEnabled = newValue
                                    appState.updateCustomProvider(updated)
                                }
                            ))
                            .toggleStyle(.switch)
                            .interfaceFont(size: 11)
                            Text(L.t(AppLocalizationKey.locEnableAgentCoderProtocol))
                                .interfaceFont(size: 10)
                                .foregroundColor(Color.mimo.textSecondary)
                        }
                    }

                    Button(role: .destructive) {
                        appState.removeCustomProvider(custom)
                    } label: {
                        Label(L.t(AppLocalizationKey.locRemoveProvider), systemImage: "trash")
                            .interfaceFont(size: 12)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color.mimo.error)

                    Button(L.t(AppLocalizationKey.locRefreshModels)) {
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
                    Button(L.t(AppLocalizationKey.locRefreshWebModels)) {
                        Task { _ = await appState.refreshWebModels(for: web) }
                    }
                    .buttonStyle(.bordered)
                }
                if !appState.supportsToolcallForSelection && appState.selectedProviderID == option.id {
                    Text(L.t(AppLocalizationKey.locToolsUnavailableForCurrentModel))
                        .interfaceFont(size: 11)
                        .foregroundColor(Color.mimo.warning)
                }
            } else {
                SettingsCardEmptyState(
                    icon: "slider.horizontal.3",
                    title: L.t(AppLocalizationKey.locProviderSelected),
                    hint: L.t(AppLocalizationKey.locPickProviderTheLeftViewItsConnectionAndSettings)
                )
            }
        }
        }
        .settingsCardFrame()
        .padding(12)
        .background(Color.mimo.surface)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var selectedParameterMetadata: MimoProviderModel? {
        guard !parameterModelID.isEmpty else { return nil }
        return ProviderSettingsLogic.model(
            for: parameterModelID,
            in: appState.serverProviders,
            providerID: parameterProviderID.isEmpty ? nil : parameterProviderID
        )
    }

    private var selectedWebModel: WebProviderModel? {
        guard !parameterModelID.isEmpty,
              let web = webConfig(for: parameterProviderID) else { return nil }
        return web.discoveredModels.first(where: { $0.name == parameterModelID })
    }

    @ViewBuilder
    private var modelParametersPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Model parameters")
                        .interfaceFont(size: 14, weight: .semibold)
                        .foregroundColor(Color.mimo.textPrimary)
                    Text("\(parameterProviderID.isEmpty ? "Provider" : parameterProviderID) / \(parameterModelID)")
                        .interfaceFont(size: 10, design: .monospaced)
                        .foregroundColor(Color.mimo.textMuted)
                }
                Spacer()
                Button {
                    parameterModelID = ""
                    parameterError = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .interfaceFont(size: 15)
                        .foregroundColor(Color.mimo.textMuted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close model parameters")
            }

            if let webModel = selectedWebModel {
                webProfilePanel(webModel)
            }

            if let meta = selectedParameterMetadata {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Provider metadata")
                        .interfaceFont(size: 11, weight: .semibold)
                        .foregroundColor(Color.mimo.textSecondary)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 7) {
                        metadataValue("Context", meta.limit?.context.map { "\($0 / 1000)k" } ?? "—")
                        metadataValue("Output", meta.limit?.output.map { String($0) } ?? "—")
                        metadataValue("Reasoning", meta.capabilities?.reasoning == true ? "Yes" : "No")
                        metadataValue("Tools", meta.capabilities?.toolcall != false ? "Yes" : "No")
                        metadataValue("Plan", meta.capabilities?.plan == true ? "Yes" : "No")
                        metadataValue("Variants", meta.variants.map { String($0.count) } ?? "—")
                    }
                }
            } else if selectedWebModel == nil {
                Text("This provider did not return model metadata. You can still set request overrides below.")
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)
            }

            HStack(spacing: 10) {
                parameterField(title: "Temperature", placeholder: "default", text: $parameterTemperature)
                parameterField(title: "Max tokens", placeholder: "default", text: $parameterMaxTokens)
                parameterField(title: "Top P", placeholder: "default", text: $parameterTopP)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("System prompt override")
                    .interfaceFont(size: 11, weight: .medium)
                    .foregroundColor(Color.mimo.textSecondary)
                TextEditor(text: $parameterSystemPrompt)
                    .font(.system(size: 11))
                    .frame(minHeight: 58, maxHeight: 100)
                    .padding(6)
                    .background(Color.mimo.background)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mimo.border, lineWidth: 1))
            }

            if let parameterError {
                Text(parameterError)
                    .interfaceFont(size: 10, weight: .medium)
                    .foregroundColor(Color.mimo.error)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text("Blank values use provider defaults.")
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)
                Spacer()
                Button("Reset") { resetParameters() }
                    .buttonStyle(.plain)
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textSecondary)
                Button("Save parameters") { saveParameters() }
                    .buttonStyle(.borderedProminent)
                    .interfaceFont(size: 11)
            }
        }
        .padding(14)
        .background(Color.mimo.surface)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.mimo.brand.opacity(0.35), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func webProfilePanel(_ model: WebProviderModel) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Live web profile")
                .interfaceFont(size: 11, weight: .semibold)
                .foregroundColor(Color.mimo.textSecondary)
            HStack(spacing: 6) {
                Text(model.discoveryStatus == .active ? "Active" : model.discoveryStatus.rawValue)
                    .interfaceFont(size: 10, weight: .medium)
                    .foregroundColor(model.discoveryStatus == .active ? Color.mimo.success : Color.mimo.warning)
                Text(model.parameterProfile.availableKeys.isEmpty ? "No parameter controls detected" : model.parameterProfile.availableKeys.joined(separator: ", "))
                    .interfaceFont(size: 10, design: .monospaced)
                    .foregroundColor(Color.mimo.textMuted)
                    .lineLimit(2)
            }
            let detected = model.parameterProfile.values
            Text("Detected defaults: temperature \(detected.temperature.map(String.init) ?? "—") · max tokens \(detected.maxTokens.map(String.init) ?? "—") · top P \(detected.topP.map(String.init) ?? "—")")
                .interfaceFont(size: 10, design: .monospaced)
                .foregroundColor(Color.mimo.textMuted)
                .lineLimit(2)
            if !model.parameterProfile.labels.isEmpty {
                Text("Detected labels: \(model.parameterProfile.labels.joined(separator: ", "))")
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)
                    .lineLimit(2)
            }
        }
        .padding(8)
        .background(Color.mimo.backgroundAlt.opacity(Double(0.45)))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    private func metadataValue(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .interfaceFont(size: 8, weight: .bold)
                .foregroundColor(Color.mimo.textMuted)
            Text(value)
                .interfaceFont(size: 10, weight: .medium)
                .foregroundColor(Color.mimo.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func parameterField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .interfaceFont(size: 10, weight: .medium)
                .foregroundColor(Color.mimo.textSecondary)
            TextField(placeholder, text: text)
                .zcodeTextFieldStyle()
                .interfaceFont(size: 11, design: .monospaced)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openParameters(modelID: String, providerID: String) {
        parameterModelID = modelID
        parameterProviderID = providerID
        let params = ModelCallParametersStore.parameters(for: modelID)
        parameterTemperature = params.temperature.map { String($0) } ?? ""
        parameterMaxTokens = params.maxTokens.map { String($0) } ?? ""
        parameterTopP = params.topP.map { String($0) } ?? ""
        parameterSystemPrompt = params.systemPrompt ?? ""
        parameterError = nil
    }

    private func resetParameters() {
        parameterTemperature = ""
        parameterMaxTokens = ""
        parameterTopP = ""
        parameterSystemPrompt = ""
        saveParameters()
    }

    private func saveParameters() {
        guard !parameterModelID.isEmpty else { return }
        let trimmedTemperature = parameterTemperature.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMaxTokens = parameterMaxTokens.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTopP = parameterTopP.trimmingCharacters(in: .whitespacesAndNewlines)
        let temperature = trimmedTemperature.isEmpty ? nil : Double(trimmedTemperature)
        let maxTokens = trimmedMaxTokens.isEmpty ? nil : Int(trimmedMaxTokens)
        let topP = trimmedTopP.isEmpty ? nil : Double(trimmedTopP)
        guard trimmedTemperature.isEmpty || temperature != nil,
              trimmedMaxTokens.isEmpty || maxTokens != nil,
              trimmedTopP.isEmpty || topP != nil else {
            parameterError = "Use numeric values for temperature, max tokens and top P."
            return
        }
        if let temperature, !(0...2).contains(temperature) {
            parameterError = "Temperature must be between 0 and 2."
            return
        }
        if let maxTokens, maxTokens <= 0 {
            parameterError = "Max tokens must be greater than 0."
            return
        }
        if let topP, !(0...1).contains(topP) {
            parameterError = "Top P must be between 0 and 1."
            return
        }
        ModelCallParametersStore.set(
            ModelCallParameters(
                temperature: temperature,
                maxTokens: maxTokens,
                topP: topP,
                systemPrompt: {
                    let trimmed = parameterSystemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? nil : trimmed
                }()
            ),
            for: parameterModelID
        )
        parameterError = nil
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
            HStack {
                Text(L.t(AppLocalizationKey.locModels))
                    .interfaceFont(size: 12, weight: .semibold)
                    .foregroundColor(Color.mimo.textMuted)
                Spacer()
                Menu {
                    ForEach(ModelSortOrder.allCases) { order in
                        Button {
                            modelSortOrder = order
                        } label: {
                            Label(order.title, systemImage: modelSortOrder == order ? "checkmark" : "arrow.up.arrow.down")
                        }
                    }
                } label: {
                    Label("Sort: \(modelSortOrder.title)", systemImage: "arrow.up.arrow.down")
                        .interfaceFont(size: 10, weight: .medium)
                        .foregroundColor(Color.mimo.brand)
                }
                .menuStyle(.borderlessButton)
            }

            let providerID = detailProviderID.isEmpty ? appState.selectedProviderID : detailProviderID
            let allModels = models(for: providerID)
            let filteredModels = visibleModelIDs(allModels, providerID: providerID)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
                TextField("Filter models", text: $modelSearchQuery)
                    .textFieldStyle(.plain)
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textPrimary)
                if !modelSearchQuery.isEmpty {
                    Button {
                        modelSearchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .interfaceFont(size: 10)
                            .foregroundColor(Color.mimo.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(Color.mimo.background)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mimo.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            if allModels.isEmpty {
                SettingsCardEmptyState(
                    icon: "cpu",
                    title: L.t(AppLocalizationKey.locModelsLoaded),
                    hint: providerID.isEmpty
                        ? L.t(AppLocalizationKey.locSelectProviderToBrowseModels)
                        : L.t(AppLocalizationKey.locStartLocalAgentOrCheck)
                )
            } else if filteredModels.isEmpty {
                Text("No models match this filter.")
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
                    .padding(.vertical, 8)
            } else {
                Text("\(filteredModels.count) of \(allModels.count) models")
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)

                let groups = Self.groupedModels(filteredModels, providerID: providerID, serverProviders: appState.serverProviders, customProviders: appState.customProviders)
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(groups.indices, id: \.self) { groupIndex in
                            let group = groups[groupIndex]
                            let key = modelGroupKey(prefix: group.prefix, providerID: providerID)
                            let isCollapsed = collapsedModelGroups.contains(key)
                            VStack(spacing: 4) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.16)) {
                                        if isCollapsed {
                                            collapsedModelGroups.remove(key)
                                        } else {
                                            collapsedModelGroups.insert(key)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: isCollapsed ? "rectangle.expand.vertical" : "rectangle.compress.vertical")
                                            .interfaceFont(size: 12, weight: .semibold)
                                            .foregroundColor(Color.mimo.brand)
                                        Image(systemName: "cube.fill")
                                            .interfaceFont(size: 11)
                                            .foregroundColor(Color.mimo.textMuted)
                                        Text(group.prefix ?? "All models")
                                            .interfaceFont(size: 11, weight: .semibold, design: .monospaced)
                                            .foregroundColor(Color.mimo.textSecondary)
                                        Text("· \(group.models.count)")
                                            .interfaceFont(size: 10)
                                            .foregroundColor(Color.mimo.textMuted)
                                        Spacer()
                                        Text(isCollapsed ? "Show" : "Hide")
                                            .interfaceFont(size: 10, weight: .medium)
                                            .foregroundColor(Color.mimo.brand)
                                    }
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 7)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.mimo.backgroundAlt)
                                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.mimo.border, lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 7))
                                }
                                .buttonStyle(.plain)
                                .help(isCollapsed ? "Show models" : "Hide models")

                                if !isCollapsed {
                                    VStack(spacing: 2) {
                                        ForEach(group.models, id: \.self) { modelID in
                                            compactModelCard(modelID: modelID, providerID: providerID, prefix: group.prefix)
                                        }
                                    }
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

    private func visibleModelIDs(_ models: [String], providerID: String) -> [String] {
        let query = modelSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = query.isEmpty ? models : models.filter { modelID in
            let meta = ProviderSettingsLogic.model(
                for: modelID,
                in: appState.serverProviders,
                providerID: providerID.isEmpty ? nil : providerID
            )
            return modelID.localizedCaseInsensitiveContains(query)
                || (meta?.name?.localizedCaseInsensitiveContains(query) == true)
        }
        return filtered.sorted { lhs, rhs in
            switch modelSortOrder {
            case .name:
                return Self.splitModelID(lhs).name.localizedCaseInsensitiveCompare(Self.splitModelID(rhs).name) == .orderedAscending
            case .context:
                let left = ProviderSettingsLogic.model(for: lhs, in: appState.serverProviders, providerID: providerID.isEmpty ? nil : providerID)?.limit?.context ?? -1
                let right = ProviderSettingsLogic.model(for: rhs, in: appState.serverProviders, providerID: providerID.isEmpty ? nil : providerID)?.limit?.context ?? -1
                return left == right ? lhs < rhs : left > right
            case .reasoning:
                let left = ProviderSettingsLogic.model(for: lhs, in: appState.serverProviders, providerID: providerID.isEmpty ? nil : providerID)?.capabilities?.reasoning == true
                let right = ProviderSettingsLogic.model(for: rhs, in: appState.serverProviders, providerID: providerID.isEmpty ? nil : providerID)?.capabilities?.reasoning == true
                return left == right ? lhs < rhs : left && !right
            case .tools:
                let left = ProviderSettingsLogic.model(for: lhs, in: appState.serverProviders, providerID: providerID.isEmpty ? nil : providerID)?.capabilities?.toolcall != false
                let right = ProviderSettingsLogic.model(for: rhs, in: appState.serverProviders, providerID: providerID.isEmpty ? nil : providerID)?.capabilities?.toolcall != false
                return left == right ? lhs < rhs : left && !right
            }
        }
    }

    private func modelGroupKey(prefix: String?, providerID: String) -> String {
        "\(providerID)::\(prefix ?? "__all__")"
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

            if appState.customProviders.contains(where: { $0.id == providerID }) {
                Button {
                    appState.removeModel(modelID, from: providerID)
                } label: {
                    Image(systemName: "trash")
                        .interfaceFont(size: 11, weight: .semibold)
                        .foregroundColor(Color.mimo.error)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove model \(modelID)")
            }

            // Three-dot menu
            Menu {
                // Selection is performed by clicking the full model row.
                // Keep the menu for parameters and secondary actions only.
                Button(action: {
                    openParameters(modelID: modelID, providerID: providerID)
                }) {
                    Label(L.t(AppLocalizationKey.locParameters), systemImage: "slider.horizontal.3")
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
                        Reasoning: \(meta.capabilities?.reasoning == true ? L.t(AppLocalizationKey.locYes) : L.t(AppLocalizationKey.locNo))
                        Tools: \(meta.capabilities?.toolcall != false ? L.t(AppLocalizationKey.locYes) : L.t(AppLocalizationKey.locNo))
                        Plan: \(meta.capabilities?.plan == true ? L.t(AppLocalizationKey.locYes) : L.t(AppLocalizationKey.locNo))
                        Cost: \(meta.cost.map { "\(String(describing: $0.input))/\(String(describing: $0.output)) per 1K" } ?? "—")
                        """
                        NSPasteboard.general.setString(info, forType: .string)
                    }) {
                        Label(L.t(AppLocalizationKey.locCopyInfo), systemImage: "doc.on.doc")
                    }
                }

                // OmniRouter/agentRouter special config
                if isAgentRouterModel(modelID: modelID, providerID: providerID) {
                    Divider()
                    Button(action: {
                        toggleToolResultFix(for: modelID)
                    }) {
                        Label(
                            isToolResultFixEnabled(for: modelID) ? L.t(AppLocalizationKey.locToolResultFixOn) : L.t(AppLocalizationKey.locToolResultFixOff),
                            systemImage: isToolResultFixEnabled(for: modelID) ? "checkmark.shield.fill" : "shield.slash"
                        )
                    }
                }
            } label: {
                Image(systemName: "ellipsis.vertical")
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
        .onTapGesture {
            guard !isSelected else { return }
            if !providerID.isEmpty {
                appState.selectProvider(providerID)
            }
            appState.selectModel(modelID)
        }
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
                    Text(L.t(AppLocalizationKey.locUrl))
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
                        Text(L.t(AppLocalizationKey.locModels1))
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
    @State private var testSucceeded: Bool?
    @State private var supportsTools = true
    @State private var acpEnabled = false
    @State private var requiresAPIKey = true
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L.t(AppLocalizationKey.locAddProvider))
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
                        Text(L.t(AppLocalizationKey.locProviderType))
                            .interfaceFont(size: 13, weight: .medium)
                            .foregroundColor(Color.mimo.textPrimary)
                        
                        Picker(L.t(AppLocalizationKey.locProviderType), selection: $type) {
                            ForEach(ProviderType.allCases) { t in
                                Label(t.rawValue, systemImage: t.icon).tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: type) { newType in
                            url = newType.defaultURL
                            requiresAPIKey = ProviderEndpointLogic.defaultRequiresAPIKey(for: newType)
                            if newType == .openCodeZen,
                               name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                name = "OpenCode Zen"
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L.t(AppLocalizationKey.locName))
                            .interfaceFont(size: 13, weight: .medium)
                            .foregroundColor(Color.mimo.textPrimary)
                        TextField("e.g., My OpenRouter", text: $name)
                            .zcodeTextFieldStyle()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L.t(AppLocalizationKey.locBaseUrl))
                            .interfaceFont(size: 13, weight: .medium)
                            .foregroundColor(Color.mimo.textPrimary)
                        TextField("API endpoint URL", text: $url)
                            .zcodeTextFieldStyle()
                            .interfaceFont(size: 12, design: .monospaced)
                        if !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                           ProviderEndpointLogic.normalizedBaseURL(url) == nil {
                            Text("Enter a valid http:// or https:// endpoint without a query string.")
                                .interfaceFont(size: 10)
                                .foregroundColor(Color.mimo.error)
                        }
                    }
                    
                    if type != .ollama && type != .acp && (requiresAPIKey || type == .openCodeZen) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(type == .openCodeZen ? "OpenCode Zen API key (optional)" : L.t(AppLocalizationKey.locApiKey))
                                .interfaceFont(size: 13, weight: .medium)
                                .foregroundColor(Color.mimo.textPrimary)
                            SecureField(type == .openModel ? "om-..." : "sk-...", text: $apiKey)
                                .zcodeTextFieldStyle()
                            if type == .openCodeZen {
                                Text("No key: temporary free chat models only. A Zen key enables the curated paid chat-compatible catalog.")
                                    .interfaceFont(size: 11)
                                    .foregroundColor(Color.mimo.textSecondary)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(type == .openCodeZen ? "Require a Zen API key" : L.t(AppLocalizationKey.locRequiresAPIKey), isOn: $requiresAPIKey)
                            .interfaceFont(size: 13, weight: .medium)
                        Text(L.t(AppLocalizationKey.locDisableForLocalModelsProvidersThatDontNeedAuthe))
                            .interfaceFont(size: 11)
                            .foregroundColor(Color.mimo.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(L.t(AppLocalizationKey.locEnableToolCalling), isOn: $supportsTools)
                            .interfaceFont(size: 13, weight: .medium)
                        Text(L.t(AppLocalizationKey.locEnableFunctiontoolCallingSupportForThisProvider))
                            .interfaceFont(size: 11)
                            .foregroundColor(Color.mimo.textSecondary)
                    }
                    
                    if type == .acp {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(L.t(AppLocalizationKey.locEnableACP), isOn: $acpEnabled)
                                .interfaceFont(size: 13, weight: .medium)
                            Text(L.t(AppLocalizationKey.locEnableAgentCoderProtocolForAutonomousCodingTask))
                                .interfaceFont(size: 11)
                                .foregroundColor(Color.mimo.textSecondary)
                        }
                    }
                    
                    if let result = testResult, let succeeded = testSucceeded {
                        ProviderConnectionResultBanner(message: result, succeeded: succeeded)
                    }
                }
                .padding(16)
            }
            
            Divider()
            
            HStack {
                Button(action: {
                    isTesting = true
                    Task {
                        let success = await appState.testProvider(
                            url: ProviderEndpointLogic.normalizedBaseURL(url) ?? url,
                            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
                            type: type
                        )
                        await MainActor.run {
                            isTesting = false
                            testSucceeded = success
                            testResult = success ? L.t(AppLocalizationKey.locConnectionSuccess) : L.t(AppLocalizationKey.locConnectionFailed)
                        }
                    }
                }) {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text(L.t(AppLocalizationKey.locTestConnection))
                    }
                }
                .buttonStyle(.bordered)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          ProviderEndpointLogic.normalizedBaseURL(url) == nil)
                
                Spacer()
                
                Button(L.t(AppLocalizationKey.locCancel)) {
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(Color.mimo.textSecondary)
                
                Button(action: {
                    guard let normalizedURL = ProviderEndpointLogic.normalizedBaseURL(url) else { return }
                    let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let provider = CustomProvider(
                        id: UUID().uuidString,
                        name: normalizedName.isEmpty ? type.rawValue : normalizedName,
                        type: type,
                        baseURL: normalizedURL,
                        apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
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
                    Text(L.t(AppLocalizationKey.locAddProvider))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                             ProviderEndpointLogic.normalizedBaseURL(url) == nil
                             ? Color.mimo.textMuted : Color.mimo.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          ProviderEndpointLogic.normalizedBaseURL(url) == nil)
            }
            .padding(16)
        }
        .frame(width: 480, height: 600)
        .background(Color.mimo.background)
    }
}


private struct ProviderConnectionResultBanner: View {
    let message: String
    let succeeded: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: succeeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .interfaceFont(size: 17, weight: .semibold)
                .foregroundColor(succeeded ? Color.mimo.success : Color.mimo.error)
            VStack(alignment: .leading, spacing: 2) {
                Text(succeeded ? "Connection verified" : "Connection failed")
                    .interfaceFont(size: 12, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Text(message)
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background((succeeded ? Color.mimo.success : Color.mimo.error).opacity(0.13))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke((succeeded ? Color.mimo.success : Color.mimo.error).opacity(0.55), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}
