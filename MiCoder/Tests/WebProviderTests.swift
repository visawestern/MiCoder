import Testing
import Foundation
@testable import MiCoder

@Suite("Web provider config + vendors (plan Раздел 12 Блок 1)")
struct WebProviderConfigTests {

    @Test func vendorDefaultsPopulated() {
        #expect(WebChatVendor.kimi.defaultChatURL == "https://www.kimi.com/")
        #expect(WebChatVendor.qwen.defaultChatURL == "https://chat.qwen.ai/")
        #expect(WebChatVendor.chatgpt.defaultChatURL == "https://chatgpt.com/")
        #expect(WebChatVendor.kimi.defaultModels.contains("k2-thinking"))
        #expect(WebChatVendor.chatgpt.defaultModels.contains("o3"))
    }

    @Test func configUsesVendorDefaults() {
        let cfg = WebProviderConfig(vendor: .kimi)
        #expect(cfg.displayName == "Kimi")
        #expect(cfg.chatURL == "https://www.kimi.com/")
        #expect(cfg.selectedModel == "k2")
        #expect(cfg.effort == .medium)
        #expect(cfg.toolCallDelayMs == 800)
        #expect(cfg.maxToolIterations == 25)
    }

    @Test func notReadyUntilToSAcknowledged() {
        var cfg = WebProviderConfig(vendor: .qwen)
        #expect(!cfg.isReady)               // ToS not acknowledged
        cfg.acknowledgedToS = true
        #expect(cfg.isReady)
    }

    @Test func configRoundTripsThroughCodable() throws {
        let cfg = WebProviderConfig(vendor: .chatgpt, effort: .high, toolCallDelayMs: 1200, acknowledgedToS: true)
        let data = try JSONEncoder().encode(cfg)
        let decoded = try JSONDecoder().decode(WebProviderConfig.self, from: data)
        #expect(decoded == cfg)
        #expect(decoded.effort == .high)
        #expect(decoded.toolCallDelayMs == 1200)
    }

    @Test func storePersistsAndUpserts() {
        let d = UserDefaults(suiteName: "web-providers-\(UUID().uuidString)")!
        let a = WebProviderConfig(vendor: .kimi, acknowledgedToS: true)
        WebProviderStore.save([a], defaults: d)
        #expect(WebProviderStore.load(defaults: d).count == 1)

        var updated = a
        updated.effort = .high
        let merged = WebProviderStore.upsert(updated, in: WebProviderStore.load(defaults: d))
        WebProviderStore.save(merged, defaults: d)
        let loaded = WebProviderStore.load(defaults: d)
        #expect(loaded.count == 1)
        #expect(loaded.first?.effort == .high)
    }
}

@Suite("Web tool-protocol emulator (plan Раздел 12 Блок 2)")
struct WebToolProtocolEmulatorTests {

    @Test func systemPreambleListsToolsAndFormat() {
        let preamble = WebToolProtocolEmulator.systemPreamble()
        #expect(preamble.contains("```tool"))
        #expect(preamble.contains("read_file"))
        #expect(preamble.contains("write_file"))
        #expect(preamble.contains("run_command"))
    }

    @Test func systemPreambleIncludesUserPrompt() {
        let preamble = WebToolProtocolEmulator.systemPreamble(userSystemPrompt: "Be terse.")
        #expect(preamble.hasPrefix("Be terse."))
    }

    @Test func parsesSingleToolCall() {
        let response = """
        Let me read that file.
        ```tool
        {"name": "read_file", "args": {"path": "src/main.swift"}}
        ```
        """
        let calls = WebToolProtocolEmulator.parseToolCalls(from: response)
        #expect(calls.count == 1)
        #expect(calls.first?.name == "read_file")
        #expect(calls.first?.arguments["path"] == "src/main.swift")
    }

    @Test func parsesMultipleToolCalls() {
        let response = """
        ```tool
        {"name": "list_dir", "args": {"path": "."}}
        ```
        then
        ```tool
        {"name": "read_file", "args": {"path": "README.md"}}
        ```
        """
        let calls = WebToolProtocolEmulator.parseToolCalls(from: response)
        #expect(calls.count == 2)
        #expect(calls[0].name == "list_dir")
        #expect(calls[1].name == "read_file")
    }

    @Test func finalResponseHasNoToolCall() {
        #expect(WebToolProtocolEmulator.isFinalResponse("All done! The bug is fixed."))
        #expect(!WebToolProtocolEmulator.isFinalResponse("```tool\n{\"name\":\"grep\",\"args\":{}}\n```"))
    }

    @Test func formatToolResultProducesParseableBlock() {
        let block = WebToolProtocolEmulator.formatToolResult(name: "read_file", result: "line1\nline2")
        #expect(block.contains("```tool_result"))
        #expect(block.contains("read_file"))
        // The result must be JSON-escaped (newline → \n)
        #expect(block.contains("line1"))
    }

