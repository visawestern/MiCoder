import Foundation

/// Compact sidebar policy: show the first twelve sessions already sorted by
/// AppState.sessions(for:), while keeping short lists unchanged. The explicit
/// constant makes the UI contract testable and prevents accidental truncation.
enum SidebarSessionLimitLogic {
    static let maximumVisible = 12

    static func visible<T>(_ sessions: [T]) -> [T] {
        Array(sessions.prefix(maximumVisible))
    }
}
