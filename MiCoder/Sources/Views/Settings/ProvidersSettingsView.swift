import SwiftUI

struct UnifiedProvidersView: View {
    @EnvironmentObject var appState: AppState
    let availableWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            MiMoAutoSection()
            Divider().background(Color.mimo.border)
            ModelSettingsView(availableWidth: availableWidth)
            Divider().background(Color.mimo.border)
            LocalProvidersSection()
            Divider().background(Color.mimo.border)
            WebProvidersSection()
        }
    }
}

/// Built-in MiMo-Auto provider settings (non-removable, free tier + paid API key).
struct MiMoAutoSection: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var store = MiMoAutoProviderStore.shared
    @State private var apiKeyInput: String = ""
    @State private var showApiKey = false
    @State private var validating = false
    @State private var testResult: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(Color.mimo.brand)
                VStack(alignment: .leading, spacing: 2) {
                    Text("MiMo Auto")
                        .interfaceFont(size: 18, weight: .semibold)
                        .foregroundColor(Color.mimo.textPrimary)
                    Text("Xiaomi MiMo Auto • free channel ended; API key supported")
                        .interfaceFont(size: 12)
                        .foregroundColor(Color.mimo.textSecondary)
                }
                Spacer()
                Text("API")
                    .interfaceFont(size: 10, weight: .bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.mimo.success.opacity(0.2))
                    .foregroundColor(Color.mimo.success)
                    .clipShape(Capsule())
            }

            // Model selector
            if !store.provider.models.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Model")
                        .interfaceFont(size: 12, weight: .medium)
                        .foregroundColor(Color.mimo.textPrimary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.provider.models) { model in
                                let selected = isSelected(model.id)
                                Button {
                                    store.selectModel(model.id)
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(model.name)
                                        if model.isFree {
                                            Image(systemName: "gift.fill")
                                                .font(.system(size: 8))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .interfaceFont(size: 11)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selected ? Color.mimo.brand.opacity(0.2) : Color.mimo.surface)
                                .foregroundColor(selected ? Color.mimo.brand : Color.mimo.textSecondary)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(selected ? Color.mimo.brand : Color.mimo.border, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
            }

            // API key section for paid tier
            VStack(alignment: .leading, spacing: 6) {
                Button(action: { showApiKey.toggle() }) {
                    HStack {
                        Image(systemName: showApiKey ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10))
                        Text("API Key (optional, official paid API)")

                            .interfaceFont(size: 12, weight: .medium)
                    }
                    .foregroundColor(Color.mimo.textSecondary)
                }
                .buttonStyle(.plain)

                if showApiKey {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if showApiKey {
                                TextField("sk-...", text: $apiKeyInput)
                                    .zcodeTextFieldStyle()
                                    .interfaceFont(size: 12)
                            } else {
                                SecureField("sk-...", text: $apiKeyInput)
                                    .zcodeTextFieldStyle()
                                    .interfaceFont(size: 12)
                            }
                            Button("Save") {
                                store.setApiKey(apiKeyInput)
                            }
                            .buttonStyle(.plain)
                            .interfaceFont(size: 12)
                            .foregroundColor(Color.mimo.brand)
                            .disabled(validating)
                        }
                        if let result = testResult {
                            Text(result)
                                .interfaceFont(size: 11)
                                .foregroundColor(result.contains("valid") ? Color.mimo.success : Color.mimo.error)
                        }
                        Text("The anonymous free MiMo Auto channel ended on 26 Jul 2026. Add a Xiaomi API key to use the official paid API.")
                            .interfaceFont(size: 10)
                            .foregroundColor(Color.mimo.textMuted)
                    }
                }
            }

            // Status
            HStack(spacing: 6) {
                Circle()
                    .fill(store.provider.isKeyValid ? Color.mimo.success : Color.mimo.error)
                    .frame(width: 6, height: 6)
                Text(store.provider.isKeyValid
                     ? (store.provider.isFreeTier ? "Free channel ready" : "API key valid")
                     : (store.provider.isFreeTier ? "Free channel ended" : "Invalid key"))
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
                Spacer()
                Button(action: { Task { await store.refreshModels() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(Color.mimo.brand)
            }
        }
        .padding(16)
        .background(Color.mimo.surface)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            apiKeyInput = store.provider.apiKey
        }
    }

    private func isSelected(_ modelID: String) -> Bool {
        appState.selectedModel == modelID || (appState.selectedModel.isEmpty && store.provider.selectedModel == modelID)
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
            Text(L.t(AppLocalizationKey.locLocalProviders))
                .interfaceFont(size: 18, weight: .semibold)
                .foregroundColor(Color.mimo.textPrimary)
            Text(L.t(AppLocalizationKey.locRunModelsLocallyViaOllamaOpencodeMicoderCliserv))
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
                        Text(detecting ? L.t(AppLocalizationKey.locDetecting) : L.t(AppLocalizationKey.locAutoDetect))
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
                primaryButton: .default(Text(L.t(AppLocalizationKey.locConfirmAndAdd))) {
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
                Text(isAdded ? L.t(AppLocalizationKey.locAdded) : L.t(AppLocalizationKey.locAdd))
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

    @State private var refreshing = false
    @State private var models: [String] = []
    @State private var showModelPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: config.kind.icon)
                    .interfaceFont(size: 14)
                    .foregroundColor(Color.mimo.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.displayName)
                        .interfaceFont(size: 13, weight: .medium)
                        .foregroundColor(Color.mimo.textPrimary)
                    Text(config.serveBaseURL)
                        .interfaceFont(size: 11)
                        .foregroundColor(Color.mimo.textMuted)
                }
                Spacer()
                Button(action: { Task { await refreshModels() } }) {
                    HStack(spacing: 3) {
                        if refreshing { ProgressView().controlSize(.small) }
                        Image(systemName: "arrow.clockwise")
                        Text("\(models.count)")
                    }
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.brand)
                }
                .buttonStyle(.plain)
                .disabled(refreshing)
                Button(action: onToggle) {
                    Text(config.isEnabled ? L.t(AppLocalizationKey.locEnabled) : L.t(AppLocalizationKey.locDisabled))
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
            if !models.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(models, id: \.self) { model in
                            Button(action: { selectModel(model) }) {
                                Text(model)
                                    .interfaceFont(size: 10)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(isSelected(model) ? Color.mimo.brand.opacity(0.2) : Color.mimo.surface)
                                    .foregroundColor(isSelected(model) ? Color.mimo.brand : Color.mimo.textSecondary)
                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(isSelected(model) ? Color.mimo.brand : Color.mimo.border, lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear { models = config.models }
    }

    private func isSelected(_ model: String) -> Bool {
        config.models.contains(model)
    }

    private func selectModel(_ model: String) {
        // Model selection handled by parent via selectedModel in AppState
    }

    private func refreshModels() async {
        refreshing = true
        if let fetched = await LocalProviderLogic.fetchModels(for: config) {
            await MainActor.run {
                models = fetched
                // Persist fetched models back to config
                var updatedLocal = config
                updatedLocal.models = fetched
                var locals = LocalProviderLogic.load()
                if let idx = locals.firstIndex(where: { $0.id == config.id }) {
                    locals[idx] = updatedLocal
                    LocalProviderLogic.save(locals)
                }
            }
        }
        refreshing = false
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
            Text(L.t(AppLocalizationKey.locProviders))
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)
            
            Text(L.t(AppLocalizationKey.locManageCustomModelProvidersAndViewServerconnecte))
                .interfaceFont(size: 14)
                .foregroundColor(Color.mimo.textSecondary)
            
            // Stats chips
            HStack(spacing: 16) {
                ProviderCountChip(title: L.t(AppLocalizationKey.locProviders), count: providerCount)
                ProviderCountChip(title: L.t(AppLocalizationKey.locModels), count: modelCount)
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
            TextField(L.t(AppLocalizationKey.locSearchProviders), text: $providerFilter)
                .zcodeTextFieldStyle()
                .interfaceFont(size: 13)
            
            Button(action: { showAddProvider = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text(L.t(AppLocalizationKey.locAdd))
                }
                .interfaceFont(size: 13)
                .foregroundColor(Color.mimo.brand)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var providersList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.t(AppLocalizationKey.locProviders))
                .interfaceFont(size: 16, weight: .semibold)
                .foregroundColor(Color.mimo.textPrimary)
            
            if filteredProviders.isEmpty {
                Text(L.t(AppLocalizationKey.locProvidersConfigured))
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
            Image(systemName: title == L.t(AppLocalizationKey.locProviders) ? "server.rack" : "cpu")
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
                .help(L.t(AppLocalizationKey.locRemoveProvider))
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
                    ParameterRow(label: L.t(AppLocalizationKey.locParamContext), value: "\(meta.limit?.context.map { "\($0/1000)k" } ?? "—")")
                    ParameterRow(label: L.t(AppLocalizationKey.locParamOutput), value: "\(meta.limit?.output.map { "\($0)" } ?? "—")")
                    ParameterRow(label: L.t(AppLocalizationKey.locParamReasoning), value: meta.capabilities?.reasoning == true ? L.t(AppLocalizationKey.locYes) : L.t(AppLocalizationKey.locNo))
                    ParameterRow(label: L.t(AppLocalizationKey.locParamTools), value: meta.capabilities?.toolcall != false ? L.t(AppLocalizationKey.locYes) : L.t(AppLocalizationKey.locNo))
                    ParameterRow(label: L.t(AppLocalizationKey.locParamPlan), value: meta.capabilities?.plan == true ? L.t(AppLocalizationKey.locYes) : L.t(AppLocalizationKey.locNo))

                    if let cost = meta.cost {
                        ParameterRow(label: L.t(AppLocalizationKey.locParamCost), value: "\(cost.input ?? 0)/\(cost.output ?? 0) \(L.t(AppLocalizationKey.locPer1KTokens))")
                    }

                    if let variants = meta.variants, !variants.isEmpty {
                        ParameterRow(label: L.t(AppLocalizationKey.locParamVariants), value: variants.keys.sorted().joined(separator: ", "))
                    }
                }
                .interfaceFont(size: 11)
            } else {
                Text(L.t(AppLocalizationKey.locParametersAvailable))
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
                    Text(L.t(AppLocalizationKey.locModelDetails))
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
                    Text(L.t(AppLocalizationKey.locConfiguration))
                        .interfaceFont(size: 11, weight: .semibold)
                        .foregroundColor(Color.mimo.textSecondary)
                    
                    ParameterDetailRow(label: "ID", value: meta.id)
                    ParameterDetailRow(label: L.t(AppLocalizationKey.locName), value: meta.name ?? "—")
                    ParameterDetailRow(label: L.t(AppLocalizationKey.locParamProvider), value: meta.providerID ?? providerID)

                    if let context = meta.limit?.context {
                        ParameterDetailRow(label: L.t(AppLocalizationKey.locParamContextLength), value: "\(context)")
                    }

                    if let capabilities = meta.capabilities {
                        ParameterDetailRow(label: L.t(AppLocalizationKey.locParamReasoning), value: capabilities.reasoning == true ? L.t(AppLocalizationKey.locSupported) : L.t(AppLocalizationKey.locNotSupported))
                        ParameterDetailRow(label: L.t(AppLocalizationKey.locParamTools), value: capabilities.toolcall != false ? L.t(AppLocalizationKey.locSupported) : L.t(AppLocalizationKey.locNotSupported))
                        ParameterDetailRow(label: L.t(AppLocalizationKey.locParamPlanMode), value: capabilities.plan == true ? L.t(AppLocalizationKey.locSupported) : L.t(AppLocalizationKey.locNotSupported))
                    }

                    if let variants = meta.variants, !variants.isEmpty {
                        ParameterDetailRow(label: L.t(AppLocalizationKey.locParamVariants), value: variants.keys.sorted().joined(separator: ", "))
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
