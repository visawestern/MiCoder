import Foundation

/// Canonical UserDefaults identity for myCoder (rename/mycoder R6).
/// Canonical keys: `com.mycoder.*`. Legacy keys `com.micoder.*` are read
/// through once and migrated: a legacy value moves to the canonical key
/// and the legacy key is removed, so old installs keep their settings
/// without dual-write drift afterwards.
enum MyCoderDefaults {
    static func key(_ suffix: String) -> String {
        MyCoderPaths.bundleKey(suffix)
    }

    static func legacyKey(_ suffix: String) -> String {
        "\(MyCoderPaths.legacyBundlePrefix).\(suffix)"
    }

    /// Read a string: canonical wins; legacy migrates forward on first read.
    static func string(_ suffix: String, in defaults: UserDefaults = .standard) -> String? {
        let canonical = key(suffix)
        if let value = defaults.string(forKey: canonical) {
            return value
        }
        let legacy = legacyKey(suffix)
        guard let value = defaults.string(forKey: legacy) else { return nil }
        defaults.set(value, forKey: canonical)
        defaults.removeObject(forKey: legacy)
        return value
    }

    /// Write straight to the canonical key.
    static func set(_ value: String, _ suffix: String, in defaults: UserDefaults = .standard) {
        defaults.set(value, forKey: key(suffix))
    }

    /// All known settings suffixes, so a one-time startup migration can
    /// carry every legacy `com.micoder.*` value forward. Keep in sync when
    /// adding new `com.mycoder.*` keys.
    static let knownSuffixes: [String] = [
        "theme", "accessLevel", "selectedVariant", "agentMode",
        "selectedModel", "selectedProviderID", "preferredProviderID",
        "preferredModelID", "thinkingLevel", "customProviders",
        "lastWorkspaceID", "settings", "webProviders",
        "webRemoteChatMappings", "modelCallParameters",
        "localProviders",
        "autoFree.model", "autoFree.locked", "autoFree.systemPrompt",
        "webBrowserActionJournal", "disabledCommands",
    ]

    /// Settings that no longer exist. Their legacy and canonical keys are
    /// dropped during migration so a removed feature leaves nothing behind
    /// (the sidebar Group/Project mode was removed in F71).
    static let retiredSuffixes: [String] = [
        "sidebarGroupingMode",
    ]

    /// One-time migration: copy every present legacy value to its canonical
    /// key (canonical wins on conflict), then drop the legacy key.
    /// Returns the number of migrated keys.
    @discardableResult
    static func migrateAllKnownKeys(in defaults: UserDefaults = .standard) -> Int {
        var migrated = 0
        for suffix in knownSuffixes {
            let canonical = key(suffix)
            let legacy = legacyKey(suffix)
            guard let value = defaults.object(forKey: legacy) else { continue }
            if defaults.object(forKey: canonical) == nil {
                defaults.set(value, forKey: canonical)
            }
            defaults.removeObject(forKey: legacy)
            migrated += 1
        }
        // Per-model tool-result fix flags are dynamic (`…toolResultFix.<modelID>`);
        // migrate any stragglers by prefix scan.
        for (k, v) in defaults.dictionaryRepresentation() where k.hasPrefix("\(MyCoderPaths.legacyBundlePrefix).") {
            let suffix = String(k.dropFirst(MyCoderPaths.legacyBundlePrefix.count + 1))
            let canonical = key(suffix)
            if defaults.object(forKey: canonical) == nil {
                defaults.set(v, forKey: canonical)
            }
            defaults.removeObject(forKey: k)
            migrated += 1
        }
        // Removed settings: drop both the canonical and the legacy key.
        for suffix in retiredSuffixes {
            defaults.removeObject(forKey: key(suffix))
            defaults.removeObject(forKey: legacyKey(suffix))
        }
        return migrated
    }
}
