import Testing
import Foundation
@testable import MiCoder

/// Round 30 — live finding: route discovery picked `/api/v2/users/status`
/// (telemetry, relative URL) as a "chat API" and DirectWebAPIClient then failed
/// with `unsupported URL` (-1002). Discovery must (a) ignore obvious non-chat
/// endpoints and (b) only propose ABSOLUTE http(s) endpoints.
@Suite("Round 30 — network route discovery quality")
struct NetworkInterceptorRouteQualityTests {

    private func req(url: String, body: String? = nil,
                     contentType: String = "application/json") -> CapturedRequest {
        CapturedRequest(url: url, method: "POST",
                        headers: ["Content-Type": contentType],
                        body: body, timestamp: Date(),
                        requestID: UUID().uuidString)
    }

    @Test("telemetry/users/status endpoints are never proposed as chat APIs")
    func junkPathsFiltered() {
        let requests = [
            req(url: "https://chat.qwen.ai/api/v2/users/status",
                body: "{\"typarms\":{\"typarm4\":\"qwen_chat\"}}"),
            req(url: "https://x.io/api/telemetry", body: "{\"message\":\"x\"}"),
            req(url: "https://x.io/api/tracking", body: "{\"content\":\"x\"}"),
            req(url: "https://x.io/api/log", body: "{\"prompt\":\"x\"}")
        ]
        #expect(NetworkInterceptor.findChatAPI(requests: requests) == nil)
    }

    @Test("relative URLs are not proposed (URLSession would fail -1002)")
    func relativeURLRejected() {
        let requests = [
            req(url: "/api/v1/chat/completion", body: "{\"message\":\"hi\"}")
        ]
        #expect(NetworkInterceptor.findChatAPI(requests: requests) == nil)
    }

    @Test("absolute chat endpoint still wins")
    func absoluteChatAccepted() {
        let requests = [
            req(url: "https://chat.qwen.ai/api/v2/chat/completions",
                body: "{\"message\":\"hi\",\"content\":\"x\"}")
        ]
        let endpoint = NetworkInterceptor.findChatAPI(requests: requests)
        #expect(endpoint != nil)
        #expect(endpoint?.url.hasPrefix("https://") == true)
    }
}
