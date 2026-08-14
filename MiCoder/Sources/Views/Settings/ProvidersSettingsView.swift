import SwiftUI

struct UnifiedProvidersView: View {
    @EnvironmentObject var appState: AppState
    let availableWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            MiCoderAutoFreeSection()
            Divider().background(Color.mimo.border)
            ModelSettingsView(availableWidth: availableWidth)
            Divider().background(Color.mimo.border)
            LocalProvidersSection()
            Divider().background(Color.mimo.border)
            WebProvidersSection()
        }
    }
}

/// Built-in OpenCode Zen provider settings (non-removable, free while Big Pickle is available).
struct MiCoderAutoFreeSection: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var store = MiCoderAutoFreeStore.shared
    @State private var systemPromptInput: String = ""
    @State private var isRefreshing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            providerStatus
            protocolDetails
            modelCatalog
            lockPolicy
            systemPromptEditor
            privacyNote
        }
        .padding(16)
        .background(Color.mimo.surface)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            systemPromptInput = store.provider.systemPrompt
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(Color.mimo.brand)
            VStack(alignment: .leading, spacing: 3) {
                Text("MiCoder Auto Free")
                    .interfaceFont(size: 18, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Text("OpenCode Zen · live anonymous free-model workspace")
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textSecondary)
            }
            Spacer()
            Text("FREE")
                .interfaceFont(size: 10, weight: .bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.mimo.success.opacity(0.2))
                .foregroundColor(Color.mimo.success)
                .clipShape(Capsule())
        }
    }

    private var providerStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(store.provider.isReady ? Color.mimo.success : Color.mimo.error)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.provider.isReady ? "ONLINE · \(store.provider.models.count) free models" : "OFFLINE · free catalog unavailable")
                    .interfaceFont(size: 12, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Text(store.provider.statusMessage.isEmpty ? "Loading live OpenCode catalog…" : store.provider.statusMessage)
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)
                    .lineLimit(2)
            }
            Spacer()
            if let refreshed = store.provider.lastCatalogRefresh {
                Text("Updated \(refreshed.formatted(date: .omitted, time: .shortened))")
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)
            }
            Button(action: refreshCatalog) {
                HStack(spacing: 5) {
                    if isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text(isRefreshing ? "Refreshing…" : "Refresh catalog")
                }
                .interfaceFont(size: 11, weight: .medium)
                .foregroundColor(Color.mimo.brand)
            }
            .buttonStyle(.plain)
            .disabled(isRefreshing)
        }
        .padding(10)
        .background(Color.mimo.background)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var protocolDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Provider parameters")
                .interfaceFont(size: 12, weight: .semibold)
                .foregroundColor(Color.mimo.textPrimary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
                parameter(title: "Endpoint", value: "opencode.ai/zen/v1")
                parameter(title: "Protocol", value: "OpenAI-compatible SSE")
                parameter(title: "Access", value: "Anonymous · no key")
                parameter(title: "Fallback", value: "Rate limit or 5 failures")
            }
        }
    }

    private func parameter(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .interfaceFont(size: 9, weight: .bold)
                .foregroundColor(Color.mimo.textMuted)
            Text(value)
                .interfaceFont(size: 11)
                .foregroundColor(Color.mimo.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var modelCatalog: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Live free models")
                    .interfaceFont(size: 12, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Spacer()
                Text("Choose from list")
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)
            }

            if store.provider.models.isEmpty {
                Text("No eligible free models are currently returned by OpenCode. Refresh the catalog or choose another provider.")
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
                    .padding(.vertical, 8)
            } else if let selected = store.provider.models.first(where: { isSelected($0.id) }) {
                HStack(spacing: 6) {
                    Menu {
                        ForEach(store.provider.models) { model in
                            Button {
                                selectModel(model.id)
                            } label: {
                                HStack(spacing: 7) {
                                    Image(systemName: isSelected(model.id) ? "checkmark.circle.fill" : "circle")
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(model.name)
                                        Text(model.id)
                                            .font(.system(size: 9, design: .monospaced))
                                    }
                                    Spacer()
                                    Text(status(for: model))
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: store.provider.isModelLocked ? "lock.fill" : "checkmark.circle.fill")
                                .foregroundColor(Color.mimo.brand)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(selected.name)
                                    .interfaceFont(size: 11, weight: .semibold)
                                    .foregroundColor(Color.mimo.textPrimary)
                                    .lineLimit(1)
                                Text(selected.id)
                                    .interfaceFont(size: 9, design: .monospaced)
                                    .foregroundColor(Color.mimo.textMuted)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 6)
                            Text(status(for: selected))
                                .interfaceFont(size: 9, weight: .medium)
                                .foregroundColor(Color.mimo.success)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .interfaceFont(size: 9, weight: .semibold)
                                .foregroundColor(Color.mimo.brand)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.mimo.brand.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.mimo.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                    .menuStyle(.borderlessButton)
                    .help("Switch free model")

                    Button(action: { toggleLock(for: selected.id) }) {
                        Image(systemName: store.provider.isModelLocked ? "lock.open" : "lock")
                            .interfaceFont(size: 11, weight: .medium)
                            .foregroundColor(Color.mimo.brand)
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(store.provider.isModelLocked ? "Unlock selected model" : "Lock selected model")
                }
            }
        }
    }

    private var lockPolicy: some View {
        HStack(spacing: 8) {
            Image(systemName: store.provider.isModelLocked ? "lock.fill" : "arrow.triangle.2.circlepath")
                .foregroundColor(store.provider.isModelLocked ? Color.mimo.brand : Color.mimo.textMuted)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.provider.isModelLocked ? "Model locked" : "Automatic fallback enabled")
                    .interfaceFont(size: 11, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Text(store.provider.isModelLocked
                     ? "The selected model will not be changed automatically. Unlock it to allow failover."
                     : "Rate limits and repeated failures can move the request to another live free model.")
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)
                    .lineLimit(2)
            }
            Spacer()
            Toggle("Lock selected model", isOn: Binding(
                get: { store.provider.isModelLocked },
                set: { store.setModelLocked($0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .padding(10)
        .background(Color.mimo.background)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var systemPromptEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("System prompt")
                .interfaceFont(size: 12, weight: .semibold)
                .foregroundColor(Color.mimo.textPrimary)
            TextEditor(text: $systemPromptInput)
                .font(.system(size: 12))
                .foregroundColor(Color.mimo.textPrimary)
                .frame(minHeight: 72, maxHeight: 120)
                .padding(6)
                .background(Color.mimo.background)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mimo.border, lineWidth: 1))
            HStack {
                Text("Sent before every free-model request.")
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)
                Spacer()
                Button("Save prompt") { store.setSystemPrompt(systemPromptInput) }
                    .buttonStyle(.plain)
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.brand)
            }
        }
    }

    private var privacyNote: some View {
        Text("Free models are temporary OpenCode routes. Availability, rate limits, model metadata and data-use terms can change. Do not send secrets.")
            .interfaceFont(size: 10)
            .foregroundColor(Color.mimo.textMuted)
    }

    private func refreshCatalog() {
        guard !isRefreshing else { return }
        isRefreshing = true
        Task {
            _ = await store.refreshModels()
            isRefreshing = false
        }
    }

    private func selectModel(_ modelID: String) {
        store.selectModel(modelID)
        if appState.selectedProviderID == MiCoderAutoFreeProvider.builtInID {
            appState.selectModel(modelID)
        }
    }

    private func toggleLock(for modelID: String) {
        if !isSelected(modelID) {
            selectModel(modelID)
        }
        store.setModelLocked(!store.provider.isModelLocked)
    }

    private func status(for model: MiCoderAutoFreeClient.Model) -> String {
        store.modelStatus(for: model.id)
    }

    private func isSelected(_ modelID: String) -> Bool {
        store.provider.selectedModel == modelID
    }
}

