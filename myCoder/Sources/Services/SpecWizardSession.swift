import Foundation
import Combine

/// Owns one project's spec wizard run: the small draft gate state plus the
/// append-only interview, specification revisions and decomposition stored in
/// the project database. The SwiftUI view only renders and forwards actions;
/// every state transition here is persisted before it is published as done.
@MainActor
final class SpecWizardSession: ObservableObject {
    @Published var draft: SpecWizardDraft
    @Published private(set) var turns: [SpecPlannerTurn] = []
    @Published private(set) var currentQuestion: SpecInterviewQuestion?
    @Published private(set) var completedSummary: String?
    @Published private(set) var specification: String = ""
    @Published private(set) var latestRevision: ProjectSpecRevision?
    @Published private(set) var nodes: [ProjectSpecNode] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastSavedAt: Date?
    @Published var errorMessage: String?

    let projectPath: String
    let projectName: String

    private let database: ProjectDatabaseManager
    private let store: ProjectSpecStore
    private let planner: SpecPlannerService
    private let providerID: String?
    private let routeProvider: (String) -> SpecPlannerRoute?
    private let projectID: String

    init(projectPath: String,
         projectName: String,
         database: ProjectDatabaseManager,
         providerID: String?,
         planner: SpecPlannerService = SpecPlannerService(),
         routeProvider: @escaping (String) -> SpecPlannerRoute?) {
        self.projectPath = projectPath
        self.projectName = projectName
        self.database = database
        self.providerID = providerID
        self.planner = planner
        self.routeProvider = routeProvider
        self.projectID = ProjectIdentityLogic.projectID(for: projectPath)
        self.store = database.makeSpecStore()
        self.draft = Self.loadDraft(from: database) ?? SpecWizardDraft()
        loadPersistedState()
    }

    // MARK: - Loaded state

    private static func loadDraft(from database: ProjectDatabaseManager) -> SpecWizardDraft? {
        guard let raw = try? database.metadataValue(forKey: "spec_wizard_draft"),
              let data = raw.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(SpecWizardDraft.self, from: data)
    }

    private func loadPersistedState() {
        if let stored = try? store.turns(projectID: projectID) {
            turns = stored.map { SpecPlannerTurn(role: $0.role, content: $0.content) }
        }
        decodeLastQuestion()

        if let revision = try? store.latestRevision(projectID: projectID) {
            latestRevision = revision
            specification = revision.contentMarkdown
            draft.specVersion = Int(revision.version)
            if let storedNodes = try? store.nodes(revisionID: revision.id) {
                nodes = storedNodes
                draft.decompositionNodeCount = storedNodes.count
            }
        }
    }

    private func decodeLastQuestion() {
        guard let lastPlannerTurn = turns.last(where: { $0.role == "planner" }),
              let data = lastPlannerTurn.content.data(using: .utf8),
              let question = try? JSONDecoder().decode(SpecInterviewQuestion.self, from: data) else {
            currentQuestion = nil
            completedSummary = nil
            return
        }
        if question.done {
            currentQuestion = nil
            completedSummary = question.summary
        } else {
            currentQuestion = question
            completedSummary = nil
        }
    }

    // MARK: - Draft persistence

