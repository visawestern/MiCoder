import Foundation

/// Persisted state of the project spec wizard. Stored inside the project's own
/// database (`project_metadata`) so it travels with the project and survives
/// restarts. This is the first slice of the wizard: model roles + project
/// brief. The model-driven interview and decomposition build on this draft.
struct SpecWizardDraft: Codable, Equatable {
    enum Status: String, Codable {
        case draft
        case forced
        case complete
    }

    var status: Status = .draft
    var goal: String = ""
    var stack: String = ""
    var constraints: String = ""
    var plannerModel: String = ""
    var coderModel: String = ""
    var updatedAt: TimeInterval = 0

    var isEmpty: Bool {
        goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && stack.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && constraints.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Checklist shown on the right side of the wizard. Every item is driven by
/// real draft data or by an explicit implementation phase — nothing is faked.
enum SpecWizardChecklistLogic {
    enum ItemID: String, CaseIterable {
        case models
        case brief
        case interview
        case decomposition
    }

    enum ItemState: Equatable {
        case done
        case pending
        case upcoming
    }

    struct Item: Identifiable, Equatable {
        let id: ItemID
        let state: ItemState
    }

    static func items(for draft: SpecWizardDraft) -> [Item] {
        let modelsReady = !draft.plannerModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !draft.coderModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let briefReady = !draft.goal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !draft.stack.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return [
            Item(id: .models, state: modelsReady ? .done : .pending),
            Item(id: .brief, state: briefReady ? .done : .pending),
            // The interview/decomposition phases have no implementation yet.
            // They are explicitly "upcoming" instead of pretending to be done.
            Item(id: .interview, state: .upcoming),
            Item(id: .decomposition, state: .upcoming)
        ]
    }

    /// Done items / actionable items. Upcoming phases are not counted until
    /// they exist, so the progress bar never claims work that was not done.
    static func progress(for draft: SpecWizardDraft) -> Double {
        let all = items(for: draft)
        let actionable = all.filter { $0.state != .upcoming }
        guard !actionable.isEmpty else { return 0 }
        let done = actionable.filter { $0.state == .done }.count
        return Double(done) / Double(actionable.count)
    }

    static func canFinish(_ draft: SpecWizardDraft) -> Bool {
        items(for: draft).allSatisfy { $0.state == .done }
    }
}
