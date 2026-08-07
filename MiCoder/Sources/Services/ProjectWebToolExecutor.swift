import Foundation

/// Real WebToolExecutor that runs the emulated tools against the current
/// project directory (plan Раздел 12 Блок 2 п.16). Used when a web model asks
/// for a tool via the emulated protocol. Path-safety is enforced by the driver
/// (validate) before execution; this executor still resolves inside the root.
/// When an `undoManager` is provided (normal production use), file-modifying
/// tools snapshot + record undo entries and append `request_history` rows, so
/// real tool operations feed the project's undo stack (Раздел 7 п.12-14).
/// `accessLevel` enforces the gate (Раздел 12 п.18): mutating tools follow the
/// edit policy, `run_command` only ever executes at `.fullAccess` and runs as a
/// real bounded shell process against the project directory.
struct ProjectWebToolExecutor: WebToolExecutor {
    let projectRoot: String
    let fileManager: FileManager
    let undoManager: ProjectUndoManager?
    let sessionId: String?
    let accessLevel: AccessLevel
    var bridge: WKWebViewBrowserBridge?
    var selectors: WebVendorSelectors?

    init(projectRoot: String,
         fileManager: FileManager = .default,
         undoManager: ProjectUndoManager? = nil,
         sessionId: String? = nil,
         accessLevel: AccessLevel = .askBeforeChanges) {
        self.projectRoot = projectRoot
        self.fileManager = fileManager
        self.undoManager = undoManager
        self.sessionId = sessionId
        self.accessLevel = accessLevel
    }

    func execute(_ call: WebToolCall) async -> String {
        let root = URL(fileURLWithPath: projectRoot)
        // The access gate runs before any side effect: a gated tool is never
        // executed, it is reported back to the model as needing approval.
        if WebToolAccessGate.permission(for: call, accessLevel: accessLevel) == .requireApproval {
            return approvalMessage(for: call)
        }
        switch WebEmulatedTool(rawValue: call.name) {
        case .readFile:
            guard let path = call.arguments["path"] else { return "error: missing path" }
            let url = root.appendingPathComponent(path)
            // Detect image files and return a clear "not supported" message
            // instead of a confusing "cannot read" error.
            let ext = url.pathExtension.lowercased()
            let imageExtensions = ["png", "jpg", "jpeg", "gif", "webp", "bmp", "tiff", "svg"]
            if imageExtensions.contains(ext) {
                return "error: cannot read \"\(path)\" (this model does not support image input)"
            }
            guard let content = try? String(contentsOf: url, encoding: .utf8) else {
                return "error: cannot read \(path)"
            }
            return String(content.prefix(20_000))
        case .writeFile:
            guard let path = call.arguments["path"], let content = call.arguments["content"] else {
                return "error: missing path/content"
            }
            let url = root.appendingPathComponent(path)
            do {
                try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try performFileOperation(operation: "write_file", fileURL: url, execute: {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                })
                return "ok: wrote \(content.count) chars to \(path)"
            } catch { return "error: \(error.localizedDescription)" }
        case .editFile:
            guard let path = call.arguments["path"],
                  let oldStr = call.arguments["old"], let newStr = call.arguments["new"] else {
                return "error: missing path/old/new"
            }
            let url = root.appendingPathComponent(path)
            guard let content = try? String(contentsOf: url, encoding: .utf8) else {
                return "error: cannot read \(path)"
            }
            guard content.contains(oldStr) else { return "error: 'old' text not found in \(path)" }
            let updated = content.replacingOccurrences(of: oldStr, with: newStr)
            do {
                try performFileOperation(operation: "edit_file", fileURL: url, execute: {
                    try updated.write(to: url, atomically: true, encoding: .utf8)
                })
                return "ok: edited \(path)"
            } catch { return "error: \(error.localizedDescription)" }
        case .listDir:
            let path = call.arguments["path"] ?? "."
            let url = root.appendingPathComponent(path)
            guard let entries = try? fileManager.contentsOfDirectory(atPath: url.path) else {
                return "error: cannot list \(path)"
            }
            return entries.sorted().joined(separator: "\n")
        case .grep:
            guard let pattern = call.arguments["pattern"] else { return "error: missing pattern" }
            let path = call.arguments["path"] ?? "."
            return grep(pattern: pattern, in: root.appendingPathComponent(path))
        case .runCommand:
            // E12: at .fullAccess the command actually runs — a bounded real
            // shell process rooted at the project directory, returning stdout +
            // stderr + exit code. At any lower level the gate above already
            // returned the approval message and nothing executed.
            let cmd = call.arguments["command"] ?? ""
            return ProjectShellRunner.run(command: cmd, workingDirectory: projectRoot).output
        // Git operations
        case .gitStatus:
            return ProjectShellRunner.run(command: "git status", workingDirectory: projectRoot).output
        case .gitDiff:
            let staged = call.arguments["staged"] == "true"
            let cmd = staged ? "git diff --cached" : "git diff"
            return ProjectShellRunner.run(command: cmd, workingDirectory: projectRoot).output
        case .gitLog:
            let limit = call.arguments["limit"] ?? "10"
            return ProjectShellRunner.run(command: "git log --oneline -\(limit)", workingDirectory: projectRoot).output
        case .gitBranch:
            if let branch = call.arguments["branch"], call.arguments["create"] == "true" {
                return ProjectShellRunner.run(command: "git checkout -b \(branch)", workingDirectory: projectRoot).output
            }
            return ProjectShellRunner.run(command: "git branch", workingDirectory: projectRoot).output
        case .gitCheckout:
            guard let branch = call.arguments["branch"] else { return "error: missing branch" }
            return ProjectShellRunner.run(command: "git checkout \(branch)", workingDirectory: projectRoot).output
        case .gitCommit:
            guard let message = call.arguments["message"] else { return "error: missing message" }
            let addAll = call.arguments["addAll"] == "true"
            let addCmd = addAll ? "git add -A && " : ""
            return ProjectShellRunner.run(command: "\(addCmd)git commit -m \"\(message)\"", workingDirectory: projectRoot).output
        case .gitPush:
            let remote = call.arguments["remote"] ?? "origin"
            let branch = call.arguments["branch"] ?? ""
            let branchArg = branch.isEmpty ? "" : " \(branch)"
            return ProjectShellRunner.run(command: "git push \(remote)\(branchArg)", workingDirectory: projectRoot).output
        case .gitPull:
            let remote = call.arguments["remote"] ?? "origin"
            let branch = call.arguments["branch"] ?? ""
            let branchArg = branch.isEmpty ? "" : " \(branch)"
            return ProjectShellRunner.run(command: "git pull \(remote)\(branchArg)", workingDirectory: projectRoot).output
        // File search & glob
        case .glob:
            let pattern = call.arguments["pattern"] ?? "*"
            let path = call.arguments["path"] ?? "."
            return glob(pattern: pattern, in: root.appendingPathComponent(path))
        case .todoRead:
            return todoRead()
        case .todoWrite:
            guard let todosJson = call.arguments["todos"] else {
                return "error: missing 'todos' argument (expected JSON array)"
            }
            return todoWrite(todosJson: todosJson)
        case .task:
            // Sub-agent task tool - launch async sub-agent
            return await executeTask(call: call)
        case .none:
            return "error: unknown tool \(call.name)"
        }
    }