    /// Writes the small gate draft, the settings row and the five checklist
    /// rows in one pass. Returns false and surfaces the error on the view.
    @discardableResult
    func saveDraft() -> Bool {
        var storedDraft = draft
        storedDraft.updatedAt = Date().timeIntervalSince1970
        let now = Int64(Date().timeIntervalSince1970)
        do {
            let existing = try store.settings(projectID: projectID)
            var settings = ProjectSpecSettings(
                projectID: projectID,
                plannerProviderID: providerID,
                plannerModelID: draft.plannerModel,
                coderProviderID: providerID,
                coderModelID: draft.coderModel,
                status: draft.status.rawValue,
                currentStep: draft.step.rawValue,
                briefGoal: draft.goal,
                briefStack: draft.stack,
                briefConstraints: draft.constraints,
                createdAt: existing?.createdAt ?? now,
                updatedAt: now,
                completedAt: draft.status == .draft ? nil : (existing?.completedAt ?? now)
            )
            settings.status = draft.status.rawValue
            try store.saveSettings(settings)
            try store.replaceChecklist(projectID: projectID, items: checklistItems(now: now))

            let data = try JSONEncoder().encode(storedDraft)
            guard let raw = String(data: data, encoding: .utf8) else {
                errorMessage = "Could not encode the wizard draft"
                return false
            }
            try database.setMetadataValue(raw, forKey: "spec_wizard_draft")
            lastSavedAt = Date()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func checklistItems(now: Int64) -> [ProjectSpecChecklistItem] {
        let titles: [SpecWizardChecklistLogic.ItemID: String] = [
            .models: "Planner and coder models",
            .brief: "Project brief",
            .interview: "Planner interview",
            .specification: "Technical specification",
            .decomposition: "Atomic decomposition"
        ]
        return SpecWizardChecklistLogic.items(for: draft).enumerated().map { index, item in
            ProjectSpecChecklistItem(
                id: "\(projectID):\(item.id.rawValue)",
                projectID: projectID,
                itemKey: item.id.rawValue,
                title: titles[item.id] ?? item.id.rawValue,
                state: checklistState(item.state),
                detail: nil,
                sortOrder: Int64(index),
                updatedAt: now
            )
        }
    }

    private func checklistState(_ state: SpecWizardChecklistLogic.ItemState) -> String {
        switch state {
        case .done: return "done"
        case .pending: return "pending"
        case .upcoming: return "upcoming"
        }
    }

    private func appendHistory(action: String,
                               entityType: String,
                               entityID: String,
                               payloadJSON: String? = nil) {
        let entry = ProjectSpecHistoryEntry(
            id: UUID().uuidString,
            projectID: projectID,
            entityType: entityType,
            entityID: entityID,
            action: action,
            payloadJSON: payloadJSON,
            actor: "user",
            createdAt: Int64(Date().timeIntervalSince1970)
        )
        try? store.appendHistory(entry)
    }

    // MARK: - Interview

    /// Sends one answer (or an empty string to fetch the first question) and
    /// appends both turns. The planner's JSON turn is stored verbatim so the
    /// question survives a restart with the same options.
    func submitAnswer(_ answer: String) async {
        guard !isLoading else { return }
        let clean = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let route = route(for: draft.plannerModel) else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if !clean.isEmpty {
                let turn = try store.appendTurn(
                    projectID: projectID,
                    role: "user",
                    content: clean,
                    suggestedAnswersJSON: nil,
                    createdAt: Int64(Date().timeIntervalSince1970)
                )
                turns.append(SpecPlannerTurn(role: turn.role, content: turn.content))
            }

            let question = try await planner.nextInterviewQuestion(
                projectName: projectName,
                brief: draft,
                turns: turns,
                route: route
            )
            let encoded = try JSONEncoder().encode(question)
            let raw = String(data: encoded, encoding: .utf8) ?? ""
            let suggestions = try JSONEncoder().encode(question.suggestedAnswers)
            let suggestionsRaw = String(data: suggestions, encoding: .utf8)
            let turn = try store.appendTurn(
                projectID: projectID,
                role: "planner",
                content: raw,
                suggestedAnswersJSON: suggestionsRaw,
                createdAt: Int64(Date().timeIntervalSince1970)
            )
            turns.append(SpecPlannerTurn(role: turn.role, content: turn.content))
            currentQuestion = question.done ? nil : question
            completedSummary = question.done ? question.summary : nil

            if question.done && !draft.interviewComplete {
                draft.interviewComplete = true
                appendHistory(action: "interview_completed",
                              entityType: "interview",
                              entityID: projectID)
                _ = saveDraft()
            } else {
                _ = saveDraft()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Starts the interview on first entry. A restart with stored turns never
    /// asks the first question twice.
    func startInterviewIfNeeded() async {
        guard turns.isEmpty, !draft.interviewComplete, draft.step == .interview else { return }
        await submitAnswer("")
    }

    // MARK: - Specification

    func generateSpecification() async {
        guard !isLoading else { return }
        guard draft.interviewComplete else {
            errorMessage = "Finish the planner interview first"
            return
        }
        guard let route = route(for: draft.plannerModel) else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let markdown = try await planner.generateSpecification(
                projectName: projectName,
                brief: draft,
                turns: turns,
                route: route
            )
            let revision = try store.appendRevision(
                projectID: projectID,
                contentMarkdown: markdown,
                summary: draft.goal,
                source: "planner",
                parentRevisionID: latestRevision?.id,
                createdAt: Int64(Date().timeIntervalSince1970)
            )
            latestRevision = revision
            specification = markdown
            draft.specVersion = Int(revision.version)
            nodes = (try? store.nodes(revisionID: revision.id)) ?? []
            draft.decompositionNodeCount = nodes.count
            appendHistory(action: "spec_revision_created",
                          entityType: "spec_revision",
                          entityID: revision.id,
                          payloadJSON: "{\"version\":\(revision.version)}")
            _ = saveDraft()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Local edits create a new immutable revision rather than mutating the
    /// one the decomposition was built from.
    func saveSpecificationEdits(_ markdown: String) {
        let clean = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            errorMessage = "The specification cannot be empty"
            return
        }
        do {
            let revision = try store.appendRevision(
                projectID: projectID,
                contentMarkdown: clean,
                summary: draft.goal,
                source: "user",
                parentRevisionID: latestRevision?.id,
                createdAt: Int64(Date().timeIntervalSince1970)
            )
            latestRevision = revision
            specification = clean
            draft.specVersion = Int(revision.version)
            nodes = (try? store.nodes(revisionID: revision.id)) ?? []
            draft.decompositionNodeCount = nodes.count
            appendHistory(action: "spec_revision_edited",
                          entityType: "spec_revision",
                          entityID: revision.id,
                          payloadJSON: "{\"version\":\(revision.version)}")
            _ = saveDraft()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Decomposition

    func generateDecomposition() async {
        guard !isLoading else { return }
        guard let revision = latestRevision, draft.specVersion > 0 else {
            errorMessage = "Generate the specification first"
            return
        }
        guard nodes.isEmpty else {
            errorMessage = "A decomposition already exists for this revision"
            return
        }
        guard let route = route(for: draft.plannerModel) else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let decomposition = try await planner.generateDecomposition(
                projectName: projectName,
                brief: draft,
                specification: revision.contentMarkdown,
                route: route
            )
            let now = Int64(Date().timeIntervalSince1970)
            var nodeByKey: [String: ProjectSpecNode] = [:]
            for (index, item) in decomposition.nodes.enumerated() {
                let acceptance = try JSONEncoder().encode(item.acceptanceCriteria)
                nodeByKey[item.key] = ProjectSpecNode(
                    id: UUID().uuidString,
                    projectID: projectID,
                    revisionID: revision.id,
                    externalKey: item.key,
                    title: item.title,
                    description: item.description,
                    kind: item.kind,
                    status: "pending",
                    sortOrder: Int64(index),
                    acceptanceCriteriaJSON: String(data: acceptance, encoding: .utf8),
                    createdAt: now,
                    updatedAt: now
                )
            }
            var edges: [ProjectSpecEdge] = []
            for item in decomposition.nodes {
                guard let node = nodeByKey[item.key] else { continue }
                for dependencyKey in item.dependsOn {
                    guard let dependency = nodeByKey[dependencyKey] else { continue }
                    edges.append(ProjectSpecEdge(
                        id: UUID().uuidString,
                        projectID: projectID,
                        fromNodeID: node.id,
                        toNodeID: dependency.id,
                        kind: "depends_on",
                        createdAt: now
                    ))
                }
            }
            try store.insertDecomposition(nodes: Array(nodeByKey.values), edges: edges)
            nodes = try store.nodes(revisionID: revision.id)
            draft.decompositionNodeCount = nodes.count
            appendHistory(action: "decomposition_created",
                          entityType: "decomposition",
                          entityID: revision.id,
                          payloadJSON: "{\"nodes\":\(nodes.count),\"edges\":\(edges.count)}")
            _ = saveDraft()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dependencies(of node: ProjectSpecNode) -> [ProjectSpecNode] {
        guard let revision = latestRevision,
              let storedEdges = try? store.edges(revisionID: revision.id) else { return [] }
        let ids = Set(storedEdges.filter { $0.fromNodeID == node.id }.map(\.toNodeID))
        return nodes.filter { ids.contains($0.id) }
    }

    // MARK: - Finish

    @discardableResult
    func finishWizard(forced: Bool) -> Bool {
        if !forced {
            guard SpecWizardChecklistLogic.canFinish(draft) else {
                errorMessage = "The specification and decomposition must be ready before chat opens"
                return false
            }
        }
        draft.status = forced ? .forced : .complete
        guard saveDraft() else { return false }
        appendHistory(action: forced ? "wizard_forced" : "wizard_completed",
                      entityType: "wizard",
                      entityID: projectID)
        return true
    }

    // MARK: - Routing

    private func route(for model: String) -> SpecPlannerRoute? {
        guard !model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Choose a planner model"
            return nil
        }
        guard let route = routeProvider(model) else {
            errorMessage = SpecPlannerServiceError.unsupportedRoute.localizedDescription
            return nil
        }
        return route
    }
}
