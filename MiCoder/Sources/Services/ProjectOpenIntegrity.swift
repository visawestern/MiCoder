import Foundation

/// Result of an open-time integrity check (plan Раздел 8 п.48).
enum ProjectOpenIntegrityResult: Equatable {
    case ok
    /// The database file exists but could not be read/validated.
    case corrupt(String)
}

/// Presented when a project's database fails its open-time integrity check.
/// Identifiable so SwiftUI can drive an `.alert(item:)` offer to restore.
struct ProjectIntegrityAlert: Identifiable, Equatable {
    let id = UUID()
    let projectPath: String
    let message: String
}

/// Open-time integrity checking + restore-from-backup (E04, plan Раздел 8 п.48).
/// Runs on every project open: a corrupted `project.db` must be detected at
/// open time (not silently crash or serve stale data), and the newest auto
/// backup must be offered for restore. Foundation-only + real SQLite so it is
/// fully testable against temp project directories.
enum ProjectOpenIntegrity {

    /// Verifies the project's database at open time. A missing database file
    /// is NOT corruption (first open creates it). When the file exists but
    /// cannot be opened/validated, `.corrupt` carries the underlying reason.
    static func checkOnOpen(projectPath: String) -> ProjectOpenIntegrityResult {
        let dbURL = ProjectDatabaseLocator.databaseURL(projectPath: projectPath)
        guard FileManager.default.fileExists(atPath: dbURL.path) else { return .ok }
        do {
            let manager = try ProjectDatabaseManager.manager(forProjectPath: projectPath)
            if let corruption = try manager.integrityCheck() {
                return .corrupt(corruption)
            }
            return .ok
        } catch {
            return .corrupt(error.localizedDescription)
        }
    }

    /// Restores the newest auto-backup over the (corrupt) `project.db`.
    /// Drops the pooled connection first so the restored file is read fresh,
    /// and removes stale `-journal`/`-wal` sidecars that could replay old
    /// garbage. Returns the backup URL, or nil when no backup exists.
    @discardableResult
    static func restoreLatestBackup(projectPath: String) throws -> URL? {
        ProjectDatabaseManager.evictProject(projectPath: projectPath)
        guard let newest = try ProjectAutoBackupLogic.listBackups(projectPath: projectPath).first else {
            return nil
        }
        let dbURL = ProjectDatabaseLocator.databaseURL(projectPath: projectPath)
        // Remove the corrupt file and its sidecars so SQLite starts clean.
        for sidecar in [dbURL, dbURL.appendingPathExtension("journal"), dbURL.appendingPathExtension("wal")] {
            try? FileManager.default.removeItem(at: sidecar)
        }
        try FileManager.default.createDirectory(at: dbURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: newest, to: dbURL)
        return newest
    }
}
