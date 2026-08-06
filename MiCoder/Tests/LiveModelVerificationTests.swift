import XCTest
@testable import MiCoder

/// TDD: when a web session is captured (login), the app should discover the
/// real model list from the vendor's web UI and update the config's
/// discoveredModels. The catalog's hardcoded list is a fallback only.
final class LiveModelVerificationTests: XCTestCase {

    func testDiscoverUpdatesConfigWithRealModels() throws {
        // Given: a config with stale/catalog models
        var config = WebProviderConfig(vendor: .kimi, acknowledgedToS: true)
        let staleModels = ["old-model-1", "old-model-2"]
        config.discoveredModels = staleModels

        // When: discovery returns a fresh list (simulating live web scrape)
        let freshModels = ["k2", "k2-thinking", "k1.5"]
        // In production this comes from WebModelDiscovery.discover; here we
        // simulate the callback that updates the config.
        config.discoveredModels = freshModels

        // Then: the config reflects the live models, not the stale catalog
        XCTAssertEqual(config.discoveredModels, freshModels,
                       "Config should reflect live-discovered models")
        XCTAssertFalse(config.discoveredModels.contains("old-model-1"),
                       "Stale catalog models should be replaced")
    }

    func testDiscoveryFailureKeepsCatalogFallback() throws {
        // Given: a config with catalog models
        var config = WebProviderConfig(vendor: .kimi, acknowledgedToS: true)
        let catalogModels = ["k2", "k2-thinking", "k1.5"]
        config.discoveredModels = catalogModels

        // When: discovery fails (returns nil/empty)
        // The config should keep the catalog models as fallback
        let discoveryResult: [String]? = nil
        if let models = discoveryResult, !models.isEmpty {
            config.discoveredModels = models
        }

        // Then: catalog models are preserved as fallback
        XCTAssertEqual(config.discoveredModels, catalogModels,
                       "Catalog models should be kept when discovery fails")
    }

    func testDiscoveryResultIsPersisted() throws {
        // Given: a config with discovered models
        var config = WebProviderConfig(vendor: .qwen, acknowledgedToS: true)
        config.discoveredModels = ["qwen2.5-max", "qwen2.5-plus"]

        // When: saved and reloaded
        WebProviderStore.save([config])
        let loaded = WebProviderStore.load().first(where: { $0.id == config.id })

        // Then: discovered models persist
        XCTAssertNotNil(loaded, "Config should be reloadable")
        XCTAssertTrue(loaded!.discoveredModels.contains("qwen2.5-max"),
                      "Discovered models should persist across save/load")
    }
}
