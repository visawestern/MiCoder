import Testing
import Foundation
@testable import myCoder

@Suite("Auto Free upstream error diagnostics")
struct AutoFreeGateTests {
    private let gateBody = #"{"type":"error","error":{"type":"FreeTierError","message":"OpenCode's free tier can only be used from within OpenCode."}}"#
    private let missingSessionBody = #"{"type":"error","error":{"type":"MissingSessionID","message":"x-opencode-session-id is required"}}"#

    @Test func detectsExplicitGateWithoutConflatingMissingSession() {
        #expect(MiCoderAutoFreeError.isFreeTierGate(statusCode: 403, body: gateBody))
        #expect(!MiCoderAutoFreeError.isFreeTierGate(statusCode: 400, body: missingSessionBody))
        #expect(!MiCoderAutoFreeError.isFreeTierGate(statusCode: 400, body: "MissingSessionID: only be used from within OpenCode"))
        #expect(!MiCoderAutoFreeError.isFreeTierGate(statusCode: 429, body: "rate limit"))
        #expect(!MiCoderAutoFreeError.isFreeTierGate(statusCode: 500, body: "boom"))
        #expect(!MiCoderAutoFreeError.isFreeTierGate(statusCode: 403, body: "forbidden"))
    }

    @Test func missingSessionRetainsTheRequiredContext() {
        let error = MiCoderAutoFreeError.mapHttpError(statusCode: 400, body: missingSessionBody, operation: "Free model streaming")
        guard case .apiError(let message) = error else {
            Issue.record("MissingSessionID must remain a context error, got \(error)")
            return
        }
        #expect(message.contains("HTTP 400"))
        #expect(message.contains("MissingSessionID"))
        #expect(message.contains("x-opencode-session-id is required"))
        #expect(!MiCoderAutoFreeClient.shouldHaltFailover(for: error))
    }

    @Test func missingSessionMessageTakesPrecedenceOverGateText() {
        let body = #"{"error":{"type":"MissingSessionID","message":"Missing session ID. Free tier can only be used from within OpenCode."}}"#
        #expect(!MiCoderAutoFreeError.isFreeTierGate(statusCode: 400, body: body))
        #expect(MiCoderAutoFreeError.gateMessage(in: body) == nil)
        guard case .apiError = MiCoderAutoFreeError.streamError(in: body) else {
            Issue.record("An SSE MissingSessionID error must retain its own diagnosis")
            return
        }
    }

    @Test func gateErrorMessageIncludesTheActualBoundedResponse() {
        let error = MiCoderAutoFreeError.mapHttpError(statusCode: 403, body: gateBody, operation: "Free model streaming")
        let text = error.localizedDescription
        #expect(text.contains("FreeTierError"))
        #expect(text.contains("only be used from within OpenCode"))
        #expect(text.contains("configured Zen provider"))
        #expect(!text.contains("verified live"))

        let longText = MiCoderAutoFreeError.freeTierBlocked("server detail " + String(repeating: "x", count: 10_000)).localizedDescription
        #expect(longText.contains("server detail"))
        #expect(longText.count < 700)
    }

    @Test func gateHaltsFailoverInsteadOfCarousel() {
        let error = MiCoderAutoFreeError.mapHttpError(statusCode: 403, body: gateBody, operation: "Free model chat")
        #expect(MiCoderAutoFreeClient.shouldHaltFailover(for: error))
        #expect(!MiCoderAutoFreeClient.shouldSwitchImmediately(for: error))
        #expect(!MiCoderAutoFreeClient.shouldSwitch(for: error, consecutiveFailures: 99))
    }

    @Test(arguments: [400, 403])
    func bareHTTPStatusDoesNotEstablishGate(status: Int) {
        for operation in ["Free model streaming", "Free model chat", "OpenCode free model list"] {
            let error = MiCoderAutoFreeError.mapHttpError(statusCode: status, body: "", operation: operation)
            guard case .modelUnavailable(_, let message) = error else {
                Issue.record("A bare HTTP status must preserve ordinary error mapping, got \(error)")
                continue
            }
            #expect(message.contains("HTTP \(status)"))
            #expect(!MiCoderAutoFreeClient.shouldHaltFailover(for: error))
        }
    }

