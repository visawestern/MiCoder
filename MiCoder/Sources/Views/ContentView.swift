import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    /// Persisted, user-resizable sidebar width (plan Раздел 11 Блок 1).
    @AppStorage("sidebarWidth") private var sidebarWidth: Double = 260
    private let sidebarMinWidth: Double = 200
    private let sidebarMaxWidth: Double = 420
    private let sidebarDefaultWidth: Double = 260

    var body: some View {
        HStack(spacing: 0) {
            if appState.sidebarVisible {
                SidebarView()
                    .frame(width: sidebarWidth)

                SidebarResizeHandle(width: $sidebarWidth,
                                    minWidth: sidebarMinWidth,
                                    maxWidth: sidebarMaxWidth,
                                    defaultWidth: sidebarDefaultWidth)
            }

            VStack(spacing: 0) {
                TopBarView()
                
                if TaskHeaderVisibility.shouldShow(selectedSession: appState.selectedSession) {
                    TaskHeaderView()
                }
                
                ChatPanelView()
                
                if appState.showTerminal {
                    Rectangle()
                        .fill(Color.mimo.border)
                        .frame(height: 1)
                    
                    BottomPanelView()
                        .frame(height: 240)
                }
                
                StatusBarView(isStreaming: appState.isStreaming, isLoading: appState.isLoading)
                    .frame(height: 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if appState.showGoal {
                Rectangle()
                    .fill(Color.mimo.border)
                    .frame(width: 1)
                
                RightPanelView()
                    .frame(width: 300)
            }
        }
        .background(Color.mimo.background)
        .environment(\.interfaceFontScale, appState.settings.zoom.fontScale)
        .preferredColorScheme(appState.appTheme.preferredColorScheme)
        // RTL layout for Arabic (plan Раздел 2 Блок 2 п.15).
        .environment(\.layoutDirection, appState.appLanguage.isRTL ? .rightToLeft : .leftToRight)
        .task {
            appState.loadCustomProviders()
            await appState.connectToServer()
            async let sessions: () = appState.loadSessionsFromServer()
            async let models: () = appState.serverConnected ? appState.loadModelsFromServer() : ()
            await sessions
            await models
        }
        .overlay { settingsOverlay }
        .animation(.easeOut(duration: 0.15), value: appState.showSettings)
        .sheet(isPresented: $appState.showSearch) {
            SearchPaletteView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showRemoteConnection) {
            RemoteConnectionSheet()
                .environmentObject(appState)
        }
        .sheet(isPresented: $appState.showProjectCreation) {
            NewProjectSheet()
                .environmentObject(appState)
        }
    }

    /// Settings as a dismissable overlay instead of a modal sheet:
    /// clicking the dimmed backdrop (or pressing Escape) closes it.
    @ViewBuilder
    private var settingsOverlay: some View {
        if appState.showSettings {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { appState.showSettings = false }

                SettingsView()
                    .environmentObject(appState)
                    .frame(maxWidth: 960, maxHeight: 720)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mimo.border, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 30, x: 0, y: 10)
                    .padding(24)

                // Invisible button so Escape keeps closing settings,
                // matching the old sheet behavior.
                Button("") { appState.showSettings = false }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.plain)
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .accessibilityHidden(true)
            }
            .transition(.opacity)
        }
    }
}

/// Drag handle that resizes the sidebar between min/max bounds, persists the
/// chosen width, and resets to default on double-click. Replaces the static
/// 1pt divider in ContentView (plan Раздел 11 Блок 1).
struct SidebarResizeHandle: View {
    @Binding var width: Double
    let minWidth: Double
    let maxWidth: Double
    let defaultWidth: Double

    @State private var isHovering = false

    var body: some View {
        Rectangle()
            .fill(Color.mimo.border)
            .frame(width: isHovering ? 3 : 1)
            .contentShape(Rectangle().inset(by: -6))
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    NSCursor.resizeLeftRight.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        width = SidebarResizeLogic.applyDrag(current: width, translation: value.translation.width,
                                                             min: minWidth, max: maxWidth)
                    }
            )
            .onTapGesture(count: 2) {
                width = defaultWidth
            }
            .accessibilityLabel("Sidebar resizer")
            .accessibilityHint("Drag to resize the sidebar; double-click to reset.")
    }
}
