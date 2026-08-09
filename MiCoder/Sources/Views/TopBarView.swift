import SwiftUI

struct TopBarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 12) {
            // Project name
            if let project = appState.selectedProject {
                Image(systemName: "folder")
                    .interfaceFont(size: 14)
                    .foregroundColor(Color.mimo.textMuted)
                
                Text(project.name)
                    .interfaceFont(size: 13, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                
                // Branch indicator
                HStack(spacing: 4) {
                    Image(systemName: "command")
                        .interfaceFont(size: 10)
                    Text(appState.gitBranch)
                        .interfaceFont(size: 11, design: .monospaced)
                }
                .foregroundColor(Color.mimo.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.mimo.surfaceHover)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Text(L.t(AppLocalizationKey.locMicoder))
                    .interfaceFont(size: 13, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                    .tracking(0.5)
            }
            
            // Session goal badge (plan Раздел 5 Блок 1 п.9), set via /goal.
            if let goal = appState.currentSessionGoal,
               let badge = SessionGoalLogic.badgeLabel(for: SessionGoal(text: goal)) {
                Text(badge)
                    .interfaceFont(size: 11, weight: .medium)
                    .foregroundColor(Color.mimo.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.mimo.brand.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .help(goal)
            }

            Spacer()
            
            // Action buttons
            TopBarButton(
                icon: "flag",
                label: L.t(AppLocalizationKey.locGoal),
                isActive: appState.showGoal,
                action: { appState.showGoal.toggle() }
            )
            
            TopBarButton(
                icon: "terminal",
                label: L.t(AppLocalizationKey.locTerminal),
                isActive: appState.showTerminal,
                action: { appState.showTerminal.toggle() }
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.mimo.surface)
    }
}

struct TopBarButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .interfaceFont(size: 14)
                
                Text(label)
                    .interfaceFont(size: 12, weight: isActive ? .semibold : .regular)
            }
            .foregroundColor(isActive ? Color.mimo.brand : Color.mimo.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isActive ? Color.mimo.brand.opacity(0.2) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isActive ? Color.mimo.brand.opacity(0.5) : Color.mimo.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
