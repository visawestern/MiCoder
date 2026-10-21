import SwiftUI

/// Full-window spec wizard shown instead of the chat for projects created via
/// the sidebar's "Project with wizard" entry. The setup step captures the model
/// roles and the brief; the following steps run the planner interview, store
/// each specification revision, and split the approved spec into atomic nodes.
/// Chat stays blocked until the decomposition exists or the user force-finishes.
struct SpecWizardView: View {
    @EnvironmentObject var appState: AppState

    let projectPath: String
    let projectName: String

    @State private var session: SpecWizardSession?
    @State private var initError: String?

    var body: some View {
        Group {
            if let session {
                SpecWizardContent(session: session)
                    .environmentObject(appState)
            } else if let initError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .interfaceFont(size: 22)
                        .foregroundColor(Color.mimo.error)
                    Text(initError)
                        .interfaceFont(size: 12)
                        .foregroundColor(Color.mimo.textSecondary)
                        .multilineTextAlignment(.center)
                    Button(L.t("Finish wizard")) {
                        appState.finishSpecWizard(for: projectPath)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(Color.mimo.cyan)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.mimo.background)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.mimo.background)
            }
        }
        .onAppear(perform: makeSession)
    }

    private func makeSession() {
        guard session == nil else { return }
        guard let database = try? ProjectDatabaseManager.manager(forProjectPath: projectPath) else {
            initError = L.t("Could not open the project database.")
            return
        }
        let created = SpecWizardSession(
            projectPath: projectPath,
            projectName: projectName,
            database: database,
            providerID: appState.selectedProviderID,
            routeProvider: { model in
                let route = SendRouteResolver.route(
                    selectedProviderID: appState.selectedProviderID,
                    selectedModel: model,
                    serverConnected: appState.serverConnected,
                    isACP: appState.isSelectedACPProvider,
                    customProviders: appState.customProviders,
                    localProviders: LocalProviderLogic.load(),
                    webProviderIDs: appState.webProviderIDs
                )
                return SpecPlannerRoute(sendRoute: route, model: model)
            }
        )
        if created.draft.plannerModel.isEmpty {
            let current = appState.selectedModel.isEmpty
                ? appState.effectiveSelectedModel()
                : appState.selectedModel
            created.draft.plannerModel = current
            created.draft.coderModel = current
        }
        session = created
        if created.draft.status != .draft {
            appState.finishSpecWizard(for: projectPath)
        }
    }
}

// MARK: - Content

