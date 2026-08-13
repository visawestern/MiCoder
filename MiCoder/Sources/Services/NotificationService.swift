import Foundation

extension Notification.Name {
    static let miCoderAutoFreeModelSwitched = Notification.Name("MiCoderAutoFreeModelSwitched")
}

// MARK: - Notification Model

struct AppNotification: Identifiable, Equatable {
    let id: String
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: Date
    var isRead: Bool
    var action: NotificationAction?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        message: String,
        type: NotificationType = .info,
        timestamp: Date = Date(),
        isRead: Bool = false,
        action: NotificationAction? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.type = type
        self.timestamp = timestamp
        self.isRead = isRead
        self.action = action
    }
}

enum NotificationType: String, Equatable {
    case info
    case success
    case warning
    case error
    
    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }
    
    var color: String {
        switch self {
        case .info: return "brand"
        case .success: return "success"
        case .warning: return "warning"
        case .error: return "error"
        }
    }
}

enum NotificationAction: Equatable {
    case openSession(String)  // session ID
    case openSettings
    case openGit
    case custom(String)       // URL or action identifier
}

enum MiCoderAutoFreeNotificationLogic {
    static func make(userInfo: [AnyHashable: Any]) -> AppNotification {
        let fromModel = userInfo["fromModel"] as? String ?? "previous model"
        let toModel = userInfo["toModel"] as? String ?? "another free model"
        let reason = userInfo["reason"] as? String ?? "provider error"
        let isRateLimit = reason == "rate limit"
        let title = isRateLimit ? "Free model rate limited" : "Free model switched"
        let message = isRateLimit
            ? "\(fromModel) reached its rate limit. MiCoder switched to \(toModel)."
            : "\(fromModel) was unavailable (\(reason)). MiCoder switched to \(toModel)."
        return AppNotification(title: title, message: message, type: .warning)
    }
}

// MARK: - Notification Service

final class NotificationService: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published private(set) var unreadCount: Int = 0
    
    private let maxNotifications = 50
    
    var sortedNotifications: [AppNotification] {
        notifications.sorted { $0.timestamp > $1.timestamp }
    }
    
    func add(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
        if !notification.isRead {
            unreadCount += 1
        }
        // Enforce max limit
        if notifications.count > maxNotifications {
            notifications = Array(notifications.prefix(maxNotifications))
        }
    }
    
    func markAsRead(_ id: String) {
        guard let index = notifications.firstIndex(where: { $0.id == id }),
              !notifications[index].isRead else { return }
        notifications[index].isRead = true
        unreadCount = max(0, unreadCount - 1)
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        unreadCount = 0
    }
    
    func remove(_ id: String) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            if !notifications[index].isRead {
                unreadCount = max(0, unreadCount - 1)
            }
            notifications.remove(at: index)
        }
    }
    
    func clearAll() {
        notifications.removeAll()
        unreadCount = 0
    }
    
    // MARK: - Convenience Methods
    
    func info(title: String, message: String, action: NotificationAction? = nil) {
        add(AppNotification(title: title, message: message, type: .info, action: action))
    }
    
    func success(title: String, message: String, action: NotificationAction? = nil) {
        add(AppNotification(title: title, message: message, type: .success, action: action))
    }
    
    func warning(title: String, message: String, action: NotificationAction? = nil) {
        add(AppNotification(title: title, message: message, type: .warning, action: action))
    }
    
    func error(title: String, message: String, action: NotificationAction? = nil) {
        add(AppNotification(title: title, message: message, type: .error, action: action))
    }
    
    // MARK: - Task Completion
    
    func taskCompleted(sessionTitle: String, sessionID: String) {
        success(
            title: "Task Complete",
            message: "\"\(sessionTitle)\" has finished processing.",
            action: .openSession(sessionID)
        )
    }
    
    func generationStopped() {
        info(
            title: "Generation Stopped",
            message: L.t("The AI response was stopped by the user.")
        )
    }
    
    func gitOperationComplete(operation: String, details: String) {
        success(
            title: "Git \(operation)",
            message: details,
            action: .openGit
        )
    }
    
    func serverDisconnected() {
        warning(
            title: "Server Disconnected",
            message: L.t("Connection to the local agent was lost.")
        )
    }
    
    func serverConnected() {
        success(
            title: "Server Connected",
            message: L.t("Connected to the local agent successfully.")
        )
    }
    
    func sessionBusy() {
        warning(
            title: "Session Busy",
            message: L.t("The session is processing another request. Please wait or stop current generation.")
        )
    }
}
