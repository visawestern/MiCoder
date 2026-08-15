import Testing
@testable import MiCoder

@Suite("Legacy database maintenance safety")
struct DatabaseManagerMaintenanceTests {
    @Test("negative archive age fails closed instead of archiving current sessions")
    func negativeArchiveAgeDoesNotArchiveCurrentSession() throws {
        let db = DatabaseManager.createInMemory()
        try db.insertSession(
            id: "session-1",
            projectId: "project-1",
            title: "Current",
            directory: "/tmp/project-1"
        )

        try db.archiveSessionsOlderThan(days: -1)

        let sessions = try db.getAllSessionsAcrossProjects()
        #expect(sessions.count == 1)
        #expect(sessions[0].isArchived == false)
    }

    @Test("negative delete age fails closed instead of deleting current sessions")
    func negativeDeleteAgeDoesNotDeleteCurrentSession() throws {
        let db = DatabaseManager.createInMemory()
        try db.insertSession(
            id: "session-2",
            projectId: "project-2",
            title: "Current",
            directory: "/tmp/project-2"
        )

        #expect(try db.deleteSessionsOlderThan(days: -1) == 0)
        #expect(try db.getAllSessionsAcrossProjects().count == 1)
    }
}