    @Test func stopLoopOnFinalOrLimit() {
        #expect(WebToolProtocolEmulator.shouldStopLoop(iteration: 3, maxIterations: 25, lastResponse: "done"))
        #expect(WebToolProtocolEmulator.shouldStopLoop(iteration: 25, maxIterations: 25, lastResponse: "```tool\n{}\n```"))
        #expect(!WebToolProtocolEmulator.shouldStopLoop(iteration: 2, maxIterations: 25, lastResponse: "```tool\n{\"name\":\"grep\"}\n```"))
    }

    @Test func validateRejectsPathEscape() {
        let call = WebToolCall(name: "read_file", arguments: ["path": "../../etc/passwd"])
        #expect(WebToolProtocolEmulator.validate(call, projectRoot: "/home/user/proj") == .pathEscapesProject("../../etc/passwd"))
    }

    @Test func validateAcceptsInsidePath() {
        let call = WebToolCall(name: "read_file", arguments: ["path": "src/main.swift"])
        #expect(WebToolProtocolEmulator.validate(call, projectRoot: "/home/user/proj") == nil)
    }

    @Test func validateRejectsUnknownTool() {
        let call = WebToolCall(name: "delete_everything", arguments: [:])
        #expect(WebToolProtocolEmulator.validate(call, projectRoot: "/home/user/proj") == .unknownTool("delete_everything"))
    }

    @Test func destructiveToolsRequireApproval() {
        #expect(WebToolProtocolEmulator.requiresApproval(WebToolCall(name: "write_file", arguments: [:])))
        #expect(WebToolProtocolEmulator.requiresApproval(WebToolCall(name: "run_command", arguments: [:])))
        #expect(!WebToolProtocolEmulator.requiresApproval(WebToolCall(name: "read_file", arguments: [:])))
    }

    @Test func pathInsideRootHandlesAbsoluteAndRelative() {
        #expect(WebToolProtocolEmulator.isPathInsideRoot("src/a.swift", root: "/proj"))
        #expect(WebToolProtocolEmulator.isPathInsideRoot("/proj/src/a.swift", root: "/proj"))
        #expect(!WebToolProtocolEmulator.isPathInsideRoot("/etc/passwd", root: "/proj"))
        #expect(!WebToolProtocolEmulator.isPathInsideRoot("../x", root: "/proj"))
    }
}

@Suite("Web session + anti-ban logic (plan Раздел 12 Блок 3)")
struct WebSessionLogicTests {

    @Test func detectsCaptchaMarkers() {
        #expect(WebSessionLogic.detectCaptcha(pageText: "Please complete the reCAPTCHA", url: ""))
        #expect(WebSessionLogic.detectCaptcha(pageText: "", url: "https://challenges.cloudflare.com/x"))
        #expect(WebSessionLogic.detectCaptcha(pageText: "Verify you are human", url: ""))
        #expect(!WebSessionLogic.detectCaptcha(pageText: "Hello, how can I help?", url: "https://kimi.com/chat"))
    }

    @Test func inferStateCaptchaWins() {
        let s = WebSessionLogic.inferState(currentURL: "https://kimi.com", hasChatInput: true,
                                           pageText: "verify you are human")
        #expect(s == .captchaRequired)
    }

    @Test func inferStateLoggedOutOnLoginURL() {
        let s = WebSessionLogic.inferState(currentURL: "https://chatgpt.com/auth/login",
                                           hasChatInput: false, pageText: "Sign in")
        #expect(s == .loggedOut)
    }

    @Test func inferStateConnectedWhenChatPresent() {
        let s = WebSessionLogic.inferState(currentURL: "https://chat.qwen.ai/c/123",
                                           hasChatInput: true, pageText: "chat")
        #expect(s == .connected)
    }

    @Test func sessionExpiredWhenAllCookiesPast() {
        #expect(WebSessionLogic.isSessionExpired(cookieExpiryEpochs: [100, 200], now: 300))
        #expect(!WebSessionLogic.isSessionExpired(cookieExpiryEpochs: [100, 5000], now: 300))
        #expect(WebSessionLogic.isSessionExpired(cookieExpiryEpochs: [], now: 300))
    }

    @Test func keepAliveDueAfterInterval() {
        #expect(WebSessionLogic.keepAliveDue(lastPing: 0, now: 130, intervalSec: 120))
        #expect(!WebSessionLogic.keepAliveDue(lastPing: 0, now: 60, intervalSec: 120))
    }

    @Test func antiBanDelayAppliesJitterWithinBounds() {
        // randomUnit 0.5 → offset 0 → exactly base
        #expect(WebAntiBanTiming.delayMs(base: 800, jitterPercent: 20, randomUnit: 0.5) == 800)
        // randomUnit 0 → -span → base - 160 = 640
        #expect(WebAntiBanTiming.delayMs(base: 800, jitterPercent: 20, randomUnit: 0) == 640)
        // randomUnit ~1 → +span → ~ base + 160
        let high = WebAntiBanTiming.delayMs(base: 800, jitterPercent: 20, randomUnit: 0.999)
        #expect(high >= 955 && high <= 960)
    }

    @Test func antiBanDelayZeroBaseIsZero() {
        #expect(WebAntiBanTiming.delayMs(base: 0, randomUnit: 0.5) == 0)
    }
}
