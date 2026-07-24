import Foundation

/// Persists and restores web-chat browser sessions (cookies + storage) so a
/// session survives app restarts and doesn't drop (plan Раздел 12 Блок 3 п.30).
/// Cookie store lives at ~/.micoder/web-sessions/<providerId>/cookies.json.
/// (Sensitive tokens should additionally go to Keychain in the app layer; this
/// pure manager handles the on-disk cookie store and expiry logic.)
struct WebSessionStore: Codable, Equatable {
    var cookies: [BrowserCookie]
    var localStorage: [String: String]
    var savedAt: Date
}

enum WebSessionManager {
    static func storeURL(providerId: String, homeDirectory: URL) -> URL {
        homeDirectory
            .appendingPathComponent(".micoder/web-sessions/\(providerId)", isDirectory: true)
            .appendingPathComponent("cookies.json")
    }

    static func persist(_ store: WebSessionStore,
                       providerId: String,
                       homeDirectory: URL,
                       fileManager: FileManager = .default) throws {
        let url = storeURL(providerId: providerId, homeDirectory: homeDirectory)
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(store).write(to: url, options: .atomic)
    }

    static func restore(providerId: String,
                       homeDirectory: URL,
                       fileManager: FileManager = .default) -> WebSessionStore? {
        let url = storeURL(providerId: providerId, homeDirectory: homeDirectory)
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WebSessionStore.self, from: data)
    }

    static func clear(providerId: String,
                     homeDirectory: URL,
                     fileManager: FileManager = .default) throws {
        let dir = storeURL(providerId: providerId, homeDirectory: homeDirectory).deletingLastPathComponent()
        if fileManager.fileExists(atPath: dir.path) {
            try fileManager.removeItem(at: dir)
        }
    }

    /// True when the stored session is expired (all cookies past expiry) — the
    /// app should prompt re-login (plan Блок 3 п.32).
    static func isExpired(_ store: WebSessionStore, now: Date = Date()) -> Bool {
        let expiries = store.cookies.compactMap { $0.expiresEpoch }
        return WebSessionLogic.isSessionExpired(cookieExpiryEpochs: expiries,
                                                now: now.timeIntervalSince1970)
    }
}