private struct SpecWizardContent: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var session: SpecWizardSession

    @State private var answerText = ""
    @State private var specEditorText = ""
    @State private var isEditingSpec = false
    @State private var saveTask: Task<Void, Never>?
    @State private var saveState: SaveState = .idle
    @State private var showFinishConfirmation = false
    @State private var showSettingsHint = false
    @State private var showSetup: Bool

    init(session: SpecWizardSession) {
        self.session = session
        _showSetup = State(initialValue: session.draft.step == .setup)
    }

    private enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case failed
    }

    private var draft: SpecWizardDraft { session.draft }
    private var models: [String] { Array(Set(appState.availableModels)).sorted() }
    private var checklist: [SpecWizardChecklistLogic.Item] {
        SpecWizardChecklistLogic.items(for: draft)
    }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    phaseContent
                    if let error = session.errorMessage {
                        errorBanner(error)
                    }
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
        .onChange(of: session.draft) { _ in scheduleSave() }
        .onChange(of: session.draft.step) { step in
            if step == .interview {
                Task { await session.startInterviewIfNeeded() }
            }
        }
        .task {
            await session.startInterviewIfNeeded()
        }
        .alert(L.t("Finish the wizard and open chat?"), isPresented: $showFinishConfirmation) {
            Button(L.t("Cancel"), role: .cancel) {}
            Button(L.t("Finish wizard"), role: .destructive) { forceFinish() }
        } message: {
            Text(L.t("Unfinished steps stay saved as a draft. You can reopen the project spec later; chat will be available immediately."))
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

    // MARK: Header

    private var visibleStep: SpecWizardStep {
        showSetup ? .setup : draft.step
    }

    private var stepNumber: Int {
        switch visibleStep {
        case .setup: return 1
        case .interview: return 2
        case .specification: return 3
        case .decomposition: return 4
        case .ready: return 4
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
                    HStack(spacing: 8) {
                        Text(L.t("Project with wizard"))
                            .interfaceFont(size: 20, weight: .semibold)
                            .foregroundColor(Color.mimo.textPrimary)
                        Text(L.t(phaseTitle))
                            .interfaceFont(size: 10, weight: .semibold)
                            .foregroundColor(Color.mimo.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.mimo.cyan.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Text(session.projectName)
                        .interfaceFont(size: 12)
                        .foregroundColor(Color.mimo.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(stepNumber) / 4")
                    .interfaceFont(size: 10, weight: .bold, design: .monospaced)
                    .foregroundColor(Color.mimo.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.mimo.cyan.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.mimo.cyan.opacity(0.35), lineWidth: 1))
            }

            Text(L.t(phaseSubtitle))
                .interfaceFont(size: 12)
                .foregroundColor(Color.mimo.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var phaseTitle: String {
        switch visibleStep {
        case .setup: return "Setup"
        case .interview: return "Interview"
        case .specification: return "Specification"
        case .decomposition: return "Decomposition"
        case .ready: return "Ready"
        }
    }

    private var phaseSubtitle: String {
        switch visibleStep {
        case .setup:
            return "Describe the project. The model-driven interview, checklist and atomic decomposition build on this setup."
        case .interview:
            return "The planner asks one question at a time. Every answer and question is stored in this project."
        case .specification:
            return "The planner turns the interview into a versioned technical specification. Edit it before decomposing if needed."
        case .decomposition:
            return "The specification is split into atomic nodes with explicit dependencies and acceptance criteria."
        case .ready:
            return "The specification and its atomic decomposition are ready. Finish the wizard to open chat."
        }
    }

    // MARK: Phases

    @ViewBuilder
    private var phaseContent: some View {
        if showSetup && draft.step == .setup {
            setupPhase
        } else {
            switch draft.step {
            case .setup:
                setupPhase
            case .interview:
                interviewPhase
            case .specification:
                specificationPhase
            case .decomposition:
                decompositionPhase
            case .ready:
                readyPhase
            }
        }
    }

    private var setupPhase: some View {
        VStack(spacing: 20) {
            modelsCard
            briefCard
            HStack {
                Spacer()
                primaryButton(L.t("Continue to interview"), icon: "arrow.right") {
                    guard draft.hasModels else {
                        session.errorMessage = L.t("Choose both roles")
                        return
                    }
                    guard draft.hasBrief else {
                        session.errorMessage = L.t("Goal and stack are required")
                        return
                    }
                    session.errorMessage = nil
                    showSetup = false
                    _ = session.saveDraft()
                    Task { await session.startInterviewIfNeeded() }
                }
                .disabled(!draft.hasModels || !draft.hasBrief || session.isLoading)
            }
        }
    }

    private var modelsCard: some View {
        card(title: L.t("Model roles"), icon: "cpu") {
            VStack(alignment: .leading, spacing: 12) {
                modelRow(
                    title: L.t("Planner model"),
                    hint: L.t("Writes questions, the specification and the decomposition."),
                    selection: $session.draft.plannerModel
                )
                Divider().opacity(0.5)
                modelRow(
                    title: L.t("Coder model"),
                    hint: L.t("Implements one atomic node at a time against its spec."),
                    selection: $session.draft.coderModel
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
                    text: $session.draft.goal,
                    height: 88
                )
                briefField(
                    title: L.t("Stack"),
                    placeholder: L.t("Languages, frameworks, storage, target platform…"),
                    text: $session.draft.stack,
                    height: 64
                )
                briefField(
                    title: L.t("Constraints"),
                    placeholder: L.t("Deadlines, compatibility, security, things that must not change…"),
                    text: $session.draft.constraints,
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

    // MARK: Interview

    private var interviewPhase: some View {
        VStack(alignment: .leading, spacing: 16) {
            card(title: L.t("Planner interview"), icon: "bubble.left.and.bubble.right") {
                VStack(alignment: .leading, spacing: 12) {
                    if session.turns.isEmpty {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text(L.t("Preparing the first question…"))
                                .interfaceFont(size: 12)
                                .foregroundColor(Color.mimo.textMuted)
                        }
                    } else {
                        ForEach(Array(session.turns.enumerated()), id: \.offset) { _, turn in
                            interviewTurn(turn)
                        }
                    }

                    if session.isLoading {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text(L.t("The planner is thinking…"))
                                .interfaceFont(size: 12)
                                .foregroundColor(Color.mimo.textMuted)
                        }
                    }
                }
            }

            if let question = session.currentQuestion, !question.done {
                questionCard(question)
            } else if let summary = session.completedSummary, draft.interviewComplete {
                card(title: L.t("Interview complete"), icon: "checkmark.seal") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(summary)
                            .interfaceFont(size: 12)
                            .foregroundColor(Color.mimo.textPrimary)
                        HStack {
                            Spacer()
                            primaryButton(L.t("Generate specification"), icon: "doc.badge.plus") {
                                Task { await session.generateSpecification() }
                            }
                            .disabled(session.isLoading)
                        }
                    }
                }
            }
        }
    }

    private func interviewTurn(_ turn: SpecPlannerTurn) -> some View {
        let isPlanner = turn.role == "planner"
        let text = isPlanner ? plannerDisplayText(turn.content) : turn.content
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: isPlanner ? "wand.and.stars" : "person.fill")
                .interfaceFont(size: 10)
                .foregroundColor(isPlanner ? Color.mimo.cyan : Color.mimo.textMuted)
                .frame(width: 16)
            Text(text)
                .interfaceFont(size: 12)
                .foregroundColor(Color.mimo.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(isPlanner ? Color.mimo.cyan.opacity(0.06) : Color.mimo.controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func plannerDisplayText(_ raw: String) -> String {
        guard let data = raw.data(using: .utf8),
              let question = try? JSONDecoder().decode(SpecInterviewQuestion.self, from: data) else {
            return raw
        }
        if question.done {
            return question.summary ?? L.t("Interview complete")
        }
        return question.question
    }

    private func questionCard(_ question: SpecInterviewQuestion) -> some View {
        card(title: L.t("Question"), icon: "questionmark.circle") {
            VStack(alignment: .leading, spacing: 12) {
                Text(question.question)
                    .interfaceFont(size: 13, weight: .medium)
                    .foregroundColor(Color.mimo.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if !question.suggestedAnswers.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                        ForEach(question.suggestedAnswers, id: \.self) { answer in
                            Button {
                                submit(answer)
                            } label: {
                                Text(answer)
                                    .interfaceFont(size: 11)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 10)
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
                        }
                    }
                }

                HStack(spacing: 8) {
                    TextField(L.t("Your answer…"), text: $answerText)
                        .textFieldStyle(.plain)
                        .interfaceFont(size: 12)
                        .padding(8)
                        .background(Color.mimo.controlBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.mimo.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .onSubmit { submit(answerText) }

                    primaryButton(L.t("Send"), icon: "arrow.up") {
                        submit(answerText)
                    }
                    .disabled(session.isLoading || answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func submit(_ answer: String) {
        let clean = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        answerText = ""
        Task { await session.submitAnswer(clean) }
    }

    // MARK: Specification

    private var specificationPhase: some View {
        card(title: L.t("Technical specification"), icon: "doc.richtext") {
            VStack(alignment: .leading, spacing: 14) {
                Text(L.t("The planner will write a versioned specification from the interview answers."))
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textSecondary)
                HStack {
                    Spacer()
                    primaryButton(L.t("Generate specification"), icon: "doc.badge.plus") {
                        Task { await session.generateSpecification() }
                    }
                    .disabled(session.isLoading)
                }
            }
        }
    }

    private var specificationCard: some View {
        card(title: L.t("Technical specification"), icon: "doc.richtext") {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("v\(draft.specVersion)")
                        .interfaceFont(size: 10, weight: .bold, design: .monospaced)
                        .foregroundColor(Color.mimo.cyan)
                    Spacer()
                    Button(L.t("Edit")) {
                        specEditorText = session.specification
                        isEditingSpec = true
                    }
                    .buttonStyle(.plain)
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.cyan)
                }

                if isEditingSpec {
                    TextEditor(text: $specEditorText)
                        .font(.system(size: 12))
                        .foregroundColor(Color.mimo.textPrimary)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 260)
                        .background(Color.mimo.controlBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    HStack {
                        Button(L.t("Cancel")) {
                            isEditingSpec = false
                        }
                        .buttonStyle(.plain)
                        .interfaceFont(size: 11)
                        .foregroundColor(Color.mimo.textMuted)
                        Spacer()
                        primaryButton(L.t("Save as new version"), icon: "square.and.arrow.down") {
                            session.saveSpecificationEdits(specEditorText)
                            isEditingSpec = false
                        }
                    }
                } else {
                    MarkdownText(text: session.specification, fontSize: 12)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.mimo.controlBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                HStack(spacing: 10) {
                    Button(L.t("Regenerate")) {
                        Task { await session.generateSpecification() }
                    }
                    .buttonStyle(.plain)
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
                    .disabled(session.isLoading)
                    Spacer()
                }
            }
        }
    }

    // MARK: Decomposition

    private var decompositionPhase: some View {
        VStack(alignment: .leading, spacing: 14) {
            specificationCard

            if session.nodes.isEmpty {
                card(title: L.t("Atomic decomposition"), icon: "square.stack.3d.up") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L.t("Split the approved specification into independently verifiable nodes. The planner will not write code here."))
                            .interfaceFont(size: 12)
                            .foregroundColor(Color.mimo.textSecondary)
                        HStack {
                            Spacer()
                            primaryButton(L.t("Generate decomposition"), icon: "square.stack.3d.up") {
                                Task { await session.generateDecomposition() }
                            }
                            .disabled(session.isLoading)
                        }
                    }
                }
            } else {
                ForEach(session.nodes, id: \.id) { node in
                    decompositionNodeCard(node)
                }

                HStack {
                    Spacer()
                    primaryButton(L.t("Finish and open chat"), icon: "checkmark.circle") {
                        if session.finishWizard(forced: false) {
                            appState.finishSpecWizard(for: session.projectPath)
                        }
                    }
                }
            }
        }
    }

    private func decompositionNodeCard(_ node: ProjectSpecNode) -> some View {
        let dependencies = session.dependencies(of: node)
        let acceptance = decodeAcceptance(node.acceptanceCriteriaJSON)
        return card(title: "\(node.externalKey) · \(node.title)", icon: "circle.hexagongrid") {
            VStack(alignment: .leading, spacing: 10) {
                Text(node.description)
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !acceptance.isEmpty {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L.t("Acceptance criteria"))
                            .interfaceFont(size: 10, weight: .semibold)
                            .foregroundColor(Color.mimo.textMuted)
                        ForEach(acceptance, id: \.self) { item in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                Text(item)
                            }
                            .interfaceFont(size: 11)
                            .foregroundColor(Color.mimo.textPrimary)
                        }
                    }
                }

                if !dependencies.isEmpty {
                    Text("\(L.t("Depends on")): \(dependencies.map(\.externalKey).joined(separator: ", "))")
                        .interfaceFont(size: 10, design: .monospaced)
                        .foregroundColor(Color.mimo.textMuted)
                }
            }
        }
    }

    private func decodeAcceptance(_ json: String?) -> [String] {
        guard let json, let data = json.data(using: .utf8),
              let values = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return values
    }

    // MARK: Ready

    private var readyPhase: some View {
        card(title: L.t("Spec ready"), icon: "checkmark.seal.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(draft.decompositionNodeCount) \(L.t("atomic nodes")) · v\(draft.specVersion)")
                    .interfaceFont(size: 12)
                    .foregroundColor(Color.mimo.textSecondary)
                Text(L.t("Chat opens after you finish the wizard. The specification and every revision stay available in this project."))
                    .interfaceFont(size: 11)
                    .foregroundColor(Color.mimo.textMuted)
                HStack {
                    Spacer()
                    primaryButton(L.t("Finish and open chat"), icon: "checkmark.circle") {
                        if session.finishWizard(forced: false) {
                            appState.finishSpecWizard(for: session.projectPath)
                        }
                    }
                }
            }
        }
    }

    // MARK: Footer

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

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .interfaceFont(size: 11)
                .foregroundColor(Color.mimo.error)
            Text(message)
                .interfaceFont(size: 11)
                .foregroundColor(Color.mimo.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                session.errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .interfaceFont(size: 9)
            }
            .buttonStyle(.plain)
            .foregroundColor(Color.mimo.textMuted)
        }
        .padding(10)
        .background(Color.mimo.error.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.mimo.error.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: Checklist

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

            if draft.specVersion > 0 {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L.t("Spec revision"))
                        .interfaceFont(size: 10, weight: .semibold)
                        .foregroundColor(Color.mimo.textMuted)
                    Text("v\(draft.specVersion)")
                        .interfaceFont(size: 12, design: .monospaced)
                        .foregroundColor(Color.mimo.textPrimary)
                }
            }

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

    // MARK: Building blocks

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

    private func primaryButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .interfaceFont(size: 10, weight: .semibold)
                Text(title)
                    .interfaceFont(size: 12, weight: .semibold)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .background(Color.mimo.brand)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .foregroundColor(.white)
        .opacity(session.isLoading ? 0.55 : 1)
    }

    // MARK: Persistence

    private func scheduleSave() {
        saveTask?.cancel()
        saveState = .saving
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            saveState = session.saveDraft() ? .saved : .failed
        }
    }

    private func saveNow() {
        saveTask?.cancel()
        saveState = session.saveDraft() ? .saved : .failed
    }

    private func forceFinish() {
        guard session.finishWizard(forced: true) else { return }
        appState.finishSpecWizard(for: session.projectPath)
    }
}