struct AutoFreeCompactModelRow: View {
    let model: MiCoderAutoFreeClient.Model
    let isSelected: Bool
    let isLocked: Bool
    let status: String
    let onSelect: () -> Void
    let onToggleLock: () -> Void

    private var statusColor: Color {
        let lower = status.lowercased()
        if lower.contains("rate") || lower.contains("failed") || lower.contains("unavailable") {
            return Color.mimo.error
        }
        return isSelected ? Color.mimo.brand : Color.mimo.textMuted
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isLocked ? "lock.fill" : (isSelected ? "checkmark.circle.fill" : "circle"))
                .interfaceFont(size: 12)
                .foregroundColor(isSelected ? Color.mimo.brand : Color.mimo.textMuted)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(model.name)
                    .interfaceFont(size: 11, weight: isSelected ? .semibold : .regular)
                    .foregroundColor(Color.mimo.textPrimary)
                    .lineLimit(1)
                Text(model.id)
                    .interfaceFont(size: 9, design: .monospaced)
                    .foregroundColor(Color.mimo.textMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            Text(status)
                .interfaceFont(size: 9, weight: .medium)
                .foregroundColor(statusColor)
                .lineLimit(1)
            if isSelected {
                Button(action: onToggleLock) {
                    Image(systemName: isLocked ? "lock.open" : "lock")
                        .interfaceFont(size: 10, weight: .medium)
                        .foregroundColor(Color.mimo.brand)
                        .frame(width: 24, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(isLocked ? "Unlock model" : "Lock selected model")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isSelected ? Color.mimo.subtleFill : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.mimo.brand.opacity(0.35) : Color.clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(model.name), \(status)")
    }
}

struct AutoFreeModelCard: View {
    let model: MiCoderAutoFreeClient.Model
    let isSelected: Bool
    let isLocked: Bool
    let status: String
    let onSelect: () -> Void
    let onToggleLock: () -> Void

    private var statusColor: Color {
        let lower = status.lowercased()
        if lower.contains("rate") || lower.contains("failed") || lower.contains("unavailable") {
            return Color.mimo.error
        }
        if isSelected { return Color.mimo.brand }
        return Color.mimo.textMuted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isLocked ? "lock.fill" : (isSelected ? "checkmark.circle.fill" : "circle"))
                    .foregroundColor(isSelected ? Color.mimo.brand : Color.mimo.textMuted)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.name)
                        .interfaceFont(size: 12, weight: .semibold)
                        .foregroundColor(Color.mimo.textPrimary)
                    Text(model.id)
                        .interfaceFont(size: 9, design: .monospaced)
                        .foregroundColor(Color.mimo.textMuted)
                        .lineLimit(1)
                }
                Spacer()
                Text(status)
                    .interfaceFont(size: 9, weight: .medium)
                    .foregroundColor(statusColor)
            }

