import Foundation

/// Sidebar grouping mode toggled by the Group/Project pill (plan Раздел 11
/// Блок 2 п.11-13). Pure enum + persistence key so the UI stays thin.
enum SidebarGroupingMode: String, Codable, CaseIterable, Identifiable {
    /// Group tasks by workspace/project with a `#` badge (default).
    case group
    /// Focus a single selected project, others collapsed.
    case project

    var id: String { rawValue }

    var label: String {
        switch self {
        case .group: return "Group"
        case .project: return "Project"
        }
    }

    var icon: String {
        switch self {
        case .group: return "number"
        case .project: return "folder"
        }
    }
}

enum SidebarGroupingLogic {
    static let storageKey = "com.micoder.sidebarGroupingMode"

    static func load(defaults: UserDefaults = .standard) -> SidebarGroupingMode {
        guard let raw = defaults.string(forKey: storageKey),
              let mode = SidebarGroupingMode(rawValue: raw) else { return .group }
        return mode
    }

    static func save(_ mode: SidebarGroupingMode, defaults: UserDefaults = .standard) {
        defaults.set(mode.rawValue, forKey: storageKey)
    }

    /// Relative-time label for a task row (plan Блок 2 п.23): "now", "11h",
    /// "1d", "9d". Given the elapsed seconds since the task's last activity.
    static func relativeTimeLabel(elapsedSeconds: TimeInterval) -> String {
        let s = max(0, elapsedSeconds)
        if s < 60 { return "now" }
        let minutes = Int(s / 60)
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        let days = hours / 24
        return "\(days)d"
    }
}
