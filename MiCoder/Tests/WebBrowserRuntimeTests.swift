import Testing
import Foundation
@testable import MiCoder

@Suite("Dynamic web browser runtime")
struct WebBrowserRuntimeTests {
    @Test("Effort capabilities belong to the selected live model")
    func modelSpecificEffortCapabilities() {
        let config = WebProviderConfig(
            vendor: .qwen,
            selectedModel: "Qwen3.8-Max",
            discoveredModels: [
                WebProviderModel(name: "Qwen3.8-Max", availableEfforts: [.low, .high]),
                WebProviderModel(name: "Qwen3-Coder", availableEfforts: [])
            ],
            discoveredEffortLevels: [.low, .medium, .high]
        )
        #expect(WebProviderSelectionLogic.availableEfforts(for: config) == [.low, .high])

        var noThinking = config
        noThinking.selectedModel = "Qwen3-Coder"
        #expect(WebProviderSelectionLogic.availableEfforts(for: noThinking).isEmpty)
    }

    @Test("Old model records decode without availableEfforts")
    func oldModelDecodeMigration() throws {
        let data = Data(#"{"name":"legacy","availableModes":["auto"],"supportsImageGeneration":false,"supportsDeepResearch":false,"supportsWebDev":false}"#.utf8)
        let model = try JSONDecoder().decode(WebProviderModel.self, from: data)
        #expect(model.name == "legacy")
        #expect(model.availableEfforts.isEmpty)
    }

    @Test("Browser instance identity isolates project, chat and provider")
    func instanceIdentity() {
        let first = WebBrowserInstanceKey(projectID: "project-a", chatID: "chat-1", providerID: "kimi")
        let same = WebBrowserInstanceKey(projectID: "project-a", chatID: "chat-1", providerID: "kimi")
        let differentChat = WebBrowserInstanceKey(projectID: "project-a", chatID: "chat-2", providerID: "kimi")
        let differentProject = WebBrowserInstanceKey(projectID: "project-b", chatID: "chat-1", providerID: "kimi")
        #expect(first == same)
        #expect(first != differentChat)
        #expect(first != differentProject)
        #expect(first.storageKey != differentChat.storageKey)
    }

    @Test("Browser action journal is bounded and keeps routing metadata")
    func boundedJournal() {
        let suiteName = "WebBrowserRuntimeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let config = WebProviderConfig(vendor: .kimi, displayName: "Kimi")
        var latest: [WebBrowserActionRecord] = []
        for index in 0..<(WebBrowserActionJournal.maxRecords + 10) {
            latest = WebBrowserActionJournal.append(
                WebBrowserActionRecord(
                    action: "send_started",
                    projectID: "project",
                    chatID: "chat-\(index)",
                    providerID: config.id,
                    providerName: config.displayName,
                    modelID: "K3",
                    effort: nil,
                    detail: "background WKWebView"
                ),
                defaults: defaults
            )
        }
        #expect(latest.count == WebBrowserActionJournal.maxRecords)
        #expect(latest.last?.chatID == "chat-\(WebBrowserActionJournal.maxRecords + 9)")
        defaults.removePersistentDomain(forName: suiteName)
    }
}
