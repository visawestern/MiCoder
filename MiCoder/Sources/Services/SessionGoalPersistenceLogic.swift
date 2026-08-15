import Foundation

enum SessionGoalPersistenceLogic {
    static func effectiveGoal(projectStoredGoal: String?, legacyStoredGoal: String?) -> String? {
        let project = projectStoredGoal?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !project.isEmpty { return project }
        let legacy = legacyStoredGoal?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return legacy.isEmpty ? nil : legacy
    }
}
