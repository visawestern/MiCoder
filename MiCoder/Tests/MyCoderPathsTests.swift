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
}
