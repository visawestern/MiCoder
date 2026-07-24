import Foundation

/// A session entry as returned by `mimo session list --format json`.
///
/// Unlike the `/experimental/session` HTTP endpoint (which only reflects
/// sessions known to the currently connected `mimo serve` instance for its
/// own project), this reads mimo's global session database
/// (`~/.local/share/mimocode/mimocode.db`) and spans every project/directory
/// the user has ever run mimo in on this machine.
struct MimoCLISessionEntry: Codable, Sendable, Equatable {
    let id: String
    let title: String
    let updated: Int64
    let created: Int64
    let projectId: String?
    let directory: String
}

extension MimoCLISessionEntry {
    func toChatSession() -> ChatSession {
        ChatSession(
            id: id,
            title: title,
            createdAt: Date(timeIntervalSince1970: TimeInterval(created) / 1000),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(updated) / 1000),
            directory: directory
        )
    }
}
