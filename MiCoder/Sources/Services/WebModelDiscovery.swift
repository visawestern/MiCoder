import Foundation

// ═══════════════════════════════════════════════════════════════════════════
// Round 9 — Web model discovery from the actual page (TDD implementation).
//
// Discovery uses the vendor-specific selectors from
// `web_providers_catalog.json`, not hardcoded strings. Failure to discover
// is surfaced explicitly instead of silently falling back to vendor
// defaults, so stale hardcoded lists are never presented as live.
// ═══════════════════════════════════════════════════════════════════════════

/// Catalog JSON structure for one vendor entry.
    private struct WebVendorCatalogEntryDTO: Decodable {
        let id: String
        let models: [String]?
        let selectors: Selectors
        struct Selectors: Decodable {
            let input: String?
            let sendButton: String?
            let responseContainer: String?
            let stopButton: String?
            let modelDropdown: String?
            let effortDropdown: String?
            let modelButton: String?
            let modelItem: String?
            let newChatTexts: [String]?
            let modeSelect: String?
            let thinkingSelect: String?
            let effortItem: String?
            let modeItem: String?
        }
    }

/// Catalog-backed selectors/URLs for each web-chat vendor.
/// Source of truth: `MiCoder/Sources/Resources/Catalog/web_providers_catalog.json`
struct WebProviderCatalog {
    struct VendorEntry: Equatable {
        let id: String
        let models: [String]
        let input: String?
        let sendButton: String?
        let responseContainer: String?
        let stopButton: String?
        let modelDropdown: String
        let effortDropdown: String?
        let modelButton: String?
        let modelItem: String?
        let newChatTexts: [String]?
        let modeSelect: String?
        let thinkingSelect: String?
        let effortItem: String?
        let modeItem: String?
    }

    private struct RootDTO: Decodable { let vendors: [WebVendorCatalogEntryDTO] }

    private let entries: [String: VendorEntry]

    private init(entries: [String: VendorEntry]) {
        self.entries = entries
    }

    static func loadBundled() throws -> WebProviderCatalog {
        let bundleURLs = [
            Bundle.module.url(forResource: "web_providers_catalog", withExtension: "json"),
            Bundle.main.url(forResource: "web_providers_catalog", withExtension: "json"),
        ]
        for u in bundleURLs.compactMap({ $0 }) {
            guard let data = try? Data(contentsOf: u) else { continue }
            let root = try JSONDecoder().decode(RootDTO.self, from: data)
            let map: [String: VendorEntry] = Dictionary(uniqueKeysWithValues:
                root.vendors.compactMap { dto in
                    guard let selector = dto.selectors.modelDropdown, !selector.isEmpty else { return nil }
                    return (dto.id, VendorEntry(id: dto.id, models: dto.models ?? [], input: dto.selectors.input, sendButton: dto.selectors.sendButton, responseContainer: dto.selectors.responseContainer, stopButton: dto.selectors.stopButton, modelDropdown: selector, effortDropdown: dto.selectors.effortDropdown, modelButton: dto.selectors.modelButton, modelItem: dto.selectors.modelItem, newChatTexts: dto.selectors.newChatTexts, modeSelect: dto.selectors.modeSelect, thinkingSelect: dto.selectors.thinkingSelect, effortItem: dto.selectors.effortItem, modeItem: dto.selectors.modeItem))
                })
            return WebProviderCatalog(entries: map)
        }
        // Fallback for tests (SPM resources live in the repo source tree).
        let candidates = [
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),
        ]
        for base in candidates {
            let url = base.appendingPathComponent("MiCoder/Sources/Resources/Catalog/web_providers_catalog.json")
            guard let data = try? Data(contentsOf: url) else { continue }
            let root = try JSONDecoder().decode(RootDTO.self, from: data)
            let map: [String: VendorEntry] = Dictionary(uniqueKeysWithValues:
                root.vendors.compactMap { dto in
                    guard let selector = dto.selectors.modelDropdown, !selector.isEmpty else { return nil }
                    return (dto.id, VendorEntry(id: dto.id, models: dto.models ?? [], input: dto.selectors.input, sendButton: dto.selectors.sendButton, responseContainer: dto.selectors.responseContainer, stopButton: dto.selectors.stopButton, modelDropdown: selector, effortDropdown: dto.selectors.effortDropdown, modelButton: dto.selectors.modelButton, modelItem: dto.selectors.modelItem, newChatTexts: dto.selectors.newChatTexts, modeSelect: dto.selectors.modeSelect, thinkingSelect: dto.selectors.thinkingSelect, effortItem: dto.selectors.effortItem, modeItem: dto.selectors.modeItem))
                })
            return WebProviderCatalog(entries: map)
        }
        throw NSError(domain: "WebProviderCatalog", code: 1, userInfo: [NSLocalizedDescriptionKey: "web_providers_catalog.json not found in bundle or repo"])
    }

    func selectors(for vendorID: String) -> VendorEntry? {
        entries[vendorID]
    }

    /// Catalog model lists (from live site inspection). Empty when a vendor
    /// provides no stable list (e.g. ChatGPT — models change frequently).
    func models(for vendorID: String) -> [String] {
        entries[vendorID]?.models ?? []
    }
}

