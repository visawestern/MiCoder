import Foundation

class SSEClient {
    private var task: URLSessionDataTask?
    private var streamTask: Task<Void, Never>?
    private var buffer = ""
    private static let sharedSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = TimeInterval(Int.max)
        config.timeoutIntervalForResource = TimeInterval(Int.max)
        return URLSession(configuration: config)
    }()
    
    var onEvent: ((String, [String: Any]) -> Void)?
    var isConnected: Bool { streamTask != nil }
    
    func processSSEData(_ data: String) {
        buffer.append(data)
        
        while let range = buffer.range(of: "\n\n") {
            let eventBlock = String(buffer[..<range.lowerBound])
            buffer.removeSubrange(buffer.startIndex..<range.upperBound)
            processEventBlock(eventBlock)
        }
    }
    
    func connect(url: URL, sessionID: String? = nil) {
        disconnect()
        
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        streamTask = Task {
            do {
                let (bytes, response) = try await URLSession.shared.bytes(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    return
                }
                
                var dataBuffer = Data()
                for try await byte in bytes {
                    guard !Task.isCancelled else { break }
                    
                    dataBuffer.append(byte)
                    
                    if byte == UInt8(ascii: "\n") {
                        if let line = String(data: dataBuffer, encoding: .utf8) {
                            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty && trimmed.hasPrefix("data: ") {
                                let jsonStr = String(trimmed.dropFirst(6))
                                await MainActor.run {
                                    self.processDataPayload(jsonStr)
                                }
                            }
                        }
                        dataBuffer.removeAll(keepingCapacity: true)
                    }
                }
            } catch {
                // Connection closed or cancelled
            }
        }
    }
    
    func disconnect() {
        streamTask?.cancel()
        streamTask = nil
        task?.cancel()
        task = nil
        buffer = ""
    }
    
    private func processEventBlock(_ block: String) {
        for line in block.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("data: ") else { continue }
            processDataPayload(String(trimmed.dropFirst(6)))
        }
    }
    
    private func processDataPayload(_ jsonStr: String) {
        guard let data = jsonStr.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let payload = json["payload"] as? [String: Any],
              let type = payload["type"] as? String else {
            return
        }
        onEvent?(type, payload)
    }
}
