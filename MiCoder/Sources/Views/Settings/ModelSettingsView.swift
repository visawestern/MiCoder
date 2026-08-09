import SwiftUI

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
                Text(L.t(AppLocalizationKey.locProvidersModels))
                    .interfaceFont(size: 16, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Spacer()
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
            Text(L.t(AppLocalizationKey.locModels))
                .interfaceFont(size: 12, weight: .semibold)
                .foregroundColor(Color.mimo.textMuted)

            let models = models(for: detailProviderID.isEmpty ? appState.selectedProviderID : detailProviderID)
            let providerID = detailProviderID.isEmpty ? appState.selectedProviderID : detailProviderID

            if models.isEmpty {
                SettingsCardEmptyState(
                    icon: "cpu",
                    title: L.t(AppLocalizationKey.locModelsLoaded),
                    hint: providerID.isEmpty
                        ? L.t(AppLocalizationKey.locSelectProviderToBrowseModels)
                        : L.t(AppLocalizationKey.locStartLocalAgentOrCheck)
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
                    Label(L.t(AppLocalizationKey.locSelect), systemImage: isSelected ? "checkmark.circle.fill" : "circle")
                }

                Divider()

                Button(action: {
                    // Show model parameters in a popover/inline detail
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
                    }
                    
                    if type != .ollama && type != .acp && requiresAPIKey {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L.t(AppLocalizationKey.locApiKey))
                                .interfaceFont(size: 13, weight: .medium)
                                .foregroundColor(Color.mimo.textPrimary)
                            SecureField(type == .openModel ? "om-..." : "sk-...", text: $apiKey)
                                .zcodeTextFieldStyle()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(L.t(AppLocalizationKey.locRequiresAPIKey), isOn: $requiresAPIKey)
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
                .disabled(name.isEmpty || url.isEmpty)
                
                Spacer()
                
                Button(L.t(AppLocalizationKey.locCancel)) {
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
                    Text(L.t(AppLocalizationKey.locAddProvider))
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
