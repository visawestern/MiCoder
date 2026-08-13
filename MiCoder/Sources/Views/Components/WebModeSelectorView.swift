import SwiftUI

/// Inline mode selector for web providers — shows model pills, thinking levels,
/// and feature modes (Deep Research, Create Image, etc).
struct WebModeSelectorView: View {
    @Binding var config: WebProviderConfig
    @State private var selectedModel: String
    @State private var selectedThinking: String = "auto"
    @State private var selectedFeatureModes: Set<String> = []

    init(config: Binding<WebProviderConfig>) {
        self._config = config
        self._selectedModel = State(initialValue: config.wrappedValue.selectedModel)
        self._selectedThinking = State(initialValue: config.wrappedValue.effort.rawValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Model pills
            if !config.discoveredModels.isEmpty {
                modelSection
            }

            // Thinking/Effort selector
            if !config.discoveredEffortLevels.isEmpty {
                thinkingSection
            }

            // Feature modes (Deep Research, Create Image, etc.)
            if !config.discoveredFeatureModes.isEmpty {
                featureModesSection
            }
        }
        .onChange(of: selectedModel) { newValue in
            config.selectedModel = newValue
        }
        .onChange(of: selectedThinking) { newValue in
            if let effort = WebEffort(rawValue: newValue) {
                config.effort = effort
            }
        }
    }

    // MARK: - Model Section

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L.t(AppLocalizationKey.locModel))
                .interfaceFont(size: 11, weight: .medium)
                .foregroundColor(Color.mimo.textMuted)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(config.discoveredModels) { model in
                        ModelPill(
                            model: model,
                            isSelected: selectedModel == model.name,
                            action: { selectedModel = model.name }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Thinking Section

    private var thinkingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L.t(AppLocalizationKey.locThinkingMode))
                .interfaceFont(size: 11, weight: .medium)
                .foregroundColor(Color.mimo.textMuted)

            Picker("", selection: $selectedThinking) {
                ForEach(config.discoveredEffortLevels, id: \.self) { level in
                    Text(level.displayName).tag(level.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Feature Modes Section

    private var featureModesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L.t(AppLocalizationKey.locFeatureModes))
                .interfaceFont(size: 11, weight: .medium)
                .foregroundColor(Color.mimo.textMuted)

            // Feature modes as horizontal scrollable pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(config.discoveredFeatureModes) { mode in
                        FeatureModeToggle(
                            mode: mode,
                            isSelected: selectedFeatureModes.contains(mode.name),
                            action: {
                                if selectedFeatureModes.contains(mode.name) {
                                    selectedFeatureModes.remove(mode.name)
                                } else {
                                    selectedFeatureModes.insert(mode.name)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Model Pill

struct ModelPill: View {
    let model: WebProviderModel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.name)
                    .interfaceFont(size: 11, weight: .medium)
                if let desc = model.description, !desc.isEmpty {
                    Text(desc)
                        .interfaceFont(size: 9)
                        .foregroundColor(Color.mimo.textMuted)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.mimo.brand.opacity(0.15) : Color.mimo.surface)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.mimo.brand : Color.mimo.border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? Color.mimo.brand : Color.mimo.textPrimary)
    }
}

// MARK: - Feature Mode Toggle

struct FeatureModeToggle: View {
    let mode: FeatureMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = mode.icon {
                    Image(systemName: icon)
                        .interfaceFont(size: 10)
                }
                Text(mode.name)
                    .interfaceFont(size: 10)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.mimo.brand : Color.mimo.surface)
            .foregroundColor(isSelected ? .white : Color.mimo.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!mode.isEnabled)
        .opacity(mode.isEnabled ? 1.0 : 0.5)
    }
}