/// Discovery of the real model list from a vendor's web UI (plan Раздел 13 п.4).
enum WebModelDiscovery {
    /// A provider can refresh its model list when it has a non-empty dropdown selector.
    static func canRefresh(_ config: WebProviderConfig) -> Bool {
        (try? WebProviderCatalog.loadBundled().selectors(for: config.vendor.id))?.modelDropdown.isEmpty == false
    }

    /// Read the vendor's model dropdown via the browser bridge and return the
    /// real parsed models. Returns nil if the dropdown isn't found, is empty,
    /// or throws — never silently successful with stale data.
    static func discover(using bridge: BrowserAutomationBridge,
                        dropdownSelector: String,
                        vendor: WebChatVendor) async -> [WebProviderModel]? {
        // Resolve vendor-specific selectors from the catalog.
        let catalogEntry = try? WebProviderCatalog.loadBundled().selectors(for: vendor.id)
        let modelItemSelector = catalogEntry?.modelItem ?? "div.model-item"
        let fallbackItemSelector = "[role='option'], [class*='option'], [class*='item'], div[class*='item'], li"

        do {
            // Wait for the model button to be present (up to 10s).
            var modelBtnFound = false
            for _ in 0..<20 {
                if (try? await bridge.exists(selector: dropdownSelector)) ?? false {
                    modelBtnFound = true
                    break
                }
                await bridge.wait(ms: 500)
            }

            // Fallback: if selector not found, try clicking a catalog-defined
            // New Chat label to enter chat mode.
            if !modelBtnFound {
                let newChatTexts = catalogEntry?.newChatTexts ?? ["New Chat", "Новый чат", "新对话"]
                var clicked = false
                for text in newChatTexts {
                    if (try? await bridge.clickByText(selector: "button, a, div", text: text)) == true {
                        clicked = true
                        break
                    }
                }
                if !clicked, (try? await bridge.exists(selector: "[class*='new-chat']")) == true {
                    try? await bridge.click(selector: "[class*='new-chat']")
                    clicked = true
                }
                if !clicked, (try? await bridge.exists(selector: "[data-testid*='new']")) == true {
                    try? await bridge.click(selector: "[data-testid*='new']")
                    clicked = true
                }
                if clicked {
                    await bridge.wait(ms: 2000)
                    for _ in 0..<25 {
                        if (try? await bridge.exists(selector: dropdownSelector)) == true {
                            modelBtnFound = true
                            break
                        }
                        await bridge.wait(ms: 300)
                    }
                }
            }

            // Modern web UIs may expose the model switcher as an accessible
            // button with no stable test id. Use the visible vendor label as a
            // bounded fallback, never a generic "button" discovery result.
            if !modelBtnFound {
                let vendorLabels: [String]
                switch vendor {
                case .chatgpt: vendorLabels = ["ChatGPT"]
                case .kimi: vendorLabels = ["Kimi"]
                case .qwen: vendorLabels = ["Qwen"]
                case .custom: vendorLabels = []
                }
                for label in vendorLabels {
                    if (try? await bridge.clickByText(selector: "button, [role='button']", text: label)) == true {
                        await bridge.wait(ms: 500)
                        modelBtnFound = true
                        break
                    }
                }
            }

            guard modelBtnFound else { return nil }

            // Click to open the vendor dropdown and read visible options from
            // the actual page. The previous implementation only waited for
            // Kimi's div.model-item, so Qwen/ChatGPT often returned nothing.
            try await bridge.click(selector: dropdownSelector)
            // Wait for vendor-specific dropdown items (not hardcoded div.model-item).
            try? await bridge.waitForSelector(selector: modelItemSelector, timeout: 5000)

            var modelNames = (try? await bridge.readModelItems(modelItemSelector: modelItemSelector)) ?? []
            if vendor == .qwen {
                for selector in ["[role='option']", "[class*='model-item']", "li[class*='model']"] {
                    let extra = (try? await bridge.readModelItems(modelItemSelector: selector)) ?? []
                    modelNames.append(contentsOf: extra)
                }
            }
            modelNames.append(contentsOf: (try? await readVisibleTexts(using: bridge, selector: modelItemSelector)) ?? [])

            var seen = Set<String>()
            modelNames = modelNames
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
            if vendor == .chatgpt {
                modelNames = Array(modelNames.prefix(1))
            }
            if !modelNames.isEmpty {
                return modelNames.map { WebProviderModel(name: $0) }
            }

            // Fallback: read raw text from the dropdown container.
            let text = try await bridge.readText(selector: dropdownSelector)
            let parsed = WebModelListParser.parse(dropdownText: text, vendor: vendor)
            if !parsed.isEmpty {
                return parsed.map { WebProviderModel(name: $0) }
            }

            // Last resort: try reading from universal selectors
            let universalText = try await bridge.readText(selector: fallbackItemSelector)
            let universalParsed = WebModelListParser.parse(dropdownText: universalText, vendor: vendor)
            return universalParsed.isEmpty ? nil : universalParsed.map { WebProviderModel(name: $0) }
        } catch {
            return nil
        }
    }

