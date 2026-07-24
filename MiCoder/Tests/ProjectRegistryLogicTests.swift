import Testing
import Foundation
@testable import MiCoder

@Suite("Project registry admin (plan Раздел 8 Блок 2/3)")
struct ProjectRegistryLogicTests {

    private func makeTempHome() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimo-registry-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test func entryIdIsCanonicalPath() {
        let a = ProjectRegistryEntry(path: "/home/u/proj/")
        let b = ProjectRegistryEntry(path: "/home/u/proj")
        #expect(a.id == b.id)      // trailing slash normalized → dedup works
        #expect(a.name == "proj")
        #expect(!a.autoImportFromCLI)   // default OFF (bug fix)
    }

    @Test func upsertDeduplicatesSamePath() {
        var projects: [ProjectRegistryEntry] = []
        projects = ProjectRegistryLogic.upsert(ProjectRegistryEntry(path: "/p/x"), into: projects)
        projects = ProjectRegistryLogic.upsert(ProjectRegistryEntry(path: "/p/x/"), into: projects)
        #expect(projects.count == 1)   // reopening same folder does NOT duplicate
    }

    @Test func upsertPreservesArchiveAndSettings() {
        var e = ProjectRegistryEntry(path: "/p/x")
        e.archivedAt = Date()
        e.autoImportFromCLI = true
        var projects = [e]
        projects = ProjectRegistryLogic.upsert(ProjectRegistryEntry(path: "/p/x"), into: projects)
        #expect(projects.first?.isArchived == true)          // archive preserved
        #expect(projects.first?.autoImportFromCLI == true)   // settings preserved
    }

    @Test func archiveRestoreDeleteFlow() {
        var projects = [ProjectRegistryEntry(path: "/p/x")]
        let id = projects[0].id
        projects = ProjectRegistryLogic.archive(id: id, at: Date(), in: projects)
        #expect(projects[0].isArchived)
        #expect(ProjectRegistryLogic.active(projects).isEmpty)
        #expect(ProjectRegistryLogic.archived(projects).count == 1)

        projects = ProjectRegistryLogic.restore(id: id, in: projects)
        #expect(!projects[0].isArchived)

        projects = ProjectRegistryLogic.remove(id: id, in: projects)
        #expect(projects.isEmpty)
    }

    @Test func setAutoImportToggles() {
        var projects = [ProjectRegistryEntry(path: "/p/x")]
        let id = projects[0].id
        #expect(!ProjectRegistryLogic.shouldAutoImportFromCLI(projects.first))
        projects = ProjectRegistryLogic.setAutoImportFromCLI(id: id, enabled: true, in: projects)
        #expect(ProjectRegistryLogic.shouldAutoImportFromCLI(projects.first))
    }

    @Test func orphanedDetectsMissingPaths() throws {
        let home = try makeTempHome()
        let realDir = home.appendingPathComponent("real")
        try FileManager.default.createDirectory(at: realDir, withIntermediateDirectories: true)
        let projects = [
            ProjectRegistryEntry(path: realDir.path),
            ProjectRegistryEntry(path: "/definitely/missing/path")
        ]
        let orphans = ProjectRegistryLogic.orphaned(projects)
        #expect(orphans.count == 1)
        #expect(orphans.first?.path == "/definitely/missing/path")
    }

    @Test func inactiveLongerThanFilters() {
        let old = ProjectRegistryEntry(path: "/p/old", lastOpenedAt: Date().addingTimeInterval(-40 * 86400))
        let fresh = ProjectRegistryEntry(path: "/p/fresh", lastOpenedAt: Date())
        let inactive = ProjectRegistryLogic.inactiveLongerThan(days: 30, in: [old, fresh])
        #expect(inactive.count == 1)
        #expect(inactive.first?.name == "old")
    }

    @Test func persistenceRoundTrip() throws {
        let home = try makeTempHome()
        let projects = [
            ProjectRegistryEntry(path: "/p/a", autoImportFromCLI: true),
            ProjectRegistryEntry(path: "/p/b")
        ]
        try ProjectRegistryLogic.save(projects, homeDirectory: home)
        let loaded = ProjectRegistryLogic.load(homeDirectory: home)
        #expect(loaded.count == 2)
        #expect(loaded.first(where: { $0.path == "/p/a" })?.autoImportFromCLI == true)
    }

    @Test func activeSortedByLastOpened() {
        let a = ProjectRegistryEntry(path: "/p/a", lastOpenedAt: Date().addingTimeInterval(-100))
        let b = ProjectRegistryEntry(path: "/p/b", lastOpenedAt: Date())
        let active = ProjectRegistryLogic.active([a, b])
        #expect(active.first?.name == "b")   // most recent first
    }
}
