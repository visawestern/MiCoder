import SwiftUI

enum TaskHeaderVisibility {
    static func shouldShow(selectedSession: ChatSession?) -> Bool {
        selectedSession != nil
    }
}

struct TopBarView: View {
    @EnvironmentObject var appState: AppState
    @State private var chatCopied = false

    var body: some View {
        HStack(spacing: 12) {
            // Sidebar toggle — always visible
            Button(action: { withAnimation { appState.sidebarVisible.toggle() } }) {
                Image(systemName: "sidebar.left")
                    .interfaceFont(size: 14)
                    .foregroundColor(appState.sidebarVisible ? Color.mimo.brand : Color.mimo.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Workspaces")

            // Session title — only when session is selected
            if let session = appState.selectedSession {
                Text(session.title)
                    .interfaceFont(size: 14, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                    .lineLimit(1)
            }

            // Workspace folder badge — only when workspace is selected
            if let workspace = appState.selectedWorkspace {
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .interfaceFont(size: 10)
                    Text(workspace.name)
                        .interfaceFont(size: 11, weight: .medium)
                }
                .foregroundColor(Color.mimo.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.mimo.surfaceHover)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Branch badge — when project is selected
            if ProjectHeaderContextLogic.shouldShowBranch(
                selectedWorkspace: appState.selectedWorkspace != nil,
                selectedLegacyProject: appState.selectedProject != nil
            ) {
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
                // Fallback "MiCoder" text when no project is open
                Text(L.t(AppLocalizationKey.locMicoder))
                    .interfaceFont(size: 13, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                    .tracking(0.5)
            }

            // Session goal badge (set via /goal)
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

            if let notice = appState.shellActionNotice {
                HStack(spacing: 4) {
                    Image(systemName: appState.shellActionNoticeTone == .error
                          ? "exclamationmark.triangle"
                          : appState.shellActionNoticeTone == .warning
                            ? "minus.circle"
                            : "checkmark.circle")
                        .interfaceFont(size: 10)
                    Text(notice)
                        .interfaceFont(size: 11)
                        .lineLimit(1)
                }
                .foregroundColor(
                    appState.shellActionNoticeTone == .error
                        ? Color.mimo.error
                        : appState.shellActionNoticeTone == .warning
                            ? Color.mimo.warning
                            : Color.mimo.success
                )
                .transition(.opacity)
            }

            Spacer()

            // Copy entire chat — only when session is selected
            if appState.selectedSession != nil {
                Button(action: copyEntireChat) {
                    Image(systemName: chatCopied ? "checkmark" : "doc.on.doc")
                        .interfaceFont(size: 14)
                        .foregroundColor(chatCopied ? Color.mimo.success : Color.mimo.textSecondary)
                }
                .buttonStyle(.plain)
                .help(chatCopied ? L.t(AppLocalizationKey.locCopied) : L.t(AppLocalizationKey.locCopyChat))
            }

            // Action buttons — always visible
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
        .onReceive(NotificationCenter.default.publisher(for: .copyEntireChatCompleted)) { _ in
            withAnimation { chatCopied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { chatCopied = false }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .copyEntireChatUnavailable)) { _ in
            withAnimation { chatCopied = false }
        }
    }

    private func copyEntireChat() {
        NotificationCenter.default.post(name: .copyEntireChat, object: nil)
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

struct ChatPanelCompactHeader: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { withAnimation { appState.sidebarVisible.toggle() } }) {
                Image(systemName: "sidebar.left")
                    .interfaceFont(size: 14)
                    .foregroundColor(appState.sidebarVisible ? Color.mimo.brand : Color.mimo.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Workspaces")

            Spacer()

            Button(action: { appState.showGoal.toggle() }) {
                Image(systemName: "sidebar.right")
                    .interfaceFont(size: 14)
                    .foregroundColor(appState.showGoal ? Color.mimo.brand : Color.mimo.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Git tools & progress")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.mimo.backgroundAlt)
        .overlay(
            Rectangle()
                .fill(Color.mimo.border)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}