            Text(model.effectiveDescription)
                .interfaceFont(size: 10)
                .foregroundColor(Color.mimo.textSecondary)
                .lineLimit(2)

            Text(model.profile.capabilityLine)
                .interfaceFont(size: 9, weight: .medium)
                .foregroundColor(Color.mimo.success)
                .lineLimit(1)

            HStack(spacing: 8) {
                Text("Context: \(model.contextDescription)")
                    .interfaceFont(size: 9)
                    .foregroundColor(Color.mimo.textMuted)
                Spacer()
                Button(action: onToggleLock) {
                    Image(systemName: isLocked ? "lock.open" : "lock")
                    Text(isLocked ? "Unlock" : "Lock")
                }
                .buttonStyle(.plain)
                .interfaceFont(size: 10, weight: .medium)
                .foregroundColor(isSelected ? Color.mimo.brand : Color.mimo.textMuted)
                .disabled(!isSelected)
            }
        }
        .padding(11)
        .background(isSelected ? Color.mimo.brand.opacity(0.10) : Color.mimo.background)
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(isLocked ? Color.mimo.brand : (isSelected ? Color.mimo.brand.opacity(0.65) : Color.mimo.border), lineWidth: isSelected ? 1.5 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .contentShape(RoundedRectangle(cornerRadius: 9))
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(model.name), \(status)")
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
                                         onToggle: { toggleLocal(cfg) },
                                         onSelect: { model in selectLocalModel(model, from: cfg) })
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

    private func selectLocalModel(_ model: String, from config: LocalProviderConfig) {
        let currentConfig = LocalProviderLogic.load().first(where: { $0.id == config.id }) ?? config
        guard currentConfig.models.contains(model) else { return }
        if appState.selectedProviderID != config.id {
            appState.selectProvider(config.id)
        }
        appState.selectModel(model)
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
    @EnvironmentObject var appState: AppState
    let config: LocalProviderConfig
    let onRemove: () -> Void
    let onToggle: () -> Void
    let onSelect: (String) -> Void

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
        LocalModelSelectionLogic.isSelected(
            model,
            selectedProviderID: config.id,
            activeProviderID: appState.selectedProviderID,
            selectedModel: appState.selectedModel
        )
    }

    private func selectModel(_ model: String) {
        guard LocalModelSelectionLogic.modelAfterTap(model, catalog: models, current: nil) == model else { return }
        onSelect(model)
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
