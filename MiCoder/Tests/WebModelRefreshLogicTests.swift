import Foundation
import Testing
@testable import MiCoder

@Suite("BUG-03 ChatGPT stale model refresh")
struct WebModelRefreshLogicTests {
    @Test("empty live refresh clears stale discovered models and selection")
    func emptyRefreshClearsStaleState() {
        let stale = WebProviderModel(
            name: "gpt-stale",
            discoveryStatus: .active,
            isLiveDiscovered: true
        )
        let config = WebProviderConfig(
            vendor: .chatgpt,
            selectedModel: "gpt-stale",
            discoveredModels: [stale],
            discoveredEffortLevels: [.high]
        )

        let refreshed = WebModelRefreshLogic.replacing(config: config, with: [])

        #expect(refreshed.discoveredModels.isEmpty)
        #expect(refreshed.discoveredEffortLevels.isEmpty)
        #expect(refreshed.selectedModel.isEmpty)
        #expect(refreshed.allModels.isEmpty)
    }

    @Test("non-empty live refresh replaces stale entries and keeps valid selection")
    func nonEmptyRefreshReplacesStaleState() {
        let config = WebProviderConfig(
            vendor: .chatgpt,
            selectedModel: "gpt-4o",
            discoveredModels: [
                WebProviderModel(name: "gpt-4o"),
                WebProviderModel(name: "gpt-stale")
            ]
        )
        let live = WebProviderModel(
            name: "gpt-4.1",
            availableEfforts: [.low, .high],
            discoveryStatus: .active,
            isLiveDiscovered: true
        )

        let refreshed = WebModelRefreshLogic.replacing(config: config, with: [live])

        #expect(refreshed.discoveredModels.map(\.name) == ["gpt-4.1"])
        #expect(refreshed.allModels == ["gpt-4.1"])
        #expect(refreshed.selectedModel == "gpt-4.1")
        #expect(refreshed.discoveredEffortLevels == [.high, .low])
    }
}
