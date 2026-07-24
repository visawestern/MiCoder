import Foundation

/// One-time migration from the legacy single-file `DatabaseManager`
/// (`~/.micoder/mimo.db`, shared by every project on the machine) into the
/// new per-project `ProjectDatabaseManager` files. Sessions are grouped by
/// their `directory` field; every message and message part attached to a
/// migrated session travels with it so no dialog history is lost.
enum ProjectDatabaseMigrator {

    struct Summary: Equatable {
        var migratedProjectPaths: [String] = []
        var unassignedSessionCount: Int = 0
        var totalSessionsMigrated: Int = 0
        var totalMessagesMigrated: Int = 0
    }

    /// Runs the migration against `legacy`, writing into per-project
    /// databases (resolved through the normal `ProjectDatabaseManager` pool)
    /// or, for sessions with no usable directory, into a dedicated
    /// "unassigned" store rooted at `unassignedBaseDirectory`.
    ///
    /// Idempotent: sessions/messages are upserted by their stable id, so
    /// running migration more than once (e.g. after a partial failure)
    /// never creates duplicates.
    @discardableResult
    static func migrate(
        from legacy: DatabaseManager,
        unassignedBaseDirectory: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".micoder")
    ) throws -> Summary {
        var summary = Summary()
        let allSessions = try legacy.getAllSessionsAcrossProjects()
        let grouped = Dictionary(grouping: allSessions) { ChatSession.normalizedPath($0.directory) }

        for (normalizedPath, sessionGroup) in grouped {
            let targetManager: ProjectDatabaseManager
            let isUnassigned = normalizedPath.isEmpty || !directoryExists(normalizedPath)

            if isUnassigned {
                targetManager = try ProjectDatabaseManager.unassignedManager(baseDirectory: unassignedBaseDirectory)
                summary.unassignedSessionCount += sessionGroup.count
            } else {
                targetManager = try ProjectDatabaseManager.manager(forProjectPath: normalizedPath)
                summary.migratedProjectPaths.append(normalizedPath)
            }

            for session in sessionGroup {
                try targetManager.insertSession(
                    id: session.id,
                    title: session.title,
                    directory: session.directory,
                    branch: session.branch,
                    agentMode: session.agentMode
                )
                summary.totalSessionsMigrated += 1

                let messages = try legacy.getMessagesBySession(sessionId: session.id)
                for message in messages {
                    try targetManager.insertMessage(
                        id: message.id,
                        sessionId: message.sessionId,
                        role: message.role,
                        content: message.content,
                        reasoning: message.reasoning,
                        isFinished: message.isFinished
                    )
                    summary.totalMessagesMigrated += 1

                    let parts = try legacy.getMessageParts(messageId: message.id)
                    for part in parts {
                        try targetManager.insertMessagePart(
                            id: part.id,
                            messageId: part.messageId,
                            type: part.type,
                            content: part.content,
                            toolName: part.toolName,
                            toolArgs: part.toolArgs,
                            toolResult: part.toolResult,
                            toolCallId: part.toolCallId,
                            sequenceOrder: part.sequenceOrder
                        )
                    }
                }
            }
        }

        return summary
    }

    private static func directoryExists(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