    /// Message fed back to the model when the access gate blocks a tool.
    /// Includes the tool name and the level that is required, so the model can
    /// report the limitation honestly instead of silently skipping work.
    private func approvalMessage(for call: WebToolCall) -> String {
        "\(call.name) requires approval (AccessLevel: \(accessLevel.rawValue)); not executed"
    }

    /// Runs a file-modifying tool under the project's undo manager when one is
    /// configured: snapshot the pre-change state, execute, record the undo
    /// entry and a `request_history` row. Without an undo manager (tests / no
    /// open project) the plain write runs unchanged.
    private func performFileOperation(operation: String, fileURL: URL, execute: () throws -> Void) throws {
        guard let undoManager, let sessionId else {
            try execute()
            return
        }
        try undoManager.executeWithUndo(operation: operation, filePath: fileURL.path, sessionId: sessionId, execute: execute)
        try undoManager.db.recordRequestHistory(
            sessionId: sessionId,
            type: "file_edit",
            payload: "{\"path\":\"\(fileURL.path)\",\"operation\":\"\(operation)\"}"
        )
    }

    // MARK: - Todo persistence (plan Раздел 12 — real tool ops, not stubs)

    private func todoFileURL() -> URL {
        URL(fileURLWithPath: projectRoot).appendingPathComponent(".micoder/todos.json")
    }

    /// Read the current todo list from `<project>/.micoder/todos.json`.
    private func todoRead() -> String {
        let url = todoFileURL()
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              !json.isEmpty else {
            return "[]"
        }
        var lines: [String] = []
        for item in json {
            let id = item["id"] as? String ?? "?"
            let content = item["content"] as? String ?? ""
            let status = item["status"] as? String ?? "pending"
            lines.append("[\(status)] \(id): \(content)")
        }
        return lines.joined(separator: "\n")
    }

