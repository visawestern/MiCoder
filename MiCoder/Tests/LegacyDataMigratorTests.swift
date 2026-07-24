import Testing
import Foundation
@testable import MiCoder

@Suite("Legacy data migration .mimocode -> .micoder (plan Раздел 13 п.11)")
struct LegacyDataMigratorTests {

    private func makeHome() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimo-migrate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "migrate-\(UUID().uuidString)")!
    }

    private func writeLegacy(_ home: URL, file: String, contents: String) throws {
        let legacy = home.appendingPathComponent(".mimocode")
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
        try contents.write(to: legacy.appendingPathComponent(file), atomically: true, encoding: .utf8)
    }

    @Test func migratesLegacyEntries() throws {
        let home = try makeHome(); let d = freshDefaults()
        try writeLegacy(home, file: "mcp.json", contents: "{}")
        let migrated = try LegacyDataMigrator.migrate(homeDirectory: home, defaults: d)
        #expect(migrated.contains("mcp.json"))
        let dest = home.appendingPathComponent(".micoder/mcp.json")
        #expect(FileManager.default.fileExists(atPath: dest.path))
    }

    @Test func doesNotOverwriteExistingCurrentData() throws {
        let home = try makeHome(); let d = freshDefaults()
        try writeLegacy(home, file: "mcp.json", contents: "LEGACY")
        // Pre-existing current file must be kept.
        let cur = home.appendingPathComponent(".micoder")
        try FileManager.default.createDirectory(at: cur, withIntermediateDirectories: true)
        try "NEW".write(to: cur.appendingPathComponent("mcp.json"), atomically: true, encoding: .utf8)

        try LegacyDataMigrator.migrate(homeDirectory: home, defaults: d)
        let content = try String(contentsOf: cur.appendingPathComponent("mcp.json"), encoding: .utf8)
        #expect(content == "NEW")   // not overwritten
    }

    @Test func runsOnlyOnce() throws {
        let home = try makeHome(); let d = freshDefaults()
        try writeLegacy(home, file: "a.txt", contents: "x")
        let first = try LegacyDataMigrator.migrate(homeDirectory: home, defaults: d)
        #expect(!first.isEmpty)
        // Add another legacy file, but migration already marked done → no re-run.
        try writeLegacy(home, file: "b.txt", contents: "y")
        let second = try LegacyDataMigrator.migrate(homeDirectory: home, defaults: d)
        #expect(second.isEmpty)
    }

    @Test func noLegacyDirMeansNoMigration() throws {
        let home = try makeHome(); let d = freshDefaults()
        #expect(!LegacyDataMigrator.shouldMigrate(homeDirectory: home, defaults: d))
        #expect(try LegacyDataMigrator.migrate(homeDirectory: home, defaults: d).isEmpty)
    }

    @Test func markDonePreventsMigration() throws {
        let home = try makeHome(); let d = freshDefaults()
        try writeLegacy(home, file: "a.txt", contents: "x")
        LegacyDataMigrator.markDone(defaults: d)
        #expect(!LegacyDataMigrator.shouldMigrate(homeDirectory: home, defaults: d))
    }
}
