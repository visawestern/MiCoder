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
    let selectors: Selectors
    struct Selectors: Decodable {
        let modelDropdown: String?
        let effortDropdown: String?
    }
}

/// Catalog-backed selectors/URLs for each web-chat vendor.
/// Source of truth: `MiCoder/Sources/Resources/Catalog/web_providers_catalog.json`
struct WebProviderCatalog {
    struct VendorEntry: Equatable {
        let id: String
        let modelDropdown: String
        let effortDropdown: String?
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
                    return (dto.id, VendorEntry(id: dto.id, modelDropdown: selector, effortDropdown: dto.selectors.effortDropdown))
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
                    return (dto.id, VendorEntry(id: dto.id, modelDropdown: selector, effortDropdown: dto.selectors.effortDropdown))
                })
            return WebProviderCatalog(entries: map)
        }
        throw NSError(domain: "WebProviderCatalog", code: 1, userInfo: [NSLocalizedDescriptionKey: "web_providers_catalog.json not found in bundle or repo"])
    }

    func selectors(for vendorID: String) -> VendorEntry? {
        entries[vendorID]
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
                        vendor: WebChatVendor) async -> [String]? {
        do {
            // Wait for the dropdown to be present on the page (up to 10s).
            // Dynamic UIs may take time to hydrate after navigation.
            var dropdownReady = false
            for _ in 0..<20 {
                if (try? await bridge.exists(selector: dropdownSelector)) ?? false {
                    dropdownReady = true
                    break
                }
                await bridge.wait(ms: 500)
            }

            // Fallback: if selector not found, try clicking "New Chat" to reveal it
            if !dropdownReady {
                // ClickByText signature: clickByText(selector:text:exactMatch:)
                let click1 = (try? await bridge.clickByText(selector: "button, a, div", text: "New Chat")) ?? false
                let click2 = (try? await bridge.clickByText(selector: "button, a", text: "新对话")) ?? false
                let click3 = (try? await bridge.click(selector: "[class*='new-chat']")) != nil
                let click4 = (try? await bridge.click(selector: "[data-testid*='new']")) != nil
                let clicked = click1 || click2 || click3 || click4
                if clicked {
                    await bridge.wait(ms: 2000)
                    // Re-check after navigation
                    for _ in 0..<25 {
                        if (try? await bridge.exists(selector: dropdownSelector)) == true {
                            dropdownReady = true
                            break
                        }
                        await bridge.wait(ms: 300)
                    }
                }
            }

            guard dropdownReady else { return nil }

            // Open the dropdown first so dynamic UIs populate the options.
            try await bridge.click(selector: dropdownSelector)
            // Settle before reading (host-side; tests are instant).
            await bridge.wait(ms: 500)
            let text = try await bridge.readText(selector: dropdownSelector)
            let models = WebModelListParser.parse(dropdownText: text, vendor: vendor)
            return models.isEmpty ? nil : models
        } catch {
            return nil
        }
    }

    /// Discover the vendor's real effort/thinking levels from the web UI.
    /// Returns nil if the effort dropdown isn't found or fails.
    static func discoverEffort(using bridge: BrowserAutomationBridge,
                              effortDropdownSelector: String,
                              vendor: WebChatVendor) async -> [WebEffort]? {
        do {
            // Wait for the effort dropdown to be present (up to 10s).
            var dropdownReady = false
            for _ in 0..<20 {
                if (try? await bridge.exists(selector: effortDropdownSelector)) ?? false {
                    dropdownReady = true
                    break
                }
                await bridge.wait(ms: 500)
            }
            guard dropdownReady else { return nil }

            try await bridge.click(selector: effortDropdownSelector)
            await bridge.wait(ms: 500)
            let text = try await bridge.readText(selector: effortDropdownSelector)
            let efforts = WebModelListParser.parseEffortLevels(dropdownText: text, vendor: vendor)
            return efforts.isEmpty ? nil : efforts
        } catch {
            return nil
        }
    }

}

extension WebProviderConnectivity {
    enum ModelsResult: Equatable {
        case models([String])
        case fallbackDefaults([String])
        case discoveryFailed(String)
    }

    /// Returns the real models if they were discovered; explicitly labels
    /// vendor defaults as fallback only when discovery hasn't been attempted
    /// yet, and surfaces an actionable failure message otherwise.
    static func modelsOrError(for config: WebProviderConfig,
                             discoveryAttempted: Bool) -> ModelsResult {
        if !config.discoveredModels.isEmpty {
            return .models(config.discoveredModels)
        }
        if !discoveryAttempted {
            return .fallbackDefaults(config.vendor.defaultModels)
        }
        return .discoveryFailed("Could not read the model list from \(config.displayName)'s web page.")
    }
}