    /// Replace the todo list with the provided JSON array and persist it.
    private func todoWrite(todosJson: String) -> String {
        guard let data = todosJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) else {
            return "error: invalid JSON — expected a JSON array of todo objects"
        }
        // Accept both a bare array and {"todos": [...]} wrapper.
        let todos: [[String: Any]]
        if let array = json as? [[String: Any]] {
            todos = array
        } else if let dict = json as? [String: Any],
                  let array = dict["todos"] as? [[String: Any]] {
            todos = array
        } else {
            return "error: expected a JSON array or {\"todos\": [...]} object"
        }
        // Validate each todo has required fields.
        for item in todos {
            guard let id = item["id"] as? String, !id.isEmpty,
                  let content = item["content"] as? String, !content.isEmpty else {
                return "error: each todo must have non-empty 'id' and 'content' strings"
            }
        }
        let url = todoFileURL()
        do {
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let outData = try JSONSerialization.data(withJSONObject: todos, options: [.prettyPrinted, .sortedKeys])
            try outData.write(to: url)
            return "ok: saved \(todos.count) todo\(todos.count == 1 ? "" : "s")"
        } catch {
            return "error: \(error.localizedDescription)"
        }
    }

    private func grep(pattern: String, in dir: URL) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return "error: bad regex" }
        var hits: [String] = []
        let scanned = ProjectFileScanner.scan(root: dir.path)
        for rec in scanned.prefix(500) {
            let fileURL = dir.appendingPathComponent(rec.path)
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            for (i, line) in content.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                let s = String(line)
                if regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil {
                    hits.append("\(rec.path):\(i + 1): \(s.trimmingCharacters(in: .whitespaces))")
                    if hits.count >= 100 { return hits.joined(separator: "\n") }
                }
            }
        }
        return hits.isEmpty ? "(no matches)" : hits.joined(separator: "\n")
    }

    private func glob(pattern: String, in dir: URL) -> String {
        let fileManager = self.fileManager
        let enumerator = fileManager.enumerator(at: dir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        var matches: [String] = []
        let patternRegex = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "?", with: ".")
        guard let regex = try? NSRegularExpression(pattern: "^" + patternRegex + "$") else {
            return "error: invalid glob pattern"
        }
        while let fileURL = enumerator?.nextObject() as? URL {
            let relPath = fileURL.path.replacingOccurrences(of: dir.path + "/", with: "")
            let fileName = fileURL.lastPathComponent
            if regex.firstMatch(in: fileName, range: NSRange(location: 0, length: fileName.count)) != nil {
                matches.append(relPath)
            }
        }
        return matches.isEmpty ? "(no matches)" : matches.joined(separator: "\n")
    }

    private func executeTask(call: WebToolCall) async -> String {
        guard let description = call.arguments["description"],
              let prompt = call.arguments["prompt"] else {
            return "error: missing description or prompt"
        }
        // Bridge is injected by the chat panel; without it we cannot drive a
        // browser. Surface the limitation as a catchable error rather than
        // force-unwrapping (which SIGILLed the process, pre-fix).
        guard let bridge else {
            return "error: sub-agent requires an active browser session (bridge not available)"
        }

        var config = WebProviderConfig(vendor: .kimi, toolCallDelayMs: 800, acknowledgedToS: true)
        config.selectedModel = "k2"
        let selectors = WebVendorSelectors(
            input: "textarea, div[contenteditable='true']",
            sendButton: "button[type='submit'], button[aria-label*='end'], button[data-testid='send-button']",
            responseContainer: "div[data-message-author-role='assistant'], div[class*='markdown'], div[class*='message']",
            stopButton: "button[aria-label*='top'], button[data-testid='stop-button'], button[class*='stop']"
        )

        let driver = WebChatDriver(bridge: bridge, executor: self, selectors: selectors, config: config, projectRoot: projectRoot, accessLevel: accessLevel)

        let fullPrompt = """
            \(prompt)

            You are a sub-agent working on a specific task. Your task description:
            \(description)

            Work autonomously and return a comprehensive result when done.
            """

        var result = ""
        await driver.runTurn(userMessage: fullPrompt, isFirstMessage: true) { event in
            switch event {
            case .final(let text):
                result = text
            case .error(let err):
                result = "error: \(err)"
            case .iterationLimitReached:
                result = "error: iteration limit reached"
            default:
                break
            }
        }

        return result
    }
}