    @Test func rateLimitRetainsTheServerMessage() {
        let body = #"{"error":{"type":"FreeUsageLimitError","message":"Free usage exceeded, subscribe to Go"}}"#
        let error = MiCoderAutoFreeError.mapHttpError(statusCode: 429, body: body, operation: "Free model streaming")
        guard case .rateLimited(let message) = error else {
            Issue.record("Expected the quota error, got \(error)")
            return
        }
        #expect(message.contains("HTTP 429"))
        #expect(message.contains("FreeUsageLimitError"))
        #expect(message.contains("Free usage exceeded, subscribe to Go"))
    }

    @Test func sseGateRequiresAnErrorEnvelope() {
        #expect(MiCoderAutoFreeError.gateMessage(in: gateBody)?.contains("FreeTierError") == true)
        guard case .freeTierBlocked = MiCoderAutoFreeError.streamError(in: gateBody) else {
            Issue.record("Expected an explicit SSE gate error")
            return
        }
        let content = #"{"choices":[{"delta":{"content":"FreeTierError: only be used from within OpenCode; MissingSessionID"}}]}"#
        #expect(MiCoderAutoFreeError.gateMessage(in: content) == nil)
        #expect(MiCoderAutoFreeError.streamError(in: content) == nil)
        #expect(MiCoderAutoFreeError.gateMessage(in: "FreeTierError") == nil)
    }

    @Test func ordinaryErrorEnvelopeIsNotReportedAsEmptyContent() {
        let body = #"{"error":{"type":"UpstreamError","message":"Provider temporarily unavailable"}}"#
        guard case .apiError(let message) = MiCoderAutoFreeError.streamError(in: body) else {
            Issue.record("Expected the actual upstream SSE error")
            return
        }
        #expect(message.contains("Provider temporarily unavailable"))
    }

    @Test func errorBodyReaderStopsAtItsByteBudget() async throws {
        let counter = AutoFreeByteReadCounter()
        let data = try await MiCoderAutoFreeClient.readErrorBody(AutoFreeCountingBytes(counter: counter), maxBytes: 64)
        #expect(data.count == 64)
        #expect(counter.readCount == 64)
    }

