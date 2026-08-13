import Testing
import Foundation
@testable import MiCoder

@Suite("MiMoAutoProvider — refreshModels has no synthetic fallback")
struct MiMoAutoProviderTests {

    @Test("refreshModels does not invent mimo-auto when the free channel is unavailable")
    func refreshModelsDoesNotReturnSyntheticFallback() async {
        var provider = MiMoAutoProvider()
        provider.models = [
            MiMoAutoClient.MiMoModel(id: "stale-model", isFree: false),
        ]
        provider.apiKey = ""

        let result = await provider.refreshModels()

        #expect(!result.contains { $0.id == "mimo-auto" })
    }

    @Test("refreshModels clears stale models after an unavailable route")
    func refreshModelsClearsStaleModels() async {
        var provider = MiMoAutoProvider()
        provider.models = [MiMoAutoClient.MiMoModel(id: "old-model", isFree: false)]

        let result = await provider.refreshModels()

        #expect(result.isEmpty)
    }
}

@Suite("MiMoAutoProviderStore — unavailable route is not ready")
struct MiMoAutoProviderStoreRefreshTests {

    @Test("provider.models stays empty after an unavailable free refresh")
    func storeClearsModelsOnFailure() async {
        var provider = MiMoAutoProvider()
        provider.models = [MiMoAutoClient.MiMoModel(id: "stale-model", isFree: false)]

        let fetched = await provider.refreshModels()
        provider.models = fetched

        #expect(provider.models.isEmpty)
    }
}
