import Foundation

enum MimoCLISessionLoaderError: Error, LocalizedError, Equatable {
    case binaryNotFound
    case commandFailed(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .binaryNotFound:
            return "mimo CLI binary not found"
        case .commandFailed(let message):
            return message.isEmpty ? "mimo session list failed" : message
        case .decodingFailed(let message):
            return "Failed to decode mimo session list: \(message)"
        }
    }
}

/// Loads recent sessions across *all* mimo projects on this machine by
/// shelling out to the `mimo` CLI (`mimo session list --format json`),
/// which reads mimo's global session database rather than the
/// per-connection `/experimental/session` HTTP endpoint.
enum MimoCLISessionLoader {

    private struct ExportEnvelope: Decodable {
        let messages: [MimoMessageResponse]
    }

    static let defaultCandidatePaths: [String] = [
        "~/.micoder/bin/mimo",
        "/usr/local/bin/mimo",
        "/opt/homebrew/bin/mimo"
    ]

    static func resolveBinaryPath(
        fileManager: FileManager = .default,
        environmentPath: String? = ProcessInfo.processInfo.environment["PATH"],
        candidatePaths: [String] = defaultCandidatePaths
    ) -> String? {
        for candidate in candidatePaths {
            let expanded = (candidate as NSString).expandingTildeInPath
            if fileManager.isExecutableFile(atPath: expanded) {
                return expanded
            }
        }
        guard let environmentPath, !environmentPath.isEmpty else { return nil }
        for directory in environmentPath.split(separator: ":") {
            guard !directory.isEmpty else { continue }
            let candidate = "\(directory)/mimo"
            if fileManager.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

    static func parseSessionList(_ data: Data) throws -> [MimoCLISessionEntry] {
        do {
            return try JSONDecoder().decode([MimoCLISessionEntry].self, from: data)
        } catch {
            throw MimoCLISessionLoaderError.decodingFailed(error.localizedDescription)
        }
    }

    static func parseExportMessages(_ data: Data) throws -> [MimoMessageResponse] {
        do {
            return try JSONDecoder().decode(ExportEnvelope.self, from: data).messages
        } catch {
            throw MimoCLISessionLoaderError.decodingFailed(String(reflecting: error))
        }
    }

    /// Merges CLI-discovered sessions (all mimo projects) with sessions
    /// already known from the live server connection, preferring the
    /// server-provided entry when both sources report the same session id.
    static func mergeSessions(existing: [ChatSession], additional: [ChatSession]) -> [ChatSession] {
        var seenIDs = Set(existing.map(\.id))
        var merged = existing
        for session in additional where seenIDs.insert(session.id).inserted {
            merged.append(session)
        }
        return merged
    }

    @discardableResult
    static func runSessionList(
        binaryPath: String,
        maxCount: Int = 200,
        timeout: TimeInterval = 15
    ) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = ["session", "list", "--format", "json", "-n", String(maxCount)]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()

        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            process.waitUntilExit()
            group.leave()
        }

        let waitResult = group.wait(timeout: .now() + timeout)
        if waitResult == .timedOut {
            process.terminate()
            throw MimoCLISessionLoaderError.commandFailed("mimo session list timed out")
        }

        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            let message = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw MimoCLISessionLoaderError.commandFailed(message)
        }

        return outData
    }

    /// Loads recent sessions from every mimo project known on this machine.
    static func loadAllSessions(maxCount: Int = 200) throws -> [ChatSession] {
        guard let binaryPath = resolveBinaryPath() else {
            throw MimoCLISessionLoaderError.binaryNotFound
        }
        let data = try runSessionList(binaryPath: binaryPath, maxCount: maxCount)
        let entries = try parseSessionList(data)
        return entries.map { $0.toChatSession() }
    }

    static func loadMessages(sessionID: String, timeout: TimeInterval = 30) throws -> [MimoMessageResponse] {
        guard let binaryPath = resolveBinaryPath() else {
            throw MimoCLISessionLoaderError.binaryNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = ["export", sessionID]

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimo-export-\(UUID().uuidString).json")
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        let stdout = try FileHandle(forWritingTo: outputURL)
        defer {
            try? stdout.close()
            try? FileManager.default.removeItem(at: outputURL)
        }
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()

        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            process.waitUntilExit()
            group.leave()
        }

        guard group.wait(timeout: .now() + timeout) != .timedOut else {
            process.terminate()
            throw MimoCLISessionLoaderError.commandFailed("mimo export timed out")
        }

        try stdout.synchronize()
        let output = try Data(contentsOf: outputURL)
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            let message = String(data: errorData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw MimoCLISessionLoaderError.commandFailed(message)
        }
        return try parseExportMessages(output)
    }
}
