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
        #expect(model.parameterProfile.isEmpty)
    }

    @Test("Named web sessions persist independently and active selection switches")
    func namedSessionsRoundTripAndActivation() throws {
        let home = FileManager.default.temporaryDirectory
            .appendingPathComponent("micoder-named-sessions-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: home) }

        let first = WebSessionStore(
            cookies: [BrowserCookie(name: "sid", value: "first", domain: "kimi.com", expiresEpoch: 9_999_999_999)],
            localStorage: ["account": "first"],
            savedAt: Date(timeIntervalSince1970: 100)
        )
        let second = WebSessionStore(
            cookies: [BrowserCookie(name: "sid", value: "second", domain: "kimi.com", expiresEpoch: 9_999_999_999)],
            localStorage: ["account": "second"],
            savedAt: Date(timeIntervalSince1970: 200)
        )
        try WebSessionManager.persist(first, providerId: "kimi", homeDirectory: home,
                                      sessionID: "account-first", sessionName: "Personal")
        try WebSessionManager.persist(second, providerId: "kimi", homeDirectory: home,
                                      sessionID: "account-second", sessionName: "Work")

        let listed = WebSessionManager.list(providerId: "kimi", homeDirectory: home)
        #expect(Set(listed.map(\.id)) == ["account-first", "account-second"])
        #expect(listed.first(where: { $0.id == "account-first" })?.name == "Personal")
        #expect(listed.first(where: { $0.id == "account-second" })?.name == "Work")
        #expect(WebSessionManager.restore(providerId: "kimi", homeDirectory: home,
                                          sessionID: "account-first")?.localStorage["account"] == "first")
        #expect(WebSessionManager.restore(providerId: "kimi", homeDirectory: home,
                                          sessionID: "account-second")?.localStorage["account"] == "second")

        var config = WebProviderConfig(id: "kimi", vendor: .kimi,
                                       activeSessionID: "account-first",
                                       activeSessionName: "Personal")
        config.activeSessionID = "account-second"
        config.activeSessionName = "Work"
        #expect(config.activeSessionID == "account-second")
        #expect(config.activeSessionName == "Work")
        #expect(WebSessionManager.restore(providerId: "kimi", homeDirectory: home,
                                          sessionID: config.activeSessionID ?? "")?.cookies.first?.value == "second")
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
