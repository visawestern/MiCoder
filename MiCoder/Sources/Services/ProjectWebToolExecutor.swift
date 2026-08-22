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
            return ProjectShellRunner.run(command: Self.gitLogCommand(limit: limit), workingDirectory: projectRoot).output
        case .gitBranch:
            return ProjectShellRunner.run(
                command: Self.gitBranchCommand(branch: call.arguments["branch"], create: call.arguments["create"] == "true"),
                workingDirectory: projectRoot).output
        case .gitCheckout:
            guard let branch = call.arguments["branch"] else { return "error: missing branch" }
            return ProjectShellRunner.run(command: Self.gitCheckoutCommand(branch: branch), workingDirectory: projectRoot).output
        case .gitCommit:
            guard let message = call.arguments["message"] else { return "error: missing message" }
            let addAll = call.arguments["addAll"] == "true"
            return ProjectShellRunner.run(command: Self.gitCommitCommand(message: message, addAll: addAll), workingDirectory: projectRoot).output
        case .gitPush:
            let remote = call.arguments["remote"] ?? "origin"
            let branch = call.arguments["branch"] ?? ""
            return ProjectShellRunner.run(command: Self.gitRemoteRefCommand("git push", remote: remote, branch: branch), workingDirectory: projectRoot).output
        case .gitPull:
            let remote = call.arguments["remote"] ?? "origin"
            let branch = call.arguments["branch"] ?? ""
            return ProjectShellRunner.run(command: Self.gitRemoteRefCommand("git pull", remote: remote, branch: branch), workingDirectory: projectRoot).output
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

    // MARK: - Shell-safe git command construction (Round 29 R1)
    //
    // Model-supplied git arguments used to be interpolated raw into a
    // `/bin/zsh -c <command>` invocation, so a crafted commit message like
    // `x" && touch pwned && echo "` escaped the surrounding quotes and ran
    // arbitrary shell beyond what the approved operation implies. Every
    // interpolated value now goes through `shellQuoted`, and numeric options
    // through `sanitizedNumber`.

    /// Wraps a value in single quotes so `$()`, backticks, `&&`, `;`, `|`,
    /// `>`, globs and whitespace lose their shell meaning. A literal `'`
    /// becomes the standard `'\''` escape sequence.
    static func shellQuoted(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Digits-only sanitizer for numeric CLI options; falls back when the
    /// value contains no usable positive number. Bounded so a huge number
    /// cannot turn into an unbounded git query.
    static func sanitizedNumber(_ raw: String, fallback: Int, maxValue: Int = 10_000) -> Int {
        let digits = raw.filter(\.isNumber)
        guard !digits.isEmpty, let n = Int(digits), n > 0 else { return fallback }
        return min(n, maxValue)
    }

    static func gitLogCommand(limit: String) -> String {
        "git log --oneline -\(sanitizedNumber(limit, fallback: 10))"
    }

    static func gitBranchCommand(branch: String?, create: Bool) -> String {
        if let branch, create {
            return "git checkout -b \(shellQuoted(branch))"
        }
        return "git branch"
    }

    static func gitCheckoutCommand(branch: String) -> String {
        "git checkout \(shellQuoted(branch))"
    }

    static func gitCommitCommand(message: String, addAll: Bool) -> String {
        let addPart = addAll ? "git add -A && " : ""
        return "\(addPart)git commit -m \(shellQuoted(message))"
    }

    static func gitRemoteRefCommand(_ verb: String, remote: String, branch: String) -> String {
        let branchPart = branch.isEmpty ? "" : " \(shellQuoted(branch))"
        return "\(verb) \(shellQuoted(remote))\(branchPart)"
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
        guard let data = try? Data(contentsOf: url) else {
            return "[]"
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            return "[]"
        }
        // Accept both a bare array and {"todos": [...]} wrapper.
        let todos: [[String: Any]]
        if let array = json as? [[String: Any]] {
            todos = array
        } else if let dict = json as? [String: Any],
                  let array = dict["todos"] as? [[String: Any]] {
            todos = array
        } else {
            return "[]"
        }
        guard !todos.isEmpty else { return "[]" }
        var lines: [String] = []
        for item in todos {
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
            try performFileOperation(operation: "todo_write", fileURL: url) {
                try outData.write(to: url)
            }
            return "ok: saved \(todos.count) todo\(todos.count == 1 ? "" : "s")"
        } catch {
            return "error: \(error.localizedDescription)"
        }
    }

    private func grep(pattern: String, in dir: URL) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return "error: bad regex" }
        var hits: [String] = []
        let scanned = ProjectFileScanner.scan(root: dir.path)
        let fileLimit = 500
        let hitLimit = 100
        var filesScanned = 0
        var truncatedFiles = false
        var truncatedHits = false

        scanLoop: for rec in scanned {
            if filesScanned >= fileLimit { truncatedFiles = true; break }
            filesScanned += 1
            let fileURL = dir.appendingPathComponent(rec.path)
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            for (i, line) in content.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                let s = String(line)
                if regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil {
                    // Round 29 R2: stop BEFORE exceeding the hit limit and warn,
                    // instead of silently returning a bare 100-line prefix.
                    if hits.count >= hitLimit { truncatedHits = true; break scanLoop }
                    hits.append("\(rec.path):\(i + 1): \(s.trimmingCharacters(in: .whitespaces))")
                }
            }
        }
        if hits.isEmpty {
            // Quality pass R29b: a bare "(no matches)" over a truncated scan
            // would hide the fact that files beyond the cap were never read.
            if truncatedFiles {
                return "(no matches)\n⚠️ Truncated: scanned \(fileLimit) of \(scanned.count) files"
            }
            return "(no matches)"
        }
        var result = hits.joined(separator: "\n")
        if truncatedFiles {
            result += "\n⚠️ Truncated: scanned \(fileLimit) of \(scanned.count) files"
        }
        if truncatedHits {
            result += "\n⚠️ Truncated: showing first \(hitLimit) matches"
        }
        return result
    }

    private func glob(pattern: String, in dir: URL) -> String {
        guard let regexPattern = Self.globToRegexPattern(pattern),
              let regex = try? NSRegularExpression(pattern: regexPattern) else {
            return "error: invalid glob pattern"
        }
        // Standardize first: a scan root of "." produces a "/./"-suffixed
        // path, and on macOS the enumerator yields entries under the resolved
        // symlink target (/var → /private/var). Resolve BOTH sides so the
        // prefix comparison below cannot silently drop every entry.
        let stdDir = dir.standardizedFileURL.resolvingSymlinksInPath()
        let rootPath = stdDir.path
        let enumerator = fileManager.enumerator(at: stdDir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        var matches: [String] = []
        var truncated = false
        let matchLimit = 500
        while let fileURL = enumerator?.nextObject() as? URL {
            // Round 29 R3: patterns are matched against the path relative to the
            // scan root (glob semantics), so `src/*.swift` and `**/*.swift`
            // work; previously only lastPathComponent was tested and every
            // pattern containing "/" answered "(no matches)".
            let fullPath = fileURL.resolvingSymlinksInPath().path
            guard fullPath.hasPrefix(rootPath + "/") else { continue }
            let relPath = String(fullPath.dropFirst(rootPath.count + 1))
            let range = NSRange(relPath.startIndex..., in: relPath)
            if regex.firstMatch(in: relPath, range: range) != nil {
                if matches.count >= matchLimit { truncated = true; break }
                matches.append(relPath)
            }
        }
        if matches.isEmpty { return "(no matches)" }
        var result = matches.sorted().joined(separator: "\n")
        if truncated {
            result += "\n⚠️ Truncated: showing first \(matchLimit) entries"
        }
        return result
    }

    /// Converts a glob pattern into an anchored regular expression string.
    /// `*` matches within one path segment (`[^/]*`), `**` spans segments
    /// (`.*/?`-style, consuming an adjacent `/`), `?` is `[^/]`, `[...]`
    /// classes pass through with glob's `!` negation translated to `^`, and
    /// everything else — including `/` and regex metacharacters — is escaped
    /// literally. Returns nil for invalid patterns (unterminated class).
    static func globToRegexPattern(_ pattern: String) -> String? {
        guard !pattern.isEmpty else { return nil }
        var out = "^"
        let chars = Array(pattern)
        var i = 0
        while i < chars.count {
            let c = chars[i]
            switch c {
            case "*":
                if i + 1 < chars.count && chars[i + 1] == "*" {
                    out += ".*"
                    i += 2
                    if i < chars.count && chars[i] == "/" { i += 1 }
                } else {
                    out += "[^/]*"
                    i += 1
                }
            case "?":
                out += "[^/]"
                i += 1
            case "[":
                var j = i + 1
                if j < chars.count && chars[j] == "!" { j += 1 }
                if j < chars.count && chars[j] == "]" { j += 1 }
                while j < chars.count && chars[j] != "]" { j += 1 }
                guard j < chars.count else { return nil }
                var cls = String(chars[(i + 1)..<j])
                if cls.hasPrefix("!") { cls = "^" + cls.dropFirst() }
                out += "[" + cls + "]"
                i = j + 1
            case "]":
                return nil
            default:
                if ".()+^$|{}\\".contains(c) { out += "\\" }
                out.append(c)
                i += 1
            }
        }
        return out + "$"
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
