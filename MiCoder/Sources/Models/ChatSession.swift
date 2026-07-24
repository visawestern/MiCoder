import Foundation

struct ChatSession: Identifiable {
    let id: String
    var title: String
    var messages: [Message]
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
    var directory: String
    var branch: String?
    var gitSummary: MimoSessionSummary?
    /// Current session goal set via /goal, shown in the TopBar (plan Раздел 5 Блок 1 п.8).
    var sessionGoal: String?
    
    init(
        id: String = UUID().uuidString,
        title: String = "New Chat",
        messages: [Message] = [],
        isActive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        directory: String = "",
        branch: String? = nil,
        gitSummary: MimoSessionSummary? = nil,
        sessionGoal: String? = nil
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.directory = directory
        self.branch = branch
        self.gitSummary = gitSummary
        self.sessionGoal = sessionGoal
    }
    
    var durationLabel: String {
        Self.durationLabel(since: updatedAt)
    }
    
    func belongs(to workspace: Workspace) -> Bool {
        Self.normalizedPath(directory) == Self.normalizedPath(workspace.path)
    }
    
    static func durationLabel(since date: Date, now: Date = Date()) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        if seconds < 60 { return "\(max(1, seconds))s" }
        
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m" }
        
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        
        let days = hours / 24
        return "\(days)d"
    }
    
    static func normalizedPath(_ path: String) -> String {
        (path as NSString).standardizingPath
    }
}
