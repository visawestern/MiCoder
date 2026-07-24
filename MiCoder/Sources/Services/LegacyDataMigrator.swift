import Foundation

/// One-time migration of legacy `~/.mimocode` data to `~/.micoder` after the
/// rebrand (plan Раздел 13 п.11). Runs at most once; never destroys data —
/// copies missing files/dirs and records completion so it doesn't re-run.
enum LegacyDataMigrator {
    static let completionFlagKey = "com.micoder.legacyMigrationDone"
    static let legacyDirName = ".mimocode"
    static let currentDirName = ".micoder"

    /// Whether migration should run: legacy dir exists, current dir absent (or
    /// empty), and not already done.
    static func shouldMigrate(homeDirectory: URL,
                             defaults: UserDefaults = .standard,
                             fileManager: FileManager = .default) -> Bool {
        if defaults.bool(forKey: completionFlagKey) { return false }
        let legacy = homeDirectory.appendingPathComponent(legacyDirName)
        guard fileManager.fileExists(atPath: legacy.path) else { return false }
        return true
    }

    /// Perform the migration. Copies legacy entries into the current dir only
    /// when the destination does not already exist (never overwrites newer
    /// data). Returns the list of migrated relative paths. Idempotent.
    @discardableResult
    static func migrate(homeDirectory: URL,
                       defaults: UserDefaults = .standard,
                       fileManager: FileManager = .default) throws -> [String] {
        guard shouldMigrate(homeDirectory: homeDirectory, defaults: defaults, fileManager: fileManager) else {
            return []
        }
        let legacy = homeDirectory.appendingPathComponent(legacyDirName)
        let current = homeDirectory.appendingPathComponent(currentDirName)
        try fileManager.createDirectory(at: current, withIntermediateDirectories: true)

        var migrated: [String] = []
        let entries = (try? fileManager.contentsOfDirectory(
            at: legacy, includingPropertiesForKeys: nil, options: [])) ?? []
        for entry in entries {
            let dest = current.appendingPathComponent(entry.lastPathComponent)
            if fileManager.fileExists(atPath: dest.path) { continue }  // keep newer
            try fileManager.copyItem(at: entry, to: dest)
            migrated.append(entry.lastPathComponent)
        }
        defaults.set(true, forKey: completionFlagKey)
        return migrated
    }

    /// Mark done without migrating (e.g. fresh install with no legacy data).
    static func markDone(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: completionFlagKey)
    }
}
