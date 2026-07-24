import Testing
import Foundation
@testable import MiCoder

@Suite("Storage reset logic (plan Раздел 8)")
struct StorageResetLogicTests {

    private let home = URL(fileURLWithPath: "/home/user")
    private let cliRoot = URL(fileURLWithPath: "/home/user/.local/share")

    @Test func appCacheOnlyClearsMimoDBOnly() {
        let plan = StorageResetLogic.plan(for: .appCacheOnly, homeDirectory: home, cliStorageRoot: cliRoot)
        #expect(plan.deletesPaths == ["/home/user/.micoder/mimo.db"])
        #expect(!plan.clearsCLIHistory)
        #expect(!plan.disablesAutoImport)
    }

    @Test func fullIncludingCLIClearsBothDBs() {
        let plan = StorageResetLogic.plan(for: .fullIncludingCLI, homeDirectory: home, cliStorageRoot: cliRoot)
        #expect(plan.deletesPaths.contains("/home/user/.micoder/mimo.db"))
        #expect(plan.deletesPaths.contains("/home/user/.local/share/mimocode/mimocode.db"))
        #expect(plan.clearsCLIHistory)
        #expect(!plan.disablesAutoImport)
    }

    @Test func clearNoAutoImportDisablesImport() {
        let plan = StorageResetLogic.plan(for: .clearNoAutoImport, homeDirectory: home, cliStorageRoot: cliRoot)
        #expect(plan.disablesAutoImport)
        #expect(!plan.clearsCLIHistory)
        #expect(plan.deletesPaths == ["/home/user/.micoder/mimo.db"])
    }

    @Test func fullResetRequiresExtraConfirmation() {
        #expect(StorageResetLogic.requiresExtraConfirmation(.fullIncludingCLI))
        #expect(!StorageResetLogic.requiresExtraConfirmation(.appCacheOnly))
        #expect(!StorageResetLogic.requiresExtraConfirmation(.clearNoAutoImport))
    }

    @Test func summaryMentionsAllDeletedPaths() {
        let plan = StorageResetLogic.plan(for: .fullIncludingCLI, homeDirectory: home, cliStorageRoot: cliRoot)
        let s = StorageResetLogic.summary(for: plan)
        #expect(s.contains("mimo.db"))
        #expect(s.contains("mimocode.db"))
        #expect(s.contains("CLI history"))
    }

    @Test func summaryForNoAutoImportMentionsDisabling() {
        let plan = StorageResetLogic.plan(for: .clearNoAutoImport, homeDirectory: home, cliStorageRoot: cliRoot)
        let s = StorageResetLogic.summary(for: plan)
        #expect(s.contains("Auto-import"))
    }

    // MARK: - Identifier normalization (Блок 2 п.17)

    @Test func projectIDStripsTrailingSlash() {
        #expect(IdentifierNormalization.projectID(for: "/foo/bar/") == "/foo/bar")
        #expect(IdentifierNormalization.projectID(for: "/foo/bar") == "/foo/bar")
    }

    @Test func sameProjectMatchesPathsWithTrailingSlash() {
        #expect(IdentifierNormalization.sameProject("/foo/bar", "/foo/bar/"))
    }

    @Test func differentPathsAreDifferentProjects() {
        #expect(!IdentifierNormalization.sameProject("/foo/bar", "/foo/baz"))
    }
}
