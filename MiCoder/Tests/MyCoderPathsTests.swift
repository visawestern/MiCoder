import Testing
import Foundation
@testable import MiCoder

@Suite("myCoder paths + legacy migration (rename/mycoder R1)")
struct MyCoderPathsTests {

    @Test func appDirNameIsMycoder() {
        #expect(MyCoderPaths.appDirName == ".mycoder")
    }

    @Test func bundlePrefixIsMycoder() {
        #expect(MyCoderPaths.bundlePrefix == "com.mycoder")
    }

    @Test func legacyDirNameIsMicoder() {
        #expect(MyCoderPaths.legacyAppDirName == ".micoder")
    }

    @Test func registryPathUsesMycoder() {
        let home = URL(fileURLWithPath: "/tmp/fake-home")
        let url = MyCoderPaths.registryURL(homeDirectory: home)
        #expect(url.path == "/tmp/fake-home/.mycoder/projects.json")
    }

    @Test func projectDataDirUsesMycoder() {
        let url = MyCoderPaths.projectDataDir(projectPath: "/p/x")
        #expect(url.path == "/p/x/.mycoder")
    }

    @Test func migrationPlanMovesMicoderToMycoder() {
        let fm = FileManager.default
        let home = fm.temporaryDirectory.appendingPathComponent("mycoder-r1-\(UUID().uuidString)", isDirectory: true)
        try! fm.createDirectory(at: home.appendingPathComponent(".micoder"), withIntermediateDirectories: true)
        let plan = MyCoderPaths.migrationPlan(homeDirectory: home, fileManager: fm)
        #expect(plan.needsMigration == true)
        #expect(plan.legacyURL.lastPathComponent == ".micoder")
        #expect(plan.targetURL.lastPathComponent == ".mycoder")
    }

    @Test func noMigrationWhenAlreadyMycoder() {
        let fm = FileManager.default
        let home = fm.temporaryDirectory.appendingPathComponent("mycoder-r1-\(UUID().uuidString)", isDirectory: true)
        try! fm.createDirectory(at: home.appendingPathComponent(".mycoder"), withIntermediateDirectories: true)
        let plan = MyCoderPaths.migrationPlan(homeDirectory: home, fileManager: fm)
        #expect(plan.needsMigration == false)
    }

    @Test func registryLogicUsesMycoderPath() {
        let home = URL(fileURLWithPath: "/tmp/fake-home")
        #expect(ProjectRegistryLogic.registryURL(homeDirectory: home) == MyCoderPaths.registryURL(homeDirectory: home))
    }

    @Test func databaseURLUsesMycoder() {
        let home = URL(fileURLWithPath: "/tmp/fake-home")
        let inProject = ProjectDatabaseManager.resolveDatabaseURL(
            projectPath: "/p/x", homeDirectory: home, attemptCreate: { _ in true })
        #expect(inProject.path == "/p/x/.mycoder/project.db")
        let fallback = ProjectDatabaseManager.resolveDatabaseURL(
            projectPath: "/p/x", homeDirectory: home, attemptCreate: { _ in false })
        #expect(fallback.path.hasPrefix("/tmp/fake-home/.mycoder/projects/"))
        #expect(fallback.lastPathComponent == "project.db")
    }

    @Test func projectDataSubdirsUseMycoder() {
        #expect(MyCoderPaths.snapshotsDir(projectPath: "/p/x").path == "/p/x/.mycoder/snapshots")
        #expect(MyCoderPaths.todosURL(projectPath: "/p/x").path == "/p/x/.mycoder/todos.json")
        #expect(MyCoderPaths.backupsDir(projectPath: "/p/x").path == "/p/x/.mycoder/backups")
    }

    @Test func homeDataSubdirsUseMycoder() {
        let home = URL(fileURLWithPath: "/tmp/fake-home")
        #expect(MyCoderPaths.deletedBackupsDir(homeDirectory: home).path == "/tmp/fake-home/.mycoder/deleted-backups")
        #expect(MyCoderPaths.logsDir(homeDirectory: home).path == "/tmp/fake-home/.mycoder/logs")
    }

    @Test func appDataComponentRecognition() {
        #expect(MyCoderPaths.isAppDataPathComponent(".mycoder") == true)
        #expect(MyCoderPaths.isAppDataPathComponent(".micoder") == true)
        #expect(MyCoderPaths.isAppDataPathComponent(".git") == false)
        #expect(MyCoderPaths.defaultExcludes.contains(".mycoder"))
        #expect(!MyCoderPaths.defaultExcludes.contains(".micoder"))
    }

    @Test func agentResourceDirsUseMycoder() {
        let home = URL(fileURLWithPath: "/tmp/fake-home")
        #expect(MyCoderPaths.skillsDir(homeDirectory: home).path == "/tmp/fake-home/.mycoder/skills")
        #expect(MyCoderPaths.skillDir(id: "demo", homeDirectory: home).path == "/tmp/fake-home/.mycoder/skills/demo")
        #expect(MyCoderPaths.mcpConfigURL(homeDirectory: home).path == "/tmp/fake-home/.mycoder/mcp.json")
        #expect(MyCoderPaths.commandsDir(homeDirectory: home).path == "/tmp/fake-home/.mycoder/commands")
        #expect(MyCoderPaths.pluginsDir(homeDirectory: home).path == "/tmp/fake-home/.mycoder/plugins")
        #expect(MyCoderPaths.webSessionsDir(providerId: "kimi", homeDirectory: home).path == "/tmp/fake-home/.mycoder/web-sessions/kimi")
        #expect(MyCoderPaths.logFile(name: "api-server.log", homeDirectory: home).path == "/tmp/fake-home/.mycoder/logs/api-server.log")
        #expect(MyCoderPaths.skillsRegistryRelativePath == ".mycoder/skills/registry.json")
        #expect(MyCoderPaths.mcpRegistryRelativePath == ".mycoder/mcp/registry.json")
    }

    @Test func defaultsKeysUseMycoderWithLegacyFallback() {
        let suite = "mycoder-r6-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        #expect(MyCoderDefaults.key("theme") == "com.mycoder.theme")
        #expect(MyCoderDefaults.legacyKey("theme") == "com.micoder.theme")
        // Legacy value migrates to canonical on read.
        defaults.set("dark", forKey: "com.micoder.theme")
        #expect(MyCoderDefaults.string("theme", in: defaults) == "dark")
        #expect(defaults.string(forKey: "com.mycoder.theme") == "dark")
        #expect(defaults.object(forKey: "com.micoder.theme") == nil)
    }

    @Test func canonicalKeyWinsOverLegacy() {
        let suite = "mycoder-r6-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("new", forKey: "com.mycoder.theme")
        defaults.set("old", forKey: "com.micoder.theme")
        #expect(MyCoderDefaults.string("theme", in: defaults) == "new")
    }
}
