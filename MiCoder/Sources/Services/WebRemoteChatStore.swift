import Foundation

/// Stable local identity for one remote provider conversation.
struct WebRemoteChatKey: Codable, Equatable, Hashable, Sendable {
    let providerID: String
    let activeSessionID: String
    let projectID: String
    let localChatID: String

    var storageKey: String {
        [providerID, activeSessionID, projectID, localChatID]
            .map { $0.isEmpty ? "-" : $0 }
            .joined(separator: "::")
    }
}

struct WebRemoteChatMapping: Codable, Equatable, Sendable {
    let key: WebRemoteChatKey
    let remoteChatID: String
    let remoteURL: String
    var verifiedTitle: String?
    let createdAt: Date
    var lastUsedAt: Date
    var status: String

    init(key: WebRemoteChatKey,
         remoteChatID: String,
         remoteURL: String,
         verifiedTitle: String? = nil,
         createdAt: Date = Date(),
         lastUsedAt: Date = Date(),
         status: String = "verified") {
        self.key = key
        self.remoteChatID = remoteChatID
        self.remoteURL = remoteURL
        self.verifiedTitle = verifiedTitle
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.status = status
    }
}

enum WebRemoteChatStore {
    static let storageKey = "com.micoder.webRemoteChatMappings"

    static func loadAll(defaults: UserDefaults = .standard) -> [String: WebRemoteChatMapping] {
        guard let data = defaults.data(forKey: storageKey),
              let mappings = try? JSONDecoder().decode([String: WebRemoteChatMapping].self, from: data) else {
            return [:]
        }
        return mappings
    }

    static func mapping(for key: WebRemoteChatKey,
                        defaults: UserDefaults = .standard) -> WebRemoteChatMapping? {
        loadAll(defaults: defaults)[key.storageKey]
    }

    static func upsert(_ mapping: WebRemoteChatMapping,
                       defaults: UserDefaults = .standard) {
        var all = loadAll(defaults: defaults)
        all[mapping.key.storageKey] = mapping
        if let data = try? JSONEncoder().encode(all) {
            defaults.set(data, forKey: storageKey)
        }
    }

    static func remove(for key: WebRemoteChatKey,
                       defaults: UserDefaults = .standard) {
        var all = loadAll(defaults: defaults)
        all.removeValue(forKey: key.storageKey)
        if let data = try? JSONEncoder().encode(all) {
            defaults.set(data, forKey: storageKey)
        }
    }

    static func clear(providerID: String,
                      activeSessionID: String? = nil,
                      defaults: UserDefaults = .standard) {
        var all = loadAll(defaults: defaults)
        all = all.filter { _, mapping in
            guard mapping.key.providerID == providerID else { return true }
            guard let activeSessionID else { return false }
            return mapping.key.activeSessionID != activeSessionID
        }
        if let data = try? JSONEncoder().encode(all) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