    /// Discover the vendor's real effort/thinking levels from the web UI.
    /// Returns nil if the effort dropdown isn't found or fails.
    static func discoverEffort(using bridge: BrowserAutomationBridge,
                              effortDropdownSelector: String,
                              vendor: WebChatVendor) async -> [WebEffort]? {
        let selectors = effortDropdownSelector
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for selector in selectors {
            do {
                var dropdownReady = false
                for _ in 0..<20 {
                    if (try? await bridge.exists(selector: selector)) == true {
                        dropdownReady = true
                        break
                    }
                    await bridge.wait(ms: 500)
                }
                guard dropdownReady else { continue }
                try await bridge.click(selector: selector)
                await bridge.wait(ms: 500)
                let triggerText = (try? await bridge.readText(selector: selector)) ?? ""
                let optionSelector = "[role='option'], [class*='effort'], [class*='thinking'], [class*='menu-item'], .ant-select-item-option-content, button"
                let optionText = (try? await bridge.readText(selector: optionSelector)) ?? ""
                let visibleText = ((try? await readVisibleTexts(using: bridge, selector: optionSelector)) ?? []).joined(separator: "\n")
                let text = [triggerText, optionText, visibleText].filter { !$0.isEmpty }.joined(separator: "\n")
                let efforts = WebModelListParser.parseEffortLevels(dropdownText: text, vendor: vendor)
                if !efforts.isEmpty { return efforts }
            } catch {
                continue
            }
        }
        return nil
    }

    private static func readVisibleTexts(using bridge: BrowserAutomationBridge, selector: String) async throws -> [String] {
        let selectorJSON = (try? JSONSerialization.data(withJSONObject: [selector]))
            .flatMap { String(data: $0, encoding: .utf8) }
            .map { String($0.dropFirst().dropLast()) } ?? "\"\""
        let result = try await bridge.evaluateJS("""
        Array.from(document.querySelectorAll(\(selectorJSON)))
            .filter(el => {
                const style = window.getComputedStyle(el);
                const rect = el.getBoundingClientRect();
                return style.display !== 'none' && style.visibility !== 'hidden' && rect.width > 0 && rect.height > 0;
            })
            .map(el => (el.innerText || el.textContent || '').trim())
            .filter(Boolean)
        """)
        if let values = result as? [String] {
            var seen = Set<String>()
            return values.filter { !$0.isEmpty && seen.insert($0).inserted }
        }
        return []
    }

