import Foundation

enum GitHubCLIError: LocalizedError {
    case brewNotFound
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .brewNotFound:
            return "Homebrew is not installed. Install GitHub CLI manually from cli.github.com."
        case .commandFailed(let output):
            return output
        }
    }
}

/// Runs GitHub CLI (`gh`) and Homebrew commands for the publish wizard.
enum GitHubCLIService {

    static func detect() async -> (status: GitHubCLIStatus, ghPath: String?) {
        guard let ghPath = GitPublishFlowLogic.ghExecutablePath() else {
            return (.notInstalled, nil)
        }
        let exitCode = await runForExitCode(executable: ghPath, arguments: ["auth", "status"])
        return (GitPublishFlowLogic.status(ghInstalled: true, authStatusExitCode: exitCode), ghPath)
    }

    static func installViaHomebrew() async throws {
        guard let brewPath = GitPublishFlowLogic.brewExecutablePath() else {
            throw GitHubCLIError.brewNotFound
        }
        let result = await run(executable: brewPath, arguments: ["install", "gh"], timeout: 600)
        guard result.exitCode == 0 else {
            throw GitHubCLIError.commandFailed(result.output)
        }
    }

    /// Runs `gh auth login --web`. The one-time device code from the CLI
    /// output is reported through `onCode` so the UI can show it while the
    /// browser flow is in progress.
    static func signIn(ghPath: String, onCode: @escaping @MainActor (String) -> Void) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ghPath)
        process.arguments = GitPublishFlowLogic.loginArguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        // `gh auth login --web` waits for Enter before opening the browser.
        let stdinPipe = Pipe()
        process.standardInput = stdinPipe

        var collected = ""
        var codeReported = false
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            collected += chunk
            if !codeReported, let code = GitPublishFlowLogic.oneTimeCode(from: collected) {
                codeReported = true
                Task { @MainActor in onCode(code) }
            }
        }

        try process.run()
        stdinPipe.fileHandleForWriting.write(Data("\n".utf8))
        stdinPipe.fileHandleForWriting.closeFile()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            process.terminationHandler = { _ in continuation.resume() }
        }
        outputPipe.fileHandleForReading.readabilityHandler = nil

        guard process.terminationStatus == 0 else {
            throw GitHubCLIError.commandFailed(collected.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    static func createRepository(
        ghPath: String,
        repoName: String,
        isPublic: Bool,
        workspacePath: String
    ) async throws -> String {
        let result = await run(
            executable: ghPath,
            arguments: GitPublishFlowLogic.createRepoArguments(repoName: repoName, isPublic: isPublic),
            currentDirectory: workspacePath,
            timeout: 300
        )
        guard result.exitCode == 0 else {
            throw GitHubCLIError.commandFailed(result.output)
        }
        return result.output
    }

    // MARK: - Process helpers

    private struct CommandResult {
        let exitCode: Int32
        let output: String
    }

    private static func runForExitCode(executable: String, arguments: [String]) async -> Int32? {
        let result = await run(executable: executable, arguments: arguments)
        return result.exitCode
    }

    private static func run(
        executable: String,
        arguments: [String],
        currentDirectory: String? = nil,
        stdin: String? = nil,
        timeout: TimeInterval = 60
    ) async -> CommandResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: runBlocking(
                    executable: executable,
                    arguments: arguments,
                    currentDirectory: currentDirectory,
                    stdin: stdin,
                    timeout: timeout
                ))
            }
        }
    }

    private static func runBlocking(
        executable: String,
        arguments: [String],
        currentDirectory: String?,
        stdin: String?,
        timeout: TimeInterval
    ) -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        if let currentDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: currentDirectory)
        }

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        if let stdin, let data = stdin.data(using: .utf8) {
            let stdinPipe = Pipe()
            process.standardInput = stdinPipe
            stdinPipe.fileHandleForWriting.write(data)
            stdinPipe.fileHandleForWriting.closeFile()
        }

        do {
            try process.run()
        } catch {
            return CommandResult(exitCode: -1, output: error.localizedDescription)
        }

        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .utility).async {
            process.waitUntilExit()
            group.leave()
        }
        if group.wait(timeout: .now() + timeout) == .timedOut {
            process.terminate()
            return CommandResult(exitCode: -1, output: "Command timed out: \(executable) \(arguments.joined(separator: " "))")
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return CommandResult(exitCode: process.terminationStatus, output: output)
    }
}
