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
                        vendor: WebChatVendor,
                        includeAllModels: Bool = false) async -> [WebProviderModel]? {
        // Resolve vendor-specific selectors from the catalog.
        let catalogEntry = try? WebProviderCatalog.loadBundled().selectors(for: vendor.id)
        let modelItemSelector = catalogEntry?.modelItem ?? "div.model-item"
        let fallbackItemSelector = "[role='option'], [class*='model'], [class*='option'], li[class*='model']"

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

            // Open the vendor dropdown and inspect structured visible leaf nodes.
            try await bridge.click(selector: dropdownSelector)
            try? await bridge.waitForSelector(selector: modelItemSelector, timeout: 5000)

            let candidateSelectors = [modelItemSelector,
                                      "[role='option']",
                                      "[role='menuitem']",
                                      "[class*='model-item']"]
            var candidates: [WebModelDOMItem] = []
            for selector in candidateSelectors {
                candidates.append(contentsOf: (try? await bridge.readModelCandidates(modelItemSelector: selector)) ?? [])
            }
            // Some vendors render secondary model columns without the vendor's
            // model-item class/role. Scan only visible menu surfaces as a bounded
            // fallback; strict vendor validation still rejects headings/efforts.
            candidates.append(contentsOf: (try? await bridge.readVisibleModelCandidates()) ?? [])
            let validNames = validatedNames(candidates, vendor: vendor)
            if !validNames.isEmpty {
                let limited = vendor == .chatgpt && !includeAllModels ? Array(validNames.prefix(1)) : validNames
                return limited.map { liveModel($0) }
            }

            // Text fallback is still strict; it cannot bypass the vendor validator.
            let text = try await bridge.readText(selector: dropdownSelector)
            let parsed = WebModelListParser.parse(dropdownText: text, vendor: vendor)
            if !parsed.isEmpty {
                let limited = vendor == .chatgpt && !includeAllModels ? Array(parsed.prefix(1)) : parsed
                return limited.map { liveModel($0) }
            }

            let universalText = try await bridge.readText(selector: fallbackItemSelector)
            let universalParsed = WebModelListParser.parse(dropdownText: universalText, vendor: vendor)
            guard !universalParsed.isEmpty else { return nil }
            let limited = vendor == .chatgpt && !includeAllModels ? Array(universalParsed.prefix(1)) : universalParsed
            return limited.map { WebProviderModel(name: $0) }
        } catch {
            return nil
        }
    }

    private static func liveModel(_ name: String) -> WebProviderModel {
        WebProviderModel(name: name,
                         discoveryStatus: .active,
                         isLiveDiscovered: true)
    }

    private static func validatedNames(_ candidates: [WebModelDOMItem], vendor: WebChatVendor) -> [String] {
        var seen = Set<String>()
        return candidates.compactMap { candidate in
            guard candidate.isVisible, candidate.isSelectable, !candidate.isDisabled, candidate.isLeaf,
                  let name = WebModelListParser.normalize(candidate.label, vendor: vendor) else { return nil }
            let key = name.lowercased()
            guard seen.insert(key).inserted else { return nil }
            return name
        }
    }

    /// Discover every model exposed through nested/secondary model menus.
    /// The page remains the source of truth; the bounded depth prevents a broken
    /// menu from producing an infinite browser loop.
    static func discoverAllModels(using bridge: BrowserAutomationBridge,
                                  dropdownSelector: String,
                                  vendor: WebChatVendor,
                                  maxExpansionDepth: Int = 12) async -> [WebProviderModel]? {
        let initial = await discover(using: bridge, dropdownSelector: dropdownSelector,
                                     vendor: vendor, includeAllModels: true) ?? []
        var names = initial.map(\.name)
        var seen = Set(names.map { $0.lowercased() })
        let expandLabels = [
            "Expand more models", "Expand models", "Expand more", "More models",
            "Show more models", "Show all models", "View all models",
            "Ещё модели", "Показать ещё", "Больше моделей", "更多模型", "展开更多模型", "展开更多"
        ]
        let expansionSelector = "button, a, [role='button'], [role='menuitem']"
        let catalogEntry = try? WebProviderCatalog.loadBundled().selectors(for: vendor.id)
        let itemSelector = catalogEntry?.modelItem ?? "[role='option'], [class*='model'], [class*='option']"
        let candidateSelectors = [itemSelector, "[role='option']", "[role='menuitem']", "[class*='model-item']"]
        var attemptedStates = Set<String>()

        for _ in 0..<maxExpansionDepth {
            var progressed = false
            for label in expandLabels {
                let beforeFingerprint = (try? await bridge.responseFingerprint(selector: itemSelector)) ?? ""
                let stateKey = "\(beforeFingerprint)|\(label.lowercased())"
                guard attemptedStates.insert(stateKey).inserted else { continue }
                guard (try? await bridge.clickVisibleTextExact(selector: expansionSelector, text: label)) == true else { continue }
                await bridge.wait(ms: 350)

                var candidates: [WebModelDOMItem] = []
                for selector in candidateSelectors {
                    candidates.append(contentsOf: (try? await bridge.readModelCandidates(modelItemSelector: selector)) ?? [])
                }
                candidates.append(contentsOf: (try? await bridge.readVisibleModelCandidates()) ?? [])
                let discovered = validatedNames(candidates, vendor: vendor)
                var added = false
                for name in discovered where seen.insert(name.lowercased()).inserted {
                    names.append(name)
                    added = true
                }
                let afterFingerprint = (try? await bridge.responseFingerprint(selector: itemSelector)) ?? ""
                if added || afterFingerprint != beforeFingerprint {
                    progressed = true
                    break
                }
            }
            guard progressed else { break }
        }

        guard !names.isEmpty else { return nil }
        return names.map { liveModel($0) }
    }

    /// Probe effort after selecting each live model. A model with no visible
    /// thinking control receives an empty capability list, which the UI uses to
    /// hide its custom effort selector rather than inventing a global setting.
    static func discoverModelCapabilities(using bridge: BrowserAutomationBridge,
                                          dropdownSelector: String,
                                          vendor: WebChatVendor,
                                          models: [WebProviderModel],
                                          effortDropdownSelector: String?) async -> [WebProviderModel] {
        guard !models.isEmpty else { return [] }
        let catalogEntry = try? WebProviderCatalog.loadBundled().selectors(for: vendor.id)
        let itemSelector = catalogEntry?.modelItem ?? "[role='option'], [class*='model'], [class*='option']"
        let effortSelector = effortDropdownSelector ?? catalogEntry?.effortDropdown
        var result: [WebProviderModel] = []

        for model in models {
            // Re-open the model menu for every probe because selecting a model
            // normally closes it. If a site virtualizes the list, the current
            // visible menu still provides the empirical answer for this model.
            _ = try? await bridge.click(selector: dropdownSelector)
            await bridge.wait(ms: 250)
            var selected = (try? await bridge.clickVisibleTextExact(selector: itemSelector, text: model.name)) == true
            if !selected {
                for selector in ["[role='option']", "[role='menuitem']", "[class*='model-item']"] {
                    if (try? await bridge.clickVisibleTextExact(selector: selector, text: model.name)) == true {
                        selected = true
                        break
                    }
                }
            }
            guard selected else {
                result.append(WebProviderModel(name: model.name,
                                               description: model.description,
                                               availableModes: model.availableModes,
                                               availableEfforts: [],
                                               parameterProfile: model.parameterProfile,
                                               supportsImageGeneration: model.supportsImageGeneration,
                                               supportsDeepResearch: model.supportsDeepResearch,
                                               supportsWebDev: model.supportsWebDev,
                                               discoveryStatus: .inactive,
                                               isLiveDiscovered: model.isLiveDiscovered,
                                               isSelectable: false,
                                               discoveryMessage: "The live menu did not expose a selectable option for this model."))
                continue
            }
            await bridge.wait(ms: 350)
            let effortProbe: [WebEffort]?
            if let effortSelector {
                effortProbe = await discoverEffort(using: bridge,
                                                   effortDropdownSelector: effortSelector,
                                                   vendor: vendor)
            } else {
                effortProbe = nil
            }
            let efforts = effortProbe ?? []
            let effortStatus: WebDiscoveryStatus = {
                guard effortSelector != nil else { return .unsupported }
                guard effortProbe != nil else { return .notDetected }
                return efforts.isEmpty ? .unsupported : .active
            }()
            let parameterProfile = await discoverParameterProfile(using: bridge)
            let existingParameters = ModelCallParametersStore.parameters(for: model.name)
            if !existingParameters.isCustomized && parameterProfile.values.isCustomized {
                ModelCallParametersStore.set(parameterProfile.values, for: model.name)
            }
            result.append(WebProviderModel(name: model.name,
                                           description: model.description,
                                           availableModes: model.availableModes,
                                           availableEfforts: efforts,
                                           parameterProfile: parameterProfile,
                                           supportsImageGeneration: model.supportsImageGeneration,
                                           supportsDeepResearch: model.supportsDeepResearch,
                                           supportsWebDev: model.supportsWebDev,
                                           discoveryStatus: effortStatus,
                                           isLiveDiscovered: true,
                                           discoveryMessage: {
                                               switch effortStatus {
                                               case .unsupported: return "This model has no visible effort control."
                                               case .notDetected: return "The effort control was expected but could not be read."
                                               default: return nil
                                               }
                                           }()))
        }
        return result
    }

    /// Probe the currently selected model's visible parameter controls. This is
    /// intentionally descriptive: a vendor may expose only some controls, so
    /// absent values remain nil and are never treated as defaults.
    static func discoverParameterProfile(using bridge: BrowserAutomationBridge) async -> WebModelParameterProfile {
        let script = """
        (function() {
          const visible = (el) => {
            const s = getComputedStyle(el), r = el.getBoundingClientRect();
            return s.display !== 'none' && s.visibility !== 'hidden' && r.width > 0 && r.height > 0;
          };
          const nodes = Array.from(document.querySelectorAll('input, textarea, select, button, [role=button]')).filter(visible);
          const relevant = nodes.filter(el => {
            const t = ((el.getAttribute('aria-label') || '') + ' ' + (el.getAttribute('name') || '') + ' ' + (el.id || '') + ' ' + (el.innerText || '')).toLowerCase();
            return /(temperature|max.?tokens?|top.?p|system.?prompt|parameter|reasoning|thinking|effort)/.test(t);
          });
          const keys = relevant.map(el => el.getAttribute('name') || el.id || el.getAttribute('aria-label') || el.tagName.toLowerCase()).filter(Boolean);
          const labels = relevant.map(el => (el.getAttribute('aria-label') || el.innerText || el.getAttribute('name') || '').trim()).filter(Boolean);
          const numberValue = (pattern) => {
            const el = relevant.find(e => pattern.test(((e.getAttribute('name') || '') + ' ' + (e.getAttribute('aria-label') || '') + ' ' + (e.id || '')).toLowerCase()));
            const value = el && (el.value || el.getAttribute('value'));
            return value && value !== '' && !Number.isNaN(Number(value)) ? Number(value) : null;
          };
          return JSON.stringify({keys: Array.from(new Set(keys)), labels: Array.from(new Set(labels)), temperature: numberValue(/temperature/), maxTokens: numberValue(/max.?tokens?/), topP: numberValue(/top.?p/) });
        })();
        """
        guard let raw = try? await bridge.evaluateJS(script) as? String,
              let data = raw.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return WebModelParameterProfile()
        }
        let keys = object["keys"] as? [String] ?? []
        let labels = object["labels"] as? [String] ?? []
        let temperature = object["temperature"] as? Double
        let maxTokens = (object["maxTokens"] as? NSNumber).map { $0.intValue }
        let topP = object["topP"] as? Double
        return WebModelParameterProfile(
            availableKeys: keys,
            labels: labels,
            values: ModelCallParameters(temperature: temperature, maxTokens: maxTokens, topP: topP)
        )
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
                let triggerTexts = (try? await readVisibleTexts(using: bridge, selector: selector)) ?? []
                guard dropdownReady, !triggerTexts.isEmpty else { continue }
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
