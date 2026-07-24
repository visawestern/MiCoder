import Foundation

/// Pure logic for the three explicit storage-reset scenarios (plan Раздел 8
/// Блок 1 п.10 / Блок 2). Decouples the "what gets cleared" decision from the
/// UI so it is unit-testable without touching real databases.
enum StorageResetScope: Equatable {
    /// (a) Clear the app cache only (`~/.micoder/mimo.db`); keep CLI history.
    case appCacheOnly
    /// (b) Full reset including CLI history (`~/.local/share/mimocode/mimocode.db`);
    ///     requires explicit confirmation because it touches data outside the app.
    case fullIncludingCLI
    /// (c) Clear cache AND disable auto-import from CLI until the user asks.
    case clearNoAutoImport
}

struct StorageResetPlan: Equatable {
    let scope: StorageResetScope
    /// Paths that will be deleted by this scenario.
    let deletesPaths: [String]
    /// Whether auto-import from CLI should be disabled after the reset.
    let disablesAutoImport: Bool
    /// Whether CLI history is also cleared.
    let clearsCLIHistory: Bool
}

enum StorageResetLogic {
    /// Build the concrete plan for a given scope. Paths are relative to the
    /// provided home directory and the CLI storage root.
    static func plan(for scope: StorageResetScope,
                    homeDirectory: URL,
                    cliStorageRoot: URL) -> StorageResetPlan {
        let mimoDB = homeDirectory.appendingPathComponent(".micoder/mimo.db").path
        let cliDB = cliStorageRoot.appendingPathComponent("mimocode/mimocode.db").path
        switch scope {
        case .appCacheOnly:
            return StorageResetPlan(scope: scope, deletesPaths: [mimoDB],
                                    disablesAutoImport: false, clearsCLIHistory: false)
        case .fullIncludingCLI:
            return StorageResetPlan(scope: scope, deletesPaths: [mimoDB, cliDB],
                                    disablesAutoImport: false, clearsCLIHistory: true)
        case .clearNoAutoImport:
            return StorageResetPlan(scope: scope, deletesPaths: [mimoDB],
                                    disablesAutoImport: true, clearsCLIHistory: false)
        }
    }

    /// Whether a scope requires an extra explicit confirmation (plan Блок 1 п.10b).
    static func requiresExtraConfirmation(_ scope: StorageResetScope) -> Bool {
        scope == .fullIncludingCLI
    }

    /// Human-readable summary of what a plan will do (shown in the confirm alert).
    static func summary(for plan: StorageResetPlan) -> String {
        var lines: [String] = []
        lines.append("Paths to delete:")
        lines.append(contentsOf: plan.deletesPaths.map { "  - \($0)" })
        if plan.clearsCLIHistory {
            lines.append("CLI history will also be cleared.")
        }
        if plan.disablesAutoImport {
            lines.append("Auto-import from CLI will be disabled until you re-enable it.")
        }
        return lines.joined(separator: "\n")
    }
}

/// Normalizes project/session identifiers to fix the "pile of UUIDs" root cause
/// (plan Раздел 8 Блок 1 п.4 / Блок 2 п.17). A project id is the canonicalized
/// absolute path; a session id is a stable UUID minted once.
enum IdentifierNormalization {
    /// Canonicalize a project path to a stable id (resolve symlinks, strip trailing slash).
    static func projectID(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let standardized = url.standardizedFileURL.path
        return standardized.hasSuffix("/") ? String(standardized.dropLast()) : standardized
    }

    /// True if two raw paths refer to the same canonical project.
    static func sameProject(_ a: String, _ b: String) -> Bool {
        projectID(for: a) == projectID(for: b)
    }
}
