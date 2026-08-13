import Foundation

/// Extracts the real model list from a vendor's web model-dropdown
/// (plan Раздел 13 п.4). The browser layer reads the dropdown's option texts
/// (via BrowserAutomationBridge.readText on the model-dropdown selector) and
/// passes them here; this pure logic cleans/normalizes them into model ids.
/// No hardcoded guesses — if parsing yields nothing, the caller keeps the empty
/// list and the UI falls back to vendor defaults only as a last resort.
enum WebModelListParser {
    /// Parse newline/pipe-separated option labels captured from the dropdown
    /// into a de-duplicated, ordered list of model names.
    static func parse(dropdownText: String, vendor: WebChatVendor) -> [String] {
        let separators = CharacterSet(charactersIn: "\n|,")
        let rawTokens = dropdownText
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var seen = Set<String>()
        var result: [String] = []
        for token in rawTokens {
            guard let name = normalize(token, vendor: vendor) else { continue }
            if seen.contains(name.lowercased()) { continue }
            seen.insert(name.lowercased())
            result.append(name)
        }
        if vendor == .chatgpt {
            return result.filter { isChatGPTModelLabel($0) }
        }
        return result
    }

    /// Normalize a single dropdown label into a model name, or nil if it's UI
    /// chrome (checkmarks, "New", "Upgrade", empty, badges).
    static func normalize(_ raw: String, vendor: WebChatVendor) -> String? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        // Strip leading selection markers / emojis commonly present in web menus.
        for prefix in ["✓", "✔", "•", "- ", "* "] {
            if s.hasPrefix(prefix) { s.removeFirst(prefix.count); s = s.trimmingCharacters(in: .whitespaces) }
        }
        // Drop obvious non-model UI entries.
        let lower = s.lowercased()
        let noise = ["new", "upgrade", "plus", "pro plan", "manage", "settings",
                     "see all", "more", "beta", "coming soon", "sign in", "log in"]
        if noise.contains(lower) { return nil }
        // Must contain at least one letter and be reasonably short.
        guard s.rangeOfCharacter(from: .letters) != nil, s.count <= 60 else { return nil }
        return s
    }

    /// ChatGPT's model switcher can contain feature actions beside model
    /// options. Keep those actions out of the composer model list.
    private static func isChatGPTModelLabel(_ label: String) -> Bool {
        let lower = label.lowercased()
        if lower == "chatgpt" { return false }
        let featureLabels = [
            "deep research", "research", "image", "images", "canvas", "agent",
            "search", "study", "shopping", "tasks", "projects", "voice"
        ]
        if featureLabels.contains(where: { lower.contains($0) }) { return false }
        return lower.contains("gpt")
            || lower.hasPrefix("o1")
            || lower.hasPrefix("o3")
            || lower.hasPrefix("o4")
            || lower == "auto"
    }

    
    /// Parse effort/thinking/reasoning levels from a dropdown text.
    static func parseEffortLevels(dropdownText: String, vendor: WebChatVendor) -> [WebEffort] {
        let separators = CharacterSet(charactersIn: "\n|,")
        let rawTokens = dropdownText
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var seen = Set<WebEffort>()
        var result: [WebEffort] = []
        for token in rawTokens {
            guard let effort = normalizeEffort(token, vendor: vendor) else { continue }
            if seen.contains(effort) { continue }
            seen.insert(effort)
            result.append(effort)
        }
        return result
    }

    /// Normalize a single dropdown label into an effort level, or nil if it's UI chrome.
    static func normalizeEffort(_ raw: String, vendor: WebChatVendor) -> WebEffort? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        // Strip leading selection markers / emojis commonly present in web menus.
        for prefix in ["✓", "✔", "•", "- ", "* "] {
            if s.hasPrefix(prefix) { s.removeFirst(prefix.count); s = s.trimmingCharacters(in: .whitespaces) }
        }
        // Drop obvious non-effort UI entries (but NOT "auto"/"Авто" — it's a valid effort level).
        let lower = s.lowercased()
        let noise = ["new", "upgrade", "plus", "pro plan", "manage", "settings",
                     "see all", "more", "beta", "coming soon", "sign in", "log in",
                     "default", "balanced", "creative", "precise"]
        if noise.contains(lower) { return nil }
        // Map vendor-specific labels to WebEffort (English + Chinese + Russian)
        switch vendor {
        case .kimi:
            if lower.contains("thinking") || lower.contains("深度") || lower.contains("推理") || lower.contains("мышлен") || lower.contains("мышлени") || lower.contains("высок") || lower.contains("глубок") {
                return .high
            }
            if lower.contains("快速") || lower.contains("快") || lower.contains("fast") || lower.contains("быстр") {
                return .low
            }
            return .medium
        case .qwen:
            if lower.contains("deep") || lower.contains("深度") || lower.contains("推理") || lower.contains("thinking") || lower.contains("мышлен") || lower.contains("мышлени") || lower.contains("высок") || lower.contains("глубок") {
                return .high
            }
            if lower.contains("快") || lower.contains("fast") || lower.contains("速度") || lower.contains("быстр") {
                return .low
            }
            return .medium
        case .chatgpt:
            if lower.contains("high") || lower.contains("高") || lower.contains("pro") {
                return .high
            }
            if lower.contains("low") || lower.contains("低") || lower.contains("快") {
                return .low
            }
            if lower.contains("medium") || lower.contains("中") || lower.contains("balanced") {
                return .medium
            }
            return .medium
        case .custom:
            if lower.contains("high") || lower.contains("高") || lower.contains("pro") || lower.contains("deep") || lower.contains("thinking") || lower.contains("мышлен") {
                return .high
            }
            if lower.contains("low") || lower.contains("低") || lower.contains("快") || lower.contains("speed") || lower.contains("быстр") {
                return .low
            }
            return .medium
        }
    }

    /// Merge freshly parsed models into a config, preserving user selection if
    /// still present (plan Раздел 13 п.4).
    static func updated(_ config: WebProviderConfig, withDropdownText text: String) -> WebProviderConfig {
        var updated = config
        let modelNames = parse(dropdownText: text, vendor: config.vendor)
        if !modelNames.isEmpty {
            updated.discoveredModels = modelNames.map { WebProviderModel(name: $0) }
        }
        return updated
    }
}
