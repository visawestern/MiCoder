import SwiftUI

enum TaskHeaderVisibility {
    static func shouldShow(selectedSession: ChatSession?) -> Bool {
        selectedSession != nil
    }
    
    static func branchLabel(workspace: Workspace?) -> String {
        workspace?.branch ?? "main"
    }
}

struct TaskHeaderView: View {
    @EnvironmentObject var appState: AppState
    @State private var chatCopied = false
    
    var body: some View {
        HStack(spacing: 12) {
            TaskHeaderLeftSidebarToggleButton()

            if let session = appState.selectedSession {
                Text(session.title)
                    .interfaceFont(size: 14, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                    .lineLimit(1)
            }
            
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
            
            HStack(spacing: 4) {
                Image(systemName: RightPanelLayout.branchIcon)
                    .interfaceFont(size: 10)
                Text(TaskHeaderVisibility.branchLabel(workspace: appState.selectedWorkspace))
                    .interfaceFont(size: 11, design: .monospaced)
            }
            .foregroundColor(Color.mimo.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.mimo.surfaceHover)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Spacer()
            
            Button(action: copyEntireChat) {
                Image(systemName: chatCopied ? "checkmark" : "doc.on.doc")
                    .interfaceFont(size: 14)
                    .foregroundColor(chatCopied ? Color.mimo.success : Color.mimo.textSecondary)
            }
            .buttonStyle(.plain)
            .help(chatCopied ? "Copied" : "Copy entire chat")
            
            Button(action: { appState.showTerminal.toggle() }) {
                Image(systemName: "terminal")
                    .interfaceFont(size: 14)
                    .foregroundColor(appState.showTerminal ? Color.mimo.brand : Color.mimo.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Terminal")
            
            Button(action: { appState.showGoal.toggle() }) {
                Image(systemName: TaskHeaderLayout.rightSidebarIcon)
                    .interfaceFont(size: 14)
                    .foregroundColor(appState.showGoal ? Color.mimo.brand : Color.mimo.textSecondary)
            }
            .buttonStyle(.plain)
            .help(TaskHeaderLayout.rightSidebarHelp)
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

    private func copyEntireChat() {
        NotificationCenter.default.post(name: .copyEntireChat, object: nil)
        withAnimation { chatCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { chatCopied = false }
        }
    }
}

struct TaskHeaderLeftSidebarToggleButton: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button(action: { withAnimation { appState.sidebarVisible.toggle() } }) {
            Image(systemName: TaskHeaderLayout.leftSidebarIcon)
                .interfaceFont(size: 14)
                .foregroundColor(appState.sidebarVisible ? Color.mimo.brand : Color.mimo.textSecondary)
        }
        .buttonStyle(.plain)
        .help(TaskHeaderLayout.leftSidebarHelp)
    }
}

struct ChatPanelCompactHeader: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            TaskHeaderLeftSidebarToggleButton()
            Spacer()
            Button(action: { appState.showGoal.toggle() }) {
                Image(systemName: TaskHeaderLayout.rightSidebarIcon)
                    .interfaceFont(size: 14)
                    .foregroundColor(appState.showGoal ? Color.mimo.brand : Color.mimo.textSecondary)
            }
            .buttonStyle(.plain)
            .help(TaskHeaderLayout.rightSidebarHelp)
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
