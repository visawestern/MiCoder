import SwiftUI
import AppKit

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            sidebarNavigationRow
            
            VStack(alignment: .leading, spacing: 2) {
                SidebarActionRow(icon: SidebarLayout.newTaskIcon, label: L.t("New task"), shortcut: "⌘N") {
                    appState.startNewTask(in: appState.selectedWorkspace)
                }
                SidebarActionRow(icon: "folder.badge.plus", label: L.t("New Project"), shortcut: "⌘⇧P") {
                    appState.showProjectCreation = true
                }
                SidebarActionRow(icon: "folder", label: L.t("Open Project…"), shortcut: "⌘O") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    panel.prompt = "Open"
                    panel.message = "Select a folder to open as a project"
                    if panel.runModal() == .OK, let url = panel.url {
                        appState.addWorkspace(path: url.path)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            
            Divider()
                .padding(.horizontal, 12)
            
            WorkspacesSectionHeader()
                .padding(.horizontal, 10)
                .padding(.top, 8)
            
            if appState.showWorkspaceSearchField {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .interfaceFont(size: 11)
                        .foregroundColor(Color.mimo.textMuted)
                    TextField(L.t("Filter workspaces"), text: $appState.workspaceFilterQuery)
                        .zcodeTextFieldStyle()
                        .interfaceFont(size: 12)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if appState.workspacesSectionExpanded {
                        if appState.workspaceViewMode == .grid {
                            WorkspaceGridView(workspaces: appState.displayedWorkspaces)
                                .padding(.horizontal, 10)
                                .padding(.top, 4)
                        } else {
                            ForEach(appState.displayedWorkspaces) { workspace in
                                // Only the active project starts expanded; others
                                // start collapsed (plan Раздел 13 п.6).
                                WorkspaceSidebarSection(
                                    workspace: workspace,
                                    startsExpanded: appState.selectedWorkspace?.id == workspace.id
                                )
                            }
                        }
                        
                        if appState.displayedWorkspaces.isEmpty {
                            Text(appState.workspaces.isEmpty ? L.t("No workspaces") : "No matching workspaces")
                                .interfaceFont(size: 12)
                                .foregroundColor(Color.mimo.textMuted)
                                .padding(.horizontal, 14)
                                .padding(.top, 8)
                        }
                    }
                }
            }
            
            SidebarFooterView()
        }
        .background(Color.mimo.backgroundAlt)
        .sheet(isPresented: $appState.showNotifications) {
            NotificationsSheet()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showWorkspacesOverview) {
            WorkspacesOverviewSheet()
                .environmentObject(appState)
        }
    }
    
    private var sidebarNavigationRow: some View {
        HStack(spacing: 8) {
            Button(action: { appState.navigateBack() }) {
                Image(systemName: "chevron.left")
                    .interfaceFont(size: 12, weight: .medium)
                    .foregroundColor(appState.canNavigateBack ? Color.mimo.textSecondary : Color.mimo.textMuted.opacity(0.4))
            }
            .buttonStyle(.plain)
            .disabled(!appState.canNavigateBack)
            
            Button(action: { appState.navigateForward() }) {
                Image(systemName: "chevron.right")
                    .interfaceFont(size: 12, weight: .medium)
                    .foregroundColor(appState.canNavigateForward ? Color.mimo.textSecondary : Color.mimo.textMuted.opacity(0.4))
            }
            .buttonStyle(.plain)
            .disabled(!appState.canNavigateForward)
            
            Spacer()
            
            Button(action: { withAnimation { appState.sidebarVisible.toggle() } }) {
                Image(systemName: "sidebar.left")
                    .interfaceFont(size: 13)
                    .foregroundColor(Color.mimo.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

struct WorkspacesSectionHeader: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 6) {
            // Group / Project pill (plan Раздел 11 Блок 2 п.11). No "Workspaces"
            // title — the sidebar mirrors the reference (plan Раздел 13 п.7).
            SidebarGroupingPill(mode: $appState.sidebarGroupingMode)

            Button(action: { withAnimation { appState.workspacesSectionExpanded.toggle() } }) {
                Image(systemName: appState.workspacesSectionExpanded ? "chevron.down" : "chevron.right")
                    .interfaceFont(size: 9)
                    .foregroundColor(Color.mimo.textMuted)
            }
            .buttonStyle(.plain)
            
            Button(action: { appState.showWorkspacesOverview = true }) {
                Image(systemName: SidebarLayout.workspacesExpandIcon)
                    .interfaceFont(size: 10)
                    .foregroundColor(Color.mimo.textMuted)
            }
            .buttonStyle(.plain)
            .help("All workspaces")
            
            Spacer()

            // Archive quick-access (plan Раздел 11 Блок 2 п.16).
            Button(action: { appState.showArchivePopover.toggle() }) {
                Image(systemName: "archivebox")
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
            }
            .buttonStyle(.plain)
            .help("Archived projects")
            .popover(isPresented: $appState.showArchivePopover) {
                ArchivedProjectsPopover().environmentObject(appState)
            }
            
            Menu {
                ForEach(WorkspaceSortOrder.allCases) { order in
                    Button(action: { appState.workspaceSortOrder = order }) {
                        HStack {
                            Text(order.rawValue)
                            if appState.workspaceSortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: SidebarLayout.workspacesFilterIcon)
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Sort workspaces")
            
            Menu {
                ForEach(WorkspaceFilterPreset.allCases, id: \.self) { preset in
                    Button(action: { appState.workspaceFilterPreset = preset }) {
                        HStack {
                            Text(preset.rawValue)
                            if appState.workspaceFilterPreset == preset {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: appState.workspaceFilterPreset == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    .interfaceFont(size: 11)
                    .foregroundColor(appState.workspaceFilterPreset != .all ? Color.mimo.brand : Color.mimo.textMuted)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Filter: \(appState.workspaceFilterPreset.rawValue)")
            
            Button(action: {
                withAnimation {
                    appState.showWorkspaceSearchField.toggle()
                    if !appState.showWorkspaceSearchField {
                        appState.workspaceFilterQuery = ""
                    }
                }
            }) {
                Image(systemName: SidebarLayout.workspacesSearchIcon)
                    .interfaceFont(size: 11)
                    .foregroundColor(appState.showWorkspaceSearchField ? Color.mimo.brand : Color.mimo.textMuted)
            }
            .buttonStyle(.plain)
            .help("Filter workspaces")
            
            Button(action: {
                withAnimation {
                    appState.workspaceViewMode = appState.workspaceViewMode == .list ? .grid : .list
                }
            }) {
                Image(systemName: appState.workspaceViewMode == .list ? SidebarLayout.workspacesViewGridIcon : SidebarLayout.workspacesViewListIcon)
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
            }
            .buttonStyle(.plain)
            .help("Toggle list/grid view")
        }
        .padding(.bottom, 6)
    }
}

struct WorkspaceGridView: View {
    let workspaces: [Workspace]
    @EnvironmentObject var appState: AppState
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(workspaces) { workspace in
                Button(action: { appState.selectedWorkspace = workspace }) {
                    VStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                            .interfaceFont(size: 18)
                            .foregroundColor(appState.selectedWorkspace?.id == workspace.id ? Color.mimo.brand : Color.mimo.textMuted)
                        Text(workspace.name)
                            .interfaceFont(size: 11, weight: .medium)
                            .foregroundColor(Color.mimo.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .padding(8)
                    .background(appState.selectedWorkspace?.id == workspace.id ? Color.mimo.surfaceHover : Color.mimo.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct SidebarFooterView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.9), Color.orange.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                Text(appState.userInitials)
                    .interfaceFont(size: 11, weight: .semibold)
                    .foregroundColor(.white)
            }
            
            Text(appState.userDisplayName)
                .interfaceFont(size: 12, weight: .medium)
                .foregroundColor(Color.mimo.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            Button(action: { appState.showNotifications = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .interfaceFont(size: 14)
                        .foregroundColor(Color.mimo.textSecondary)
                    
                    if appState.notificationService.unreadCount > 0 {
                        Text("\(appState.notificationService.unreadCount)")
                            .interfaceFont(size: 9, weight: .bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.mimo.error)
                            .clipShape(Capsule())
                            .offset(x: 6, y: -6)
                    }
                }
            }
            .buttonStyle(.plain)
            .help("Notifications (\(appState.notificationService.unreadCount) unread)")
            
            Button(action: { appState.openSettings() }) {
                Image(systemName: "gearshape")
                    .interfaceFont(size: 14)
                    .foregroundColor(Color.mimo.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.mimo.backgroundAlt)
        .overlay(
            Rectangle()
                .fill(Color.mimo.border)
                .frame(height: 1),
            alignment: .top
        )
    }
}

struct NotificationsSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Notifications")
                    .interfaceFont(size: 18, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Spacer()
                if appState.notificationService.unreadCount > 0 {
                    Button("Mark All Read") {
                        appState.notificationService.markAllAsRead()
                    }
                    .buttonStyle(.plain)
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.brand)
                }
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.mimo.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            Divider()
                .padding(.horizontal, 12)
            
            if appState.notificationService.notifications.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "bell.slash")
                        .interfaceFont(size: 32)
                        .foregroundColor(Color.mimo.textMuted.opacity(0.5))
                    Text("No notifications")
                        .interfaceFont(size: 14)
                        .foregroundColor(Color.mimo.textSecondary)
                    Text("Task completions and system alerts will appear here.")
                        .interfaceFont(size: 12)
                        .foregroundColor(Color.mimo.textMuted)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(appState.notificationService.sortedNotifications) { notification in
                            NotificationRow(notification: notification)
                                .environmentObject(appState)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 380, height: 400)
        .background(Color.mimo.background)
    }
}

struct NotificationRow: View {
    @EnvironmentObject var appState: AppState
    let notification: AppNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: notification.type.icon)
                .interfaceFont(size: 14)
                .foregroundColor(iconColor)
                .frame(width: 18)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(notification.title)
                        .interfaceFont(size: 12, weight: .semibold)
                        .foregroundColor(Color.mimo.textPrimary)
                    Spacer()
                    if !notification.isRead {
                        Circle()
                            .fill(Color.mimo.brand)
                            .frame(width: 7, height: 7)
                    }
                    Text(timeAgo(notification.timestamp))
                        .interfaceFont(size: 10)
                        .foregroundColor(Color.mimo.textMuted)
                }
                Text(notification.message)
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textSecondary)
                    .lineLimit(2)
                
                if let action = notification.action {
                    Button(action: { handleAction(action) }) {
                        Text(actionLabel(action))
                            .interfaceFont(size: 11, weight: .medium)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color.mimo.brand)
                    .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            appState.notificationService.markAsRead(notification.id)
        }
        .background(
            notification.isRead
                ? Color.clear
                : Color.mimo.brand.opacity(0.04)
        )
        
        Divider()
            .padding(.leading, 42)
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .info: return Color.mimo.brand
        case .success: return Color.mimo.success
        case .warning: return Color.mimo.warning
        case .error: return Color.mimo.error
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
    
    private func actionLabel(_ action: NotificationAction) -> String {
        switch action {
        case .openSession: return "Open Session"
        case .openSettings: return "Open Settings"
        case .openGit: return "View Changes"
        case .custom(let id): return id
        }
    }
    
    private func handleAction(_ action: NotificationAction) {
        switch action {
        case .openSession(let sessionID):
            if let session = appState.sessions.first(where: { $0.id == sessionID }) {
                appState.selectSession(session)
            }
        case .openSettings:
            appState.openSettings()
        case .openGit:
            appState.showGoal = true
        case .custom:
            break
        }
    }
}

struct WorkspacesOverviewSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    
    private var filtered: [Workspace] {
        SidebarWorkspaceLogic.filtered(appState.workspaces, query: query)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Overview")
                    .interfaceFont(size: 18, weight: .semibold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.mimo.textMuted)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.mimo.textMuted)
                TextField("Search workspaces", text: $query)
                    .zcodeTextFieldStyle()
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(filtered) { workspace in
                        Button(action: {
                            appState.selectedWorkspace = workspace
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(Color.mimo.textMuted)
                                Text(workspace.name)
                                    .foregroundColor(Color.mimo.textPrimary)
                                Spacer()
                                if appState.selectedWorkspace?.id == workspace.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.mimo.brand)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(24)
        .frame(width: 420, height: 420)
        .background(Color.mimo.background)
    }
}

struct SidebarActionRow: View {
    let icon: String
    let label: String
    var shortcut: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .interfaceFont(size: 13)
                    .frame(width: 18)
                    .foregroundColor(Color.mimo.textSecondary)
                Text(label)
                    .interfaceFont(size: 13)
                    .foregroundColor(Color.mimo.textPrimary)
                Spacer()
                if let shortcut {
                    Text(shortcut)
                        .interfaceFont(size: 11)
                        .foregroundColor(Color.mimo.textMuted)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct WorkspaceSidebarSection: View {
    let workspace: Workspace
    /// Whether this group should start expanded — only the active project is
    /// expanded by default; other groups start collapsed (plan Раздел 13 п.6).
    let startsExpanded: Bool
    @EnvironmentObject var appState: AppState
    @State private var isExpanded: Bool
    @State private var hoveredSessionID: String?

    init(workspace: Workspace, startsExpanded: Bool = false) {
        self.workspace = workspace
        self.startsExpanded = startsExpanded
        _isExpanded = State(initialValue: startsExpanded)
    }
    
    private static let groupColors: [Color] = [
        Color(red: 0.49, green: 0.23, blue: 0.93), // brand purple
        Color(red: 0.20, green: 0.82, blue: 0.72), // teal
        Color(red: 0.95, green: 0.55, blue: 0.25), // orange
        Color(red: 0.95, green: 0.35, blue: 0.55), // pink
        Color(red: 0.30, green: 0.60, blue: 0.95), // blue
        Color(red: 0.85, green: 0.65, blue: 0.13), // gold
        Color(red: 0.55, green: 0.35, blue: 0.85), // light purple
        Color(red: 0.35, green: 0.80, blue: 0.60), // green
    ]
    
    private var groupColor: Color {
        let index = abs(workspace.id.hashValue) % Self.groupColors.count
        return Self.groupColors[index]
    }
    
    private var workspaceSessions: [ChatSession] {
        appState.sessions(for: workspace)
    }
    
    private var activeSession: ChatSession? {
        workspaceSessions.first { $0.id == appState.selectedSession?.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Group Row
            HStack(spacing: 8) {
                // Colored circle avatar with #
                ZStack {
                    Circle()
                        .fill(groupColor.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Text("#")
                        .interfaceFont(size: 12, weight: .bold)
                        .foregroundColor(groupColor)
                }
                
                // Name + chevron
                Button(action: {
                    appState.selectedWorkspace = workspace
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                }) {
                    HStack(spacing: 4) {
                        Text(workspace.name)
                            .interfaceFont(size: 12, weight: .medium)
                            .foregroundColor(Color.mimo.textPrimary)
                            .lineLimit(1)
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .interfaceFont(size: 9)
                            .foregroundColor(Color.mimo.textMuted)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Spacer(minLength: 0)
                
                // Session count
                Text("\(workspaceSessions.count)")
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
                
                // Plus button
                Button(action: { appState.startNewTask(in: workspace) }) {
                    Image(systemName: "plus.circle")
                        .interfaceFont(size: 13)
                        .foregroundColor(Color.mimo.textMuted)
                }
                .buttonStyle(.plain)
                .help("New task")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            
            // Nested Sessions
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    if workspaceSessions.isEmpty {
                        Text("No tasks yet")
                            .interfaceFont(size: 11)
                            .foregroundColor(Color.mimo.textMuted)
                            .padding(.leading, 50)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(workspaceSessions.prefix(10)) { session in
                            SessionTaskRow(
                                session: session,
                                workspace: workspace,
                                groupColor: groupColor,
                                isHovered: hoveredSessionID == session.id
                            )
                            .onHover { hovering in
                                hoveredSessionID = hovering ? session.id : nil
                            }
                        }
                    }
                }
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

struct SessionTaskRow: View {
    let session: ChatSession
    let workspace: Workspace
    let groupColor: Color
    var isHovered: Bool = false
    @EnvironmentObject var appState: AppState
    
    var isSelected: Bool {
        appState.selectedSession?.id == session.id
    }
    
    private var timeBadge: String {
        let interval = Date().timeIntervalSince(session.updatedAt)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        return "\(Int(interval / 86400))d"
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Color indicator strip (only for selected)
            if isSelected {
                RoundedRectangle(cornerRadius: 1)
                    .fill(groupColor)
                    .frame(width: 2)
            } else {
                Color.clear
                    .frame(width: 2)
            }
            
            // Session content
            Button(action: { appState.selectSession(session) }) {
                HStack(spacing: 6) {
                    Text(session.title)
                        .interfaceFont(size: 12)
                        .foregroundColor(isSelected ? Color.mimo.textPrimary : Color.mimo.textSecondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if isSelected {
                        // "now" badge
                        Text("now")
                            .interfaceFont(size: 9, weight: .medium)
                            .foregroundColor(Color.mimo.textPrimary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.mimo.textPrimary.opacity(0.12))
                            .cornerRadius(4)
                    } else {
                        // Time badge
                        Text(timeBadge)
                            .interfaceFont(size: 10)
                            .foregroundColor(Color.mimo.textMuted)
                    }
                }
            }
            .buttonStyle(.plain)
            
            if isHovered {
                HStack(spacing: 4) {
                    Button(action: { appState.startNewTask(in: workspace) }) {
                        Image(systemName: "plus")
                            .interfaceFont(size: 10)
                            .foregroundColor(Color.mimo.textMuted)
                    }
                    .buttonStyle(.plain)
                    
                    Menu {
                        Button("Open in Finder") {
                            appState.openFolderInFinder(session.directory.isEmpty ? workspace.path : session.directory)
                        }
                        Button("New task") {
                            appState.startNewTask(in: workspace)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .interfaceFont(size: 10)
                            .foregroundColor(Color.mimo.textMuted)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
            }
        }
        .padding(.leading, 50)
        .padding(.trailing, 14)
        .padding(.vertical, 5)
        .background(
            isSelected
                ? Color.mimo.textPrimary.opacity(0.06)
                : Color.clear
        )
        .cornerRadius(6)
    }
}

struct SearchPaletteView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    
    private var matchingSessions: [ChatSession] {
        SearchPaletteLogic.matchingSessions(appState.sessions, query: query)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Search")
                    .interfaceFont(size: 20, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.mimo.textMuted)
                }
                .buttonStyle(.plain)
                .help("Close (Esc)")
            }

            TextField("Search tasks…", text: $query)
                .zcodeTextFieldStyle()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(matchingSessions) { session in
                        Button(action: {
                            appState.selectSession(session)
                            dismiss()
                        }) {
                            HStack {
                                Text(session.title)
                                    .interfaceFont(size: 13)
                                    .foregroundColor(Color.mimo.textPrimary)
                                Spacer()
                                Text(session.durationLabel)
                                    .interfaceFont(size: 11)
                                    .foregroundColor(Color.mimo.textMuted)
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("Esc to close")
                .interfaceFont(size: 11)
                .foregroundColor(Color.mimo.textMuted)
        }
        .padding(24)
        .frame(width: 480, height: 400)
        .background(Color.mimo.background)
        .onExitCommand {
            dismiss()
        }
    }
}

// MARK: - Group/Project pill (plan Раздел 11 Блок 2)

struct SidebarGroupingPill: View {
    @Binding var mode: SidebarGroupingMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SidebarGroupingMode.allCases) { m in
                Button(action: { withAnimation(.easeOut(duration: 0.15)) { mode = m } }) {
                    HStack(spacing: 3) {
                        Image(systemName: m.icon)
                            .interfaceFont(size: 9)
                        Text(m.label)
                            .interfaceFont(size: 10, weight: .medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundColor(mode == m ? Color.mimo.textPrimary : Color.mimo.textMuted)
                    .background(mode == m ? Color.mimo.surface : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color.mimo.backgroundAlt.opacity(0.6))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.mimo.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

// MARK: - Archived projects popover (plan Раздел 11 Блок 2 п.16 + Раздел 8)

struct ArchivedProjectsPopover: View {
    @EnvironmentObject var appState: AppState
    @State private var archived: [ProjectRegistryEntry] = ProjectRegistryLogic.archived(
        ProjectRegistryLogic.load(homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Archived projects")
                .interfaceFont(size: 13, weight: .semibold)
                .foregroundColor(Color.mimo.textPrimary)

            if archived.isEmpty {
                Text("No archived projects")
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textMuted)
            } else {
                ForEach(archived) { entry in
                    HStack(spacing: 8) {
                        Image(systemName: "archivebox")
                            .interfaceFont(size: 11)
                            .foregroundColor(Color.mimo.textMuted)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(entry.name)
                                .interfaceFont(size: 12, weight: .medium)
                                .foregroundColor(Color.mimo.textPrimary)
                            Text(entry.path)
                                .interfaceFont(size: 10)
                                .foregroundColor(Color.mimo.textMuted)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button("Restore") { restore(entry) }
                            .interfaceFont(size: 11)
                            .buttonStyle(.plain)
                            .foregroundColor(Color.mimo.brand)
                    }
                }
            }

            Divider()
            Button(action: {
                appState.showArchivePopover = false
                appState.showSettings = true
                appState.settingsTab = .storage
            }) {
                Text("Open full storage panel")
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.brand)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 320)
    }

    private func restore(_ entry: ProjectRegistryEntry) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let all = ProjectRegistryLogic.load(homeDirectory: home)
        let updated = ProjectRegistryLogic.restore(id: entry.id, in: all)
        try? ProjectRegistryLogic.save(updated, homeDirectory: home)
        archived = ProjectRegistryLogic.archived(updated)
    }
}
