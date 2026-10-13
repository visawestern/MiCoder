import Testing
import Foundation
@testable import myCoder

/// OpenCode headless-server session API (verified live against
/// `opencode serve` 1.18.29: POST /session → POST /session/:id/message).
@Suite("OpenCode serve session client (OC-2)")
struct OpenCodeServeClientTests {

    private func json(_ s: String) -> Data { s.data(using: .utf8)! }

    @Test func sessionIDExtractsFromCreateResponse() {
        let data = json(#"{"id":"ses_abc123","slug":"x","title":"probe"}"#)
        #expect(OpenCodeServeClient.extractSessionID(from: data) == "ses_abc123")
        #expect(OpenCodeServeClient.extractSessionID(from: json("{}")) == nil)
    }

    @Test func textJoinsTextParts() {
        let data = json("""
        {"info":{"id":"m1"},"parts":[
          {"type":"step-start","id":"p0"},
          {"type":"text","text":"he"},
          {"type":"text","text":"llo"},
          {"type":"tool","state":{"status":"completed"}}
        ]}
        """)
        #expect(OpenCodeServeClient.extractText(from: data) == "hello")
        #expect(OpenCodeServeClient.extractText(from: json(#"{"info":{},"parts":[]}"#)) == nil)
    }

    @Test func messageBodyCarriesModelAndText() throws {
        let body = OpenCodeServeClient.messageBody(modelID: "big-pickle", text: "hi")
        let data = try JSONSerialization.data(withJSONObject: body)
        let back = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let model = back?["model"] as? [String: Any]
        #expect(model?["providerID"] as? String == "opencode")
        #expect(model?["modelID"] as? String == "big-pickle")
        let parts = back?["parts"] as? [[String: Any]]
        #expect(parts?.first?["text"] as? String == "hi")
    }

    @Test func sendCreatesSessionThenMessages() async throws {
        let session = json(#"{"id":"ses_1","slug":"x"}"#)
        let answer = json(#"{"info":{"id":"m1"},"parts":[{"type":"text","text":"ok"}]}"#)
        // Two-step scripted transport.
        final class Script: DirectChatTransport, @unchecked Sendable {
            var calls: [String] = []
            func post(url: String, headers: [String : String], body: Data) async -> (Int, Data)? {
                calls.append(url)
                if url.hasSuffix("/session") { return (200, session) }
                return (200, answer)
            }
            let session: Data
            let answer: Data
            init(session: Data, answer: Data) { self.session = session; self.answer = answer }
        }
        let transport = Script(session: session, answer: answer)
        let result = try await OpenCodeServeClient.send(
            baseURL: "http://127.0.0.1:4096", headers: [:],
            modelID: "big-pickle", text: "hi", sessionID: nil,
            transport: transport)
        #expect(result.content == "ok")
        #expect(result.sessionID == "ses_1")
        #expect(transport.calls.count == 2)
        #expect(transport.calls[0].hasSuffix("/session"))
        #expect(transport.calls[1].contains("/session/ses_1/message"))
    }

    @Test func sendReusesGivenSession() async throws {
        let answer = json(#"{"info":{"id":"m1"},"parts":[{"type":"text","text":"again"}]}"#)
        final class Script: DirectChatTransport, @unchecked Sendable {
            var calls: [String] = []
            let answer: Data
            init(answer: Data) { self.answer = answer }
            func post(url: String, headers: [String : String], body: Data) async -> (Int, Data)? {
                calls.append(url)
                return (200, answer)
            }
        }
        let transport = Script(answer: answer)
        let result = try await OpenCodeServeClient.send(
            baseURL: "http://127.0.0.1:4096", headers: [:],
            modelID: "big-pickle", text: "hi", sessionID: "ses_9",
            transport: transport)
        #expect(result.content == "again")
        #expect(result.sessionID == "ses_9")
        #expect(transport.calls.count == 1)
    }

    @Test func unauthorizedIsActionable() async {
        struct DenyAll: DirectChatTransport {
            func post(url: String, headers: [String : String], body: Data) async -> (Int, Data)? {
                (401, Data())
            }
        }
        do {
            _ = try await OpenCodeServeClient.send(
                baseURL: "http://127.0.0.1:4096", headers: [:],
                modelID: "big-pickle", text: "hi", sessionID: "ses_9",
                transport: DenyAll())
            Issue.record("expected throw")
        } catch let error as OpenCodeServeError {
            #expect(error == .unauthorized)
            #expect(error.localizedDescription.contains("password") || error.localizedDescription.contains("auth"))
        } catch {
            Issue.record("wrong error type: \(error)")
        }
    }
}
