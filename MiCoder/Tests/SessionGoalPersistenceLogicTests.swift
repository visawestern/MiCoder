import Testing
@testable import MiCoder

@Suite("Session goal persistence routing")
struct SessionGoalPersistenceLogicTests {
    @Test("restored project goal survives session hydration")
    func projectGoalSurvivesHydration() {
        #expect(SessionGoalPersistenceLogic.effectiveGoal(
            projectStoredGoal: "Ship the release",
            legacyStoredGoal: nil
        ) == "Ship the release")
    }

    @Test("project-scoped goal wins over stale legacy global goal")
    func projectGoalWinsOverLegacy() {
        #expect(SessionGoalPersistenceLogic.effectiveGoal(
            projectStoredGoal: "Project-specific goal",
            legacyStoredGoal: "Stale global goal"
        ) == "Project-specific goal")
    }

    @Test("empty project goal falls back to legacy only for compatibility")
    func legacyCompatibilityFallback() {
        #expect(SessionGoalPersistenceLogic.effectiveGoal(
            projectStoredGoal: "  ",
            legacyStoredGoal: "Legacy goal"
        ) == "Legacy goal")
        #expect(SessionGoalPersistenceLogic.effectiveGoal(
            projectStoredGoal: nil,
            legacyStoredGoal: nil
        ) == nil)
    }
}
