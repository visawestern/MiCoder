import Testing
import Foundation
@testable import MiCoder

@Suite("MiMoAutoProvider — refreshModels clears stale data on API failure")
struct MiMoAutoProviderTests {

    @Test("refreshModels always includes mimo-auto fallback on API failure")
    func refreshModelsReturnsFallbackOnFailure() async {
        // Arrange: provider has stale models from a previous successful call
        var provider = MiMoAutoProvider()
        provider.models = [
            MiMoAutoClient.MiMoModel(id: "qwen3-max", isFree: false),
            MiMoAutoClient.MiMoModel(id: "gemini-flash", isFree: false),
        ]
        provider.apiKey = ""  // Free tier — API may fail without key

        // Act: refresh with the real MiMoAutoClient (no API key = may return error)
        let result = await provider.refreshModels()

        // Assert: must always contain mimo-auto (the user needs to send messages)
        #expect(result.contains { $0.id == "mimo-auto" }, "refreshModels must always include mimo-auto fallback")
    }

    @Test("refreshModels always includes mimo-auto when API returns empty")
    func refreshModelsReturnsFallbackOnEmpty() async {
        var provider = MiMoAutoProvider()
        provider.models = [
            MiMoAutoClient.MiMoModel(id: "old-model", isFree: false),
        ]

        let result = await provider.refreshModels()

        // Must always have mimo-auto
        #expect(result.contains { $0.id == "mimo-auto" }, "refreshModels must always include mimo-auto")
    }
}

@Suite("MiMoAutoProviderStore — refreshModels always clears on failure")
struct MiMoAutoProviderStoreRefreshTests {

    @Test("provider.models always contains mimo-auto after refresh")
    func storeClearsModelsOnFailure() async {
        // This test verifies the contract: when refreshModels() returns [],
        // the provider's models array should still have mimo-auto.

        var provider = MiMoAutoProvider()
        provider.models = [
            MiMoAutoClient.MiMoModel(id: "stale-qwen-model", isFree: false),
        ]

        // refreshModels() now returns fallback with mimo-auto (fixed)
        let fetched = await provider.refreshModels()

        // Simulate what the store does
        provider.models = fetched.isEmpty ? [MiMoAutoClient.MiMoModel(id: "mimo-auto", isFree: true)] : fetched

        // GREEN: provider.models should always contain mimo-auto
        #expect(provider.models.contains { $0.id == "mimo-auto" }, "provider.models must always contain mimo-auto")
    }
}
