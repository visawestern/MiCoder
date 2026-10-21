import SwiftUI

/// Full-window spec wizard shown instead of the chat for projects created via
/// the sidebar's "Project with wizard" entry. This first slice captures the
/// model roles and the project brief, persists them in the project database,
/// and blocks chat until the user force-finishes the setup. The model-driven
/// interview and atomic decomposition run on top of this draft.
struct SpecWizardView: View {
    @EnvironmentObject var appState: AppState

    let projectPath: String
    let projectName: String

    @State private var draft = SpecWizardDraft()
    @State private var loaded = false
    @State private var saveTask: Task<Void, Never>?
    @State private var saveState: SaveState = .idle
    @State private var showFinishConfirmation = false
    @State private var showSettingsHint = false

    private enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case failed
    }

    private var models: [String] {
        Array(Set(appState.availableModels)).sorted()
    }

    private var checklist: [SpecWizardChecklistLogic.Item] {
        SpecWizardChecklistLogic.items(for: draft)
    }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    modelsCard
                    briefCard
                    footer
                }
                .padding(28)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }

            Divider()

            checklistPane
                .frame(width: 300)
        }
        .background(Color.mimo.background)
        .onAppear(perform: load)
        .onChange(of: draft) { _ in scheduleSave() }
        .alert(L.t("Finish the wizard and open chat?"), isPresented: $showFinishConfirmation) {
            Button(L.t("Cancel"), role: .cancel) {}
            Button(L.t("Finish wizard"), role: .destructive) { finishWizard() }
        } message: {
            Text(L.t("The spec stays saved as a draft. You can reopen the project spec later; chat will be available immediately."))
        }
        .alert(L.t("No models configured"), isPresented: $showSettingsHint) {
            Button(L.t("Open settings")) {
                appState.showSettings = true
                appState.settingsTab = .providers
            }
            Button(L.t("Cancel"), role: .cancel) {}
        } message: {
            Text(L.t("Add a provider or connect a local model before choosing planner and coder roles."))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .interfaceFont(size: 22, weight: .medium)
                    .foregroundColor(Color.mimo.cyan)
                    .padding(10)
                    .background(Color.mimo.cyan.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(L.t("Project with wizard"))
                        .interfaceFont(size: 20, weight: .semibold)
                        .foregroundColor(Color.mimo.textPrimary)
                    Text(projectName)
                        .interfaceFont(size: 12)
                        .foregroundColor(Color.mimo.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(L.t("Step 1 of 4"))
                    .interfaceFont(size: 10, weight: .bold, design: .monospaced)
                    .foregroundColor(Color.mimo.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.mimo.cyan.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.mimo.cyan.opacity(0.35), lineWidth: 1))
            }

            Text(L.t("Describe the project. The model-driven interview, checklist and atomic decomposition build on this setup."))
                .interfaceFont(size: 12)
                .foregroundColor(Color.mimo.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var modelsCard: some View {
        card(title: L.t("Model roles"), icon: "cpu") {
            VStack(alignment: .leading, spacing: 12) {
                modelRow(
                    title: L.t("Planner model"),
                    hint: L.t("Writes questions, the specification and the decomposition."),
                    selection: $draft.plannerModel
                )
                Divider().opacity(0.5)
                modelRow(
                    title: L.t("Coder model"),
                    hint: L.t("Implements one atomic node at a time against its spec."),
                    selection: $draft.coderModel
                )

                if models.isEmpty {
                    Button(L.t("Configure models…")) { showSettingsHint = true }
                        .buttonStyle(.plain)
                        .interfaceFont(size: 11, weight: .medium)
                        .foregroundColor(Color.mimo.cyan)
                }
            }
        }
    }

    private func modelRow(title: String, hint: String, selection: Binding<String>) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .interfaceFont(size: 12, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
                Text(hint)
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 16)

            Menu {
                if models.isEmpty {
                    Text(L.t("No models available")).interfaceFont(size: 11)
                } else {
                    ForEach(models, id: \.self) { model in
                        Button {
                            selection.wrappedValue = model
                        } label: {
                            if selection.wrappedValue == model {
                                Label(model, systemImage: "checkmark")
                            } else {
                                Text(model)
                            }
                        }
                    }
                }
                Divider()
                Button(L.t("Manage models")) {
                    appState.showSettings = true
                    appState.settingsTab = .providers
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selection.wrappedValue.isEmpty ? L.t("Choose model") : selection.wrappedValue)
                        .interfaceFont(size: 12)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .interfaceFont(size: 9)
                }
                .foregroundColor(selection.wrappedValue.isEmpty ? Color.mimo.textMuted : Color.mimo.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.mimo.controlBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.mimo.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    private var briefCard: some View {
        card(title: L.t("Project brief"), icon: "doc.text") {
            VStack(alignment: .leading, spacing: 14) {
                briefField(
                    title: L.t("Goal"),
                    placeholder: L.t("What should this project do, and for whom?"),
                    text: $draft.goal,
                    height: 88
                )
                briefField(
                    title: L.t("Stack"),
                    placeholder: L.t("Languages, frameworks, storage, target platform…"),
                    text: $draft.stack,
                    height: 64
                )
                briefField(
                    title: L.t("Constraints"),
                    placeholder: L.t("Deadlines, compatibility, security, things that must not change…"),
                    text: $draft.constraints,
                    height: 64
                )
            }
        }
    }

    private func briefField(title: String, placeholder: String, text: Binding<String>, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .interfaceFont(size: 11, weight: .semibold)
                .foregroundColor(Color.mimo.textSecondary)
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .interfaceFont(size: 12)
                        .foregroundColor(Color.mimo.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: text)
                    .font(.system(size: 12))
                    .foregroundColor(Color.mimo.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(4)
            }
            .frame(height: height)
            .background(Color.mimo.controlBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.mimo.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            saveStatus
            Spacer()
            Button {
                saveNow()
            } label: {
                Text(L.t("Save draft"))
                    .interfaceFont(size: 12, weight: .medium)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.mimo.controlBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.mimo.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .foregroundColor(Color.mimo.textPrimary)

            Button {
                showFinishConfirmation = true
            } label: {
                Text(L.t("Finish wizard"))
                    .interfaceFont(size: 12, weight: .semibold)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.mimo.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .foregroundColor(.white)
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var saveStatus: some View {
        switch saveState {
        case .idle:
            EmptyView()
        case .saving:
            Text(L.t("Saving…")).interfaceFont(size: 11).foregroundColor(Color.mimo.textMuted)
        case .saved:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill").interfaceFont(size: 10)
                Text(L.t("Saved")).interfaceFont(size: 11)
            }
            .foregroundColor(Color.mimo.success)
        case .failed:
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill").interfaceFont(size: 10)
                Text(L.t("Could not save the draft. Check the project database.")).interfaceFont(size: 11)
            }
            .foregroundColor(Color.mimo.error)
        }
    }

    private var checklistPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L.t("Wizard checklist"))
                .interfaceFont(size: 11, weight: .bold, design: .monospaced)
                .tracking(0.8)
                .foregroundColor(Color.mimo.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.mimo.controlBackground)
                        Capsule()
                            .fill(Color.mimo.cyan)
                            .frame(width: geometry.size.width * SpecWizardChecklistLogic.progress(for: draft))
                    }
                }
                .frame(height: 5)
                Text("\(Int((SpecWizardChecklistLogic.progress(for: draft) * 100).rounded()))%")
                    .interfaceFont(size: 10, design: .monospaced)
                    .foregroundColor(Color.mimo.textMuted)
            }

            VStack(alignment: .leading, spacing: 10) {
                checklistRow(id: .models)
                checklistRow(id: .brief)
                checklistRow(id: .interview)
                checklistRow(id: .specification)
                checklistRow(id: .decomposition)
            }

            Spacer()

            Text(L.t("Chat is blocked for this project until the wizard is finished or force-finished."))
                .interfaceFont(size: 10)
                .foregroundColor(Color.mimo.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(Color.mimo.backgroundAlt)
    }

    private func checklistRow(id: SpecWizardChecklistLogic.ItemID) -> some View {
        let state = checklist.first(where: { $0.id == id })?.state ?? .pending
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon(for: state))
                .interfaceFont(size: 12)
                .foregroundColor(color(for: state))
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(title(for: id))
                    .interfaceFont(size: 12, weight: state == .done ? .semibold : .regular)
                    .foregroundColor(state == .upcoming ? Color.mimo.textMuted : Color.mimo.textPrimary)
                if let detail = detail(for: id, state: state) {
                    Text(detail)
                        .interfaceFont(size: 10)
                        .foregroundColor(Color.mimo.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func title(for id: SpecWizardChecklistLogic.ItemID) -> String {
        switch id {
        case .models: return L.t("Planner and coder models")
        case .brief: return L.t("Project brief")
        case .interview: return L.t("Spec interview")
        case .specification: return L.t("Specification")
        case .decomposition: return L.t("Atomic decomposition")
        }
    }

    private func detail(for id: SpecWizardChecklistLogic.ItemID, state: SpecWizardChecklistLogic.ItemState) -> String? {
        switch (id, state) {
        case (.interview, .upcoming), (.decomposition, .upcoming):
            return L.t("Next wizard step")
        case (.models, .pending):
            return L.t("Choose both roles")
        case (.brief, .pending):
            return L.t("Goal and stack are required")
        case (.interview, .pending):
            return L.t("Answer the planner's questions")
        case (.specification, .pending):
            return L.t("Generate the spec from the interview")
        case (.decomposition, .pending):
            return L.t("Split the spec into atomic nodes")
        default:
            return nil
        }
    }

    private func icon(for state: SpecWizardChecklistLogic.ItemState) -> String {
        switch state {
        case .done: return "checkmark.circle.fill"
        case .pending: return "circle"
        case .upcoming: return "lock.circle"
        }
    }

    private func color(for state: SpecWizardChecklistLogic.ItemState) -> Color {
        switch state {
        case .done: return Color.mimo.success
        case .pending: return Color.mimo.textMuted
        case .upcoming: return Color.mimo.textMuted.opacity(0.7)
        }
    }

    private func card<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textSecondary)
                Text(title)
                    .interfaceFont(size: 13, weight: .semibold)
                    .foregroundColor(Color.mimo.textPrimary)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mimo.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.mimo.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Persistence

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let stored = DatabaseBridge.shared.loadSpecWizardDraft(projectPath: projectPath) {
            draft = stored
            if stored.status != .draft {
                appState.finishSpecWizard(for: projectPath)
                return
            }
        } else {
            draft.plannerModel = appState.selectedModel.isEmpty
                ? appState.effectiveSelectedModel()
                : appState.selectedModel
            draft.coderModel = draft.plannerModel
            scheduleSave()
        }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveState = .saving
        let snapshot = draft
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            let ok = DatabaseBridge.shared.saveSpecWizardDraft(snapshot, projectPath: projectPath)
            await MainActor.run {
                saveState = ok ? .saved : .failed
            }
        }
    }

    private func saveNow() {
        saveTask?.cancel()
        saveState = .saving
        let ok = DatabaseBridge.shared.saveSpecWizardDraft(draft, projectPath: projectPath)
        saveState = ok ? .saved : .failed
    }

    private func finishWizard() {
        draft.status = .forced
        saveNow()
        appState.finishSpecWizard(for: projectPath)
    }
}