    @Test func streamingHTTPErrorReadsBodyBeforeValidation() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AutoFreeMissingSessionProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let client = MiCoderAutoFreeClient(session: session)
        do {
            for try await _ in client.chatCompletion(messages: [.init(role: "user", content: "test")]) {}
            Issue.record("Expected the HTTP error")
        } catch let error as MiCoderAutoFreeError {
            guard case .apiError(let message) = error else {
                Issue.record("Expected the body-based MissingSessionID diagnosis, got \(error)")
                return
            }
            #expect(message.contains("HTTP 400"))
            #expect(message.contains("MissingSessionID"))
            #expect(message.contains("x-opencode-session-id is required"))
        }
    }

    @Test func completionRequestCarriesTheReadToolTheFreeTierRequires() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AutoFreeCaptureProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let path = "/gate-tools"
        AutoFreeCaptureProtocol.setResponse(
            path: path,
            body: "data: {\"choices\":[{\"delta\":{\"content\":\"ok\"}}]}\n\ndata: [DONE]\n\n"
        )
        let client = MiCoderAutoFreeClient(session: session, baseURL: URL(string: "https://auto-free.test" + path)!)
        for try await _ in client.chatCompletion(messages: [.init(role: "user", content: "test")]) {}

        let body = try #require(AutoFreeCaptureProtocol.lastBody(path: path))
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let tools = try #require(json["tools"] as? [[String: Any]])
        let names = tools.compactMap { ($0["function"] as? [String: Any])?["name"] as? String }
        #expect(names.contains("read"))
        #expect(json["tool_choice"] as? String == "none")
    }

    @Test func agentToolSetUsesTheUpstreamToolNames() {
        let names = Set(MiCoderAutoFreeClient.agentToolDefinitions().map(\.function.name))
        #expect(names.contains("read"))
        #expect(names.contains("write"))
        #expect(names.contains("edit"))
        #expect(names.contains("bash"))
        #expect(names.contains("read_file") == false)
        #expect(names.contains("run_command") == false)
    }

    @Test func nativeToolCallDeltasBecomeToolCallEvents() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AutoFreeCaptureProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let path = "/tool-call-deltas"
        AutoFreeCaptureProtocol.setResponse(path: path, body: """
        data: {"choices":[{"delta":{"tool_calls":[{"index":0,"id":"call_1","type":"function","function":{"name":"read","arguments":"{\\"path\\""}}]}}]}

        data: {"choices":[{"delta":{"tool_calls":[{"index":0,"function":{"arguments":":\\"README.md\\"}"}}]}}]}

        data: [DONE]

        """)
        let client = MiCoderAutoFreeClient(session: session, baseURL: URL(string: "https://auto-free.test" + path)!)
        var events: [StreamEvent] = []
        for try await event in client.chatCompletion(messages: [.init(role: "user", content: "test")]) {
            events.append(event)
        }
        #expect(events.contains(.toolCall(
            id: "call_1",
            name: "read",
            arguments: #"{"path":"README.md"}"#
        )))
    }

    @Test func nativeToolCallMapsToTheLocalExecutor() throws {
        let call = try #require(MiCoderAutoFreeClient.emulatedToolCall(
            name: "read",
            arguments: #"{"path":"src/main.swift","limit":20}"#
        ))
        #expect(call.name == "read_file")
        #expect(call.arguments["path"] == "src/main.swift")
        #expect(call.arguments["limit"] == "20")

        let edit = try #require(MiCoderAutoFreeClient.emulatedToolCall(
            name: "edit",
            arguments: #"{"filePath":"a.swift","oldString":"x","newString":"y"}"#
        ))
        #expect(edit.name == "edit_file")
        #expect(edit.arguments["path"] == "a.swift")
        #expect(edit.arguments["old"] == "x")
        #expect(edit.arguments["new"] == "y")
    }

    @Test func assistantToolCallAndToolResultMessagesEncodeTheNativeShape() throws {
        let call = MiCoderAutoFreeClient.Message.ToolCall(
            id: "call_1",
            type: "function",
            function: .init(name: "read", arguments: #"{"path":"a.txt"}"#)
        )
        let assistant = MiCoderAutoFreeClient.Message(
            role: "assistant",
            content: "",
            toolCalls: [call]
        )
        let result = MiCoderAutoFreeClient.Message(role: "tool", content: "file body", toolCallID: "call_1")
        let data = try JSONEncoder().encode([assistant, result])
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        let encodedCall = try #require((json[0]["tool_calls"] as? [[String: Any]])?.first)
        #expect(encodedCall["id"] as? String == "call_1")
        #expect((encodedCall["function"] as? [String: Any])?["name"] as? String == "read")
        #expect(json[1]["role"] as? String == "tool")
        #expect(json[1]["tool_call_id"] as? String == "call_1")
        #expect(json[1]["content"] as? String == "file body")
    }
}

private final class AutoFreeByteReadCounter {
    var readCount = 0
}

private struct AutoFreeCountingBytes: AsyncSequence, AsyncIteratorProtocol {
    typealias Element = UInt8
    let counter: AutoFreeByteReadCounter

    func makeAsyncIterator() -> Self { self }

    mutating func next() async -> UInt8? {
        counter.readCount += 1
        return 120
    }
}

private final class AutoFreeMissingSessionProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        let body = #"{"error":{"type":"MissingSessionID","message":"x-opencode-session-id is required"}}"#
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class AutoFreeCaptureProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var responses: [String: String] = [:]
    private static var bodies: [String: Data] = [:]

    static func setResponse(path: String, body: String) {
        lock.lock()
        defer { lock.unlock() }
        responses[path] = body
        bodies[path] = nil
    }

    static func lastBody(path: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return bodies[path]
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let path = request.url?.path ?? ""
        let body = Self.captureBody(request)
        Self.lock.lock()
        let key = Self.responses.keys.first { path.hasPrefix($0) }
        if let key { Self.bodies[key] = body }
        let response = key.flatMap { Self.responses[$0] } ?? ""
        Self.lock.unlock()

        let http = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil,
                                   headerFields: ["Content-Type": "text/event-stream"])!
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(response.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func captureBody(_ request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
