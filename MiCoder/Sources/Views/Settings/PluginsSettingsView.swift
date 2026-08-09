import SwiftUI

struct PluginsSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchQuery = ""
    @State private var plugins: [PluginEntry] = []

    private var filtered: [PluginEntry] {
        AgentResourcesLoader.filterEntries(plugins, query: searchQuery) { $0.name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(L.t(AppLocalizationKey.locPlugins))
                .interfaceFont(size: 24, weight: .bold)
                .foregroundColor(Color.mimo.textPrimary)

            Text(L.t(AppLocalizationKey.locEnableDisableInstalledPluginsPluginsBundleSkill))
                .interfaceFont(size: 14)
                .foregroundColor(Color.mimo.textSecondary)

            if !appState.supportsToolcallForSelection {
                Text(L.t(AppLocalizationKey.locToolsUnavailableForTheCurrentModelProvider))
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.warning)
            }

            TextField(L.t(AppLocalizationKey.locSearchPlugins), text: $searchQuery)
                .zcodeTextFieldStyle()

            if filtered.isEmpty {
                settingsEmptyState(L.t(AppLocalizationKey.locNoPluginsInstalled), subtitle: L.t(AppLocalizationKey.locPluginsLiveUnderMicoderplugins))
            } else {
                ForEach(filtered) { plugin in
                    HStack {
                        Text(plugin.name)
                            .interfaceFont(size: 13, weight: .medium)
                            .foregroundColor(Color.mimo.textPrimary)
                        Spacer()
                        Text(plugin.isEnabled ? L.t(AppLocalizationKey.locEnabled) : L.t(AppLocalizationKey.locDisabled))
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
