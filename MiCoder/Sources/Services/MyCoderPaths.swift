import Foundation

/// Canonical myCoder filesystem identity (rename/mycoder R1).
/// New canonical dir: `~/.mycoder` + `<project>/.mycoder`.
/// Legacy dir: `~/.micoder` (migrated once, never written to afterwards).
enum MyCoderPaths {
    static let appDirName = ".mycoder"
    static let legacyAppDirName = ".micoder"
    static let bundlePrefix = "com.mycoder"
    static let legacyBundlePrefix = "com.micoder"

    struct MigrationPlan: Equatable {
        let legacyURL: URL
        let targetURL: URL
        let needsMigration: Bool
    }

    static func appDir(homeDirectory: URL) -> URL {
        homeDirectory.appendingPathComponent(appDirName, isDirectory: true)
    }

    static func legacyAppDir(homeDirectory: URL) -> URL {
        homeDirectory.appendingPathComponent(legacyAppDirName, isDirectory: true)
    }

    static func registryURL(homeDirectory: URL) -> URL {
        appDir(homeDirectory: homeDirectory).appendingPathComponent("projects.json")
    }

    static func projectDataDir(projectPath: String) -> URL {
        URL(fileURLWithPath: projectPath).appendingPathComponent(appDirName, isDirectory: true)
    }

    static func snapshotsDir(projectPath: String) -> URL {
        projectDataDir(projectPath: projectPath).appendingPathComponent("snapshots", isDirectory: true)
    }

    static func todosURL(projectPath: String) -> URL {
        projectDataDir(projectPath: projectPath).appendingPathComponent("todos.json")
    }

    static func backupsDir(projectPath: String) -> URL {
        projectDataDir(projectPath: projectPath).appendingPathComponent("backups", isDirectory: true)
    }

    static func deletedBackupsDir(homeDirectory: URL) -> URL {
        appDir(homeDirectory: homeDirectory).appendingPathComponent("deleted-backups", isDirectory: true)
    }

    static func logsDir(homeDirectory: URL) -> URL {
        appDir(homeDirectory: homeDirectory).appendingPathComponent("logs", isDirectory: true)
    }

    /// True for both the canonical dir and the legacy one, so watchers,
    /// indexers and gitignore logic keep ignoring migrated-but-unmoved dirs.
    static func isAppDataPathComponent(_ component: String) -> Bool {
        component == appDirName || component == legacyAppDirName
    }

    /// Indexer excludes: canonical name only (legacy dirs are migrated away,
    /// but `isAppDataPathComponent` still guards un-migrated ones at runtime).
    static let defaultExcludes: [String] = [
        ".git", "node_modules", ".build", "DerivedData", ".mycoder",
        "dist", "build", ".next", ".venv", "venv", "__pycache__", ".idea", ".swiftpm"
    ]

    static func bundleKey(_ suffix: String) -> String {
        "\(bundlePrefix).\(suffix)"
    }

    /// Pure decision: migrate iff legacy dir exists and target does not.
    /// Both existing → no move (operator resolves); neither → nothing to do.
    static func migrationPlan(homeDirectory: URL, fileManager: FileManager = .default) -> MigrationPlan {
        let legacy = legacyAppDir(homeDirectory: homeDirectory)
        let target = appDir(homeDirectory: homeDirectory)
        var isDirLegacy: ObjCBool = false
        var isDirTarget: ObjCBool = false
        let legacyExists = fileManager.fileExists(atPath: legacy.path, isDirectory: &isDirLegacy) && isDirLegacy.boolValue
        let targetExists = fileManager.fileExists(atPath: target.path, isDirectory: &isDirTarget) && isDirTarget.boolValue
        return MigrationPlan(legacyURL: legacy, targetURL: target, needsMigration: legacyExists && !targetExists)
    }

    /// Execute a previously computed plan: move legacy → target atomically.
    /// Returns true when a move happened; false when nothing to do.
    @discardableResult
    static func performMigration(_ plan: MigrationPlan, fileManager: FileManager = .default) throws -> Bool {
        guard plan.needsMigration else { return false }
        try fileManager.moveItem(at: plan.legacyURL, to: plan.targetURL)
        return true
    }
}