    /// Discover feature modes (Deep Research, Create Image, etc.) for a vendor.
    static func discoverFeatureModes(using bridge: BrowserAutomationBridge,
                                     vendor: WebChatVendor) async -> [FeatureMode] {
        var modes: [FeatureMode] = []
        switch vendor {
        case .qwen:
            modes = await discoverQwenFeatureModes(bridge: bridge)
        case .kimi:
            modes = await discoverKimiFeatureModes(bridge: bridge)
        default:
            break
        }
        return modes
    }

    /// Discover Qwen feature modes via mode-select dropdown.
    private static func discoverQwenFeatureModes(bridge: BrowserAutomationBridge) async -> [FeatureMode] {
        do {
            try await bridge.click(selector: "[class*='mode-select']")
            try await bridge.waitForSelector(selector: ".ant-select-item-option", timeout: 5000)

            let rawModes = try await bridge.evaluateJS("""
                Array.from(document.querySelectorAll('.ant-select-item-option-content'))
                    .map(el => ({
                        name: el.textContent.trim(),
                        disabled: el.closest('.ant-select-item')?.classList.contains('ant-select-item-disabled') ?? false
                    }))
            """) as? [[String: Any]] ?? []

            return rawModes.compactMap { dict in
                guard let name = dict["name"] as? String, !name.isEmpty else { return nil }
                return FeatureMode(name: name, icon: iconForMode(name), isEnabled: !(dict["disabled"] as? Bool ?? false))
            }
        } catch {
            return []
        }
    }

    /// Discover Kimi feature modes (from sidebar or inline).
    private static func discoverKimiFeatureModes(bridge: BrowserAutomationBridge) async -> [FeatureMode] {
        do {
            let rawModes = try await bridge.evaluateJS("""
                Array.from(document.querySelectorAll('[class*="sidebar"] a, [class*="nav"] a, [class*="sidebar"] button'))
                    .map(el => el.textContent.trim())
                    .filter(t => t.length > 0 && t.length < 40)
            """) as? [String] ?? []

            let featureNames = ["Slides", "Deep Research", "Swarm", "Kimi Work", "Kimi Code", "Слайды", "Глубокое исследование"]
            return rawModes.filter { name in
                featureNames.contains { name.contains($0) }
            }.map { FeatureMode(name: $0, icon: iconForMode($0), isEnabled: true) }
        } catch {
            return []
        }
    }

    /// Discover thinking/effort levels for Qwen.
    static func discoverThinkingLevels(using bridge: BrowserAutomationBridge) async -> [WebEffort] {
        do {
            try await bridge.click(selector: "[class*='qwen-select-thinking']")
            try await bridge.waitForSelector(selector: ".ant-select-item-option", timeout: 5000)

            let rawLevels = try await bridge.evaluateJS("""
                Array.from(document.querySelectorAll('.ant-select-item-option-content'))
                    .map(el => el.textContent.trim())
            """) as? [String] ?? []

            return rawLevels.compactMap { WebEffort.fromLabel($0) }
        } catch {
            return []
        }
    }

    /// Map a mode name to an icon.
    private static func iconForMode(_ name: String) -> String? {
        let lower = name.lowercased()
        if lower.contains("image") || lower.contains("img") { return "photo" }
        if lower.contains("video") { return "video" }
        if lower.contains("research") || lower.contains("deep") { return "magnifyingglass" }
        if lower.contains("web") { return "globe" }
        if lower.contains("tool") { return "wrench" }
        if lower.contains("slides") || lower.contains("presentation") { return "rectangle.stack" }
        if lower.contains("code") { return "chevron.left.forwardslash.chevron.right" }
        if lower.contains("swarm") { return "antenna.radiowaves.left.and.right" }
        return "sparkles"
    }
}
