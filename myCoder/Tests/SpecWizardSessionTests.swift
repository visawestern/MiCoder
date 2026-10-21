import Testing
import Foundation
@testable import myCoder

private final class SessionFakeProvider: SpecCompletionProviding {
    var responses: [Result<String, Error>]
    private(set) var requests: [SpecCompletionRequest] = []

    init(responses: [Result<String, Error>]) {
        self.responses = responses
    }

    func complete(_ request: SpecCompletionRequest) async throws -> String {
        requests.append(request)
        guard !responses.isEmpty else { throw SpecPlannerServiceError.emptyResponse }
        return try responses.removeFirst().get()
    }
}

@Suite("Spec wizard session")
struct SpecWizardSessionTests {

    @MainActor
    private func withSession(
        responses: [Result<String, Error>],
        body: (SpecWizardSession, ProjectSpecStore, SessionFakeProvider) async throws -> Void
    ) async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mycoder-spec-session-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer {
            ProjectDatabaseManager.evictProject(projectPath: dir.path)
            try? FileManager.default.removeItem(at: dir)
        }
        let manager = try ProjectDatabaseManager.manager(forProjectPath: dir.path)
        let provider = SessionFakeProvider(responses: responses)
        let session = SpecWizardSession(
            projectPath: dir.path,
            projectName: "Notes",
            database: manager,
            providerID: "test-provider",
            planner: SpecPlannerService(provider: provider),
            routeProvider: { .autoFree(model: $0) }
        )
        try await body(session, manager.makeSpecStore(), provider)
    }

    @MainActor
    private func prepare(_ session: SpecWizardSession) {
        session.draft.goal = "Offline notes app"
        session.draft.stack = "SwiftUI"
        session.draft.constraints = "No network"
        session.draft.plannerModel = "free"
        session.draft.coderModel = "free"
        #expect(session.saveDraft())
    }

    @Test("Interview turns persist and completion is derived from the planner")
    @MainActor
    func interviewPersists() async throws {
        let question = #"{"id":"q1","question":"Target OS?","suggested_answers":["macOS"],"done":false}"#
        let final = #"{"id":"final","done":true,"summary":"A macOS notes app"}"#
        try await withSession(responses: [.success(question), .success(final)]) { session, store, _ in
            prepare(session)
            await session.submitAnswer("")
            #expect(session.currentQuestion?.question == "Target OS?")
            #expect(session.draft.step == .interview)
            #expect(session.turns.count == 1)

            await session.submitAnswer("macOS")
            #expect(session.draft.interviewComplete)
            #expect(session.completedSummary == "A macOS notes app")
            #expect(session.currentQuestion == nil)
            #expect(session.draft.step == .specification)
            let storedTurns = try store.turns(projectID: ProjectIdentityLogic.projectID(for: session.projectPath))
            #expect(storedTurns.count == 3)

            let second = SpecWizardSession(
                projectPath: session.projectPath,
                projectName: "Notes",
                database: try ProjectDatabaseManager.manager(forProjectPath: session.projectPath),
                providerID: "test-provider",
                planner: SpecPlannerService(provider: SessionFakeProvider(responses: [])),
                routeProvider: { .autoFree(model: $0) }
            )
            #expect(second.draft.interviewComplete)
            #expect(second.turns.count == 3)
            #expect(second.completedSummary == "A macOS notes app")
        }
    }

    @Test("Specification and decomposition are stored as immutable rows")
    @MainActor
    func specificationAndDecomposition() async throws {
        let spec = "# Notes\n\nBuild an offline notes app."
        let decomposition = """
        {"nodes":[
          {"key":"N1","title":"Storage","description":"Local store","kind":"task",
           "acceptance_criteria":["Survives restart"],"depends_on":[]},
          {"key":"N2","title":"Editor","description":"Text editor","kind":"task",
           "acceptance_criteria":["Edits text"],"depends_on":["N1"]}
        ]}
        """
        try await withSession(responses: [.success(spec), .success(decomposition)]) { session, store, provider in
            prepare(session)
            session.draft.interviewComplete = true
            #expect(session.saveDraft())

            await session.generateSpecification()
            #expect(session.errorMessage == nil)
            #expect(session.draft.specVersion == 1)
            #expect(session.latestRevision?.contentMarkdown == spec)
            #expect(provider.requests.count == 1)

            await session.generateDecomposition()
            #expect(session.errorMessage == nil)
            #expect(session.nodes.count == 2)
            #expect(session.draft.decompositionNodeCount == 2)
            #expect(session.draft.step == .ready)
            let revisionID = try #require(session.latestRevision?.id)
            #expect(try store.edges(revisionID: revisionID).count == 1)
            let editor = try #require(session.nodes.first { $0.externalKey == "N2" })
            #expect(session.dependencies(of: editor).map(\.externalKey) == ["N1"])
            #expect(session.finishWizard(forced: false))
            #expect(session.draft.status == .complete)
        }
    }

    @Test("A new specification revision starts a fresh decomposition")
    @MainActor
    func newRevisionResetsDecomposition() async throws {
        let first = "# Version one"
        let second = "# Version two"
        let decomposition = """
        {"nodes":[{"key":"N1","title":"One","description":"Do it","kind":"task",
        "acceptance_criteria":["Works"],"depends_on":[]}]}
        """
        try await withSession(responses: [.success(first), .success(decomposition), .success(second)]) { session, store, _ in
            prepare(session)
            session.draft.interviewComplete = true
            #expect(session.saveDraft())

            await session.generateSpecification()
            await session.generateDecomposition()
            let firstRevisionID = try #require(session.latestRevision?.id)
            #expect(session.nodes.count == 1)

            await session.generateSpecification()
            #expect(session.draft.specVersion == 2)
            #expect(session.nodes.isEmpty)
            #expect(session.draft.decompositionNodeCount == 0)
            #expect(session.draft.step == .decomposition)
            #expect(try store.nodes(revisionID: firstRevisionID).count == 1)
        }
    }

    @Test("Forced finish persists without faking a decomposition")
    @MainActor
    func forcedFinish() async throws {
        try await withSession(responses: []) { session, _, _ in
            prepare(session)
            #expect(!session.finishWizard(forced: false))
            #expect(session.errorMessage != nil)
            #expect(session.finishWizard(forced: true))
            #expect(session.draft.status == .forced)

            let raw = try #require(try session.databaseValueForTesting(key: "spec_wizard_draft"))
            let decoded = try JSONDecoder().decode(SpecWizardDraft.self, from: Data(raw.utf8))
            #expect(decoded.status == .forced)
            #expect(decoded.interviewComplete == false)
            #expect(decoded.decompositionNodeCount == 0)
        }
    }
}

private extension SpecWizardSession {
    func databaseValueForTesting(key: String) throws -> String? {
        try ProjectDatabaseManager.manager(forProjectPath: projectPath).metadataValue(forKey: key)
    }
}
