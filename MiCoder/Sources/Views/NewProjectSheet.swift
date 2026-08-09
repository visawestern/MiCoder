import SwiftUI
import AppKit

struct NewProjectSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var projectName = ""
    @State private var projectPath = ""
    @State private var showFolderPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(L.t(AppLocalizationKey.locNewProject))
                    .interfaceFont(size: 18, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.mimo.textMuted)
                }
                .buttonStyle(.plain)
            }
            
            // Project name
            VStack(alignment: .leading, spacing: 6) {
                Text(L.t(AppLocalizationKey.locProjectName))
                    .interfaceFont(size: 12, weight: .medium)
                    .foregroundColor(Color.mimo.textSecondary)
                TextField(L.t(AppLocalizationKey.locMyProject), text: $projectName)
                    .zcodeTextFieldStyle()
                    .interfaceFont(size: 13)
            }
            
            // Folder picker
            VStack(alignment: .leading, spacing: 6) {
                Text(L.t(AppLocalizationKey.locFolder))
                    .interfaceFont(size: 12, weight: .medium)
                    .foregroundColor(Color.mimo.textSecondary)
                
                HStack(spacing: 8) {
                    TextField("/Path/to/project", text: $projectPath)
                        .zcodeTextFieldStyle()
                        .interfaceFont(size: 13)
                    
                    Button(action: selectFolder) {
                        Image(systemName: "folder")
                            .interfaceFont(size: 14)
                            .foregroundColor(Color.mimo.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Choose folder")
                }
            }
            
            Spacer()
            
            // Actions
            HStack {
                Button(L.t(AppLocalizationKey.locCancel)) {
                    dismiss()
                }
                .interfaceFont(size: 13)
                .foregroundColor(Color.mimo.textSecondary)
                
                Spacer()
                
                Button(action: createProject) {
                    Text(L.t(AppLocalizationKey.locCreateProject))
                        .interfaceFont(size: 13, weight: .medium)
                }
                .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty || projectPath.trimmingCharacters(in: .whitespaces).isEmpty)
                .buttonStyle(.borderedProminent)
                .tint(Color.mimo.brand)
            }
        }
        .padding(24)
        .frame(width: 420, height: 260)
        .background(Color.mimo.background)
        .onSubmit {
            if !projectName.isEmpty && !projectPath.isEmpty {
                createProject()
            }
        }
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Choose project folder"
        panel.prompt = "Select"
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        projectPath = url.path
        
        if projectName.isEmpty {
            projectName = url.lastPathComponent
        }
    }
    
    private func createProject() {
        let name = projectName.trimmingCharacters(in: .whitespaces)
        let path = projectPath.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !path.isEmpty else { return }
        
        appState.createNewProject(name: name, path: path)
        dismiss()
    }
}
