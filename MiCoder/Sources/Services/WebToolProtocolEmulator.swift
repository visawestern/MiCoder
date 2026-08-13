import Foundation

/// One tool call requested by a web model through the emulated text protocol
/// (plan Раздел 12 Блок 2 п.8/п.13).
struct WebToolCall: Equatable {
    let name: String
    let arguments: [String: String]
}

/// The set of tools we teach a plain web chat to "call" so it behaves like a
/// real coding agent (plan Блок 2 п.12). These map 1:1 to the app's real
/// tool executors (read_file/write_file/etc.).
enum WebEmulatedTool: String, CaseIterable {
    case readFile = "read_file"
    case writeFile = "write_file"
    case editFile = "edit_file"
    case listDir = "list_dir"
    case grep = "grep"
    case runCommand = "run_command"
    // Git operations
    case gitStatus = "git_status"
    case gitDiff = "git_diff"
    case gitLog = "git_log"
    case gitBranch = "git_branch"
    case gitCheckout = "git_checkout"
    case gitCommit = "git_commit"
    case gitPush = "git_push"
    case gitPull = "git_pull"
    // File search & glob
    case glob = "glob"
    case todoRead = "todo_read"
    case todoWrite = "todo_write"
    // Sub-agent / task tool
    case task = "task"

    var argumentSchema: String {
        switch self {
        case .readFile: return #"{"path": "<relative path>"}"#
        case .writeFile: return #"{"path": "<relative path>", "content": "<file content>"}"#
        case .editFile: return #"{"path": "<relative path>", "old": "<text>", "new": "<text>"}"#
        case .listDir: return #"{"path": "<relative path>"}"#
        case .grep: return #"{"pattern": "<regex>", "path": "<relative path>"}"#
        case .runCommand: return #"{"command": "<shell command>"}"#
        case .gitStatus: return #"{"path": "<relative path>"}"#
        case .gitDiff: return #"{"path": "<relative path>", "staged": <bool>}"#
        case .gitLog: return #"{"path": "<relative path>", "limit": <int>}"#
        case .gitBranch: return #"{"branch": "<branch name>", "create": <bool>}"#
        case .gitCheckout: return #"{"branch": "<branch name>"}"#
        case .gitCommit: return #"{"message": "<commit message>", "addAll": <bool>}"#
        case .gitPush: return #"{"remote": "<remote name>", "branch": "<branch name>"}"#
        case .gitPull: return #"{"remote": "<remote name>", "branch": "<branch name>"}"#
        case .glob: return #"{"pattern": "<glob pattern>", "path": "<relative path>"}"#
        case .todoRead: return #"{}"#
        case .todoWrite: return #"{"todos": [{"id": "<id>", "content": "<text>", "status": "<pending|in_progress|completed>"}]}"#
        case .task: return #"{"description": "<task description>", "prompt": "<detailed prompt>", "subagentType": "<general|code|debug|review>"}"#
        }
    }

    var description: String {
        switch self {
        case .readFile: return "Read a file's contents."
        case .writeFile: return "Create or overwrite a file."
        case .editFile: return "Replace an exact substring in a file."
        case .listDir: return "List entries of a directory."
        case .grep: return "Search files for a regex pattern."
        case .runCommand: return "Run a shell command (requires approval)."
        case .gitStatus: return "Show git status (modified, staged, untracked files)."
        case .gitDiff: return "Show git diff (staged or unstaged)."
        case .gitLog: return "Show git commit history."
        case .gitBranch: return "List or create git branches."
        case .gitCheckout: return "Switch git branch."
        case .gitCommit: return "Create a git commit."
        case .gitPush: return "Push commits to remote."
        case .gitPull: return "Pull commits from remote."
        case .glob: return "Find files matching a glob pattern."
        case .todoRead: return "Read the current todo list."
        case .todoWrite: return "Write/update the todo list."
        case .task: return "Launch a sub-agent for a complex task (runs in background, returns result)."
        }
    }
}

/// Emulates a tool-calling protocol over a plain web chat that has no native
/// tool support (plan Раздел 12 Блок 2). The model is instructed via a system
/// preamble to emit strict ```tool blocks; we parse them, execute locally, and
/// feed ```tool_result back so it continues — an agentic loop over web chat.
enum WebToolProtocolEmulator {

    /// System preamble teaching the model the strict tool-call format.
    static func systemPreamble(tools: [WebEmulatedTool] = WebEmulatedTool.allCases,
                               userSystemPrompt: String = "") -> String {
        var lines: [String] = []
        if !userSystemPrompt.isEmpty {
            lines.append(userSystemPrompt)
            lines.append("")
        }
        lines.append("You are a local coding agent operating through a web chat model.")
        lines.append("The host application, not the web model, executes tools against the opened project.")
        lines.append("Never claim that a file changed or a command ran until you receive its tool_result.")
        lines.append("")
        lines.append("To use a tool, reply with ONLY this exact fenced block:")
        lines.append("```tool")
        lines.append(#"{"name": "<tool_name>", "args": { ... }}"#)
        lines.append("```")
        lines.append("Wait for the host's ```tool_result block after every call, then continue from that result.")
        lines.append("If a command needs approval, explain the approval requirement; do not pretend it ran.")
        lines.append("When the task is done, reply normally WITHOUT a tool block and summarize actual results.")
        lines.append("")
        lines.append("Available tools and current access:")
        lines.append("- read_file, list_dir, grep, glob: read-only project inspection; available immediately.")
        lines.append("- write_file, edit_file: modify project files; governed by the selected access level and undo history.")
        lines.append("- run_command: executes in the opened project directory only at full access; otherwise approval is returned and nothing runs.")
        lines.append("- git_status, git_diff, git_log, git_branch, git_checkout: inspect or switch project Git state.")
        lines.append("- git_commit, git_push, git_pull: Git operations; use only when explicitly requested and report the result.")
        lines.append("- todo_read, todo_write: maintain the task checklist for this session.")
        lines.append("- task: delegate a complex subtask and wait for its returned result.")
        lines.append("")
        lines.append("For shell work, call run_command with the command. Do not ask the user to copy a command unless the host reports that approval is required.")
        lines.append("")
        lines.append("A large prompt may arrive split across several messages. If a message")
        lines.append("starts with \"[PART x/N — do not answer yet…]\", acknowledge briefly and")
        lines.append("WAIT. Only when you receive \"[FINAL PART N/N — you may now respond]\"")
        lines.append("should you process the whole prompt and reply.")
        lines.append("")
        lines.append("Available tools:")
        for tool in tools {
            lines.append("- \(tool.rawValue): \(tool.description) args: \(tool.argumentSchema)")
        }
        return lines.joined(separator: "\n")
    }

    /// Extract all tool calls from a model response. Tolerant of surrounding
    /// prose and markdown fences (plan Блок 2 п.11/п.13), and — since Round 12 —
    /// also of the informal `[tool call: NAME with args]` syntax that plain web
    /// models actually emit (e.g. `[tool call: LS with path "."]`), so the
    /// agentic loop never stalls on a well-meant but non-strict call.
    static func parseToolCalls(from responseText: String) -> [WebToolCall] {
        var calls: [WebToolCall] = []
        // Find ```tool ... ``` fenced blocks.
        let scanner = responseText as NSString
        let pattern = "```tool\\s*\\n(.*?)\\n```"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) {
            let matches = regex.matches(in: responseText, range: NSRange(location: 0, length: scanner.length))
            for match in matches where match.numberOfRanges >= 2 {
                let jsonString = scanner.substring(with: match.range(at: 1))
                if let call = parseSingleCall(jsonString) {
                    calls.append(call)
                }
            }
        }
        // Then the informal `[tool call: NAME ...]` variant.
        calls.append(contentsOf: parseInformalCalls(from: responseText))
        return calls
    }

    /// Parse `[tool call: NAME with key value / key="value" ...]`.
    private static func parseInformalCalls(from text: String) -> [WebToolCall] {
        let scanner = text as NSString
        let pattern = "\\[tool call:\\s*([^\\]]+)\\]"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }
        var calls: [WebToolCall] = []
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: scanner.length))
        for match in matches where match.numberOfRanges >= 2 {
            let body = scanner.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
            let tokens = body.split(separator: " ", maxSplits: 1).map(String.init)
            guard let rawName = tokens.first, let name = canonicalToolName(rawName) else { continue }
            var argsText = tokens.count > 1 ? tokens[1] : ""
            // Drop the connective "with": "[tool call: LS with path "."]" →
            // args "path \".\"".
            let withPrefix = argsText.trimmingCharacters(in: .whitespaces)
            if withPrefix.hasPrefix("with ") {
                argsText = String(withPrefix.dropFirst(5))
            }
            calls.append(WebToolCall(name: name, arguments: parseInformalArgs(argsText)))
        }
        return calls
    }

    /// Parse `path "."` / `path="."` / `pattern "x"` / `pattern="x"` into [String: String].
    private static func parseInformalArgs(_ text: String) -> [String: String] {
        var args: [String: String] = [:]
        let scanner = text as NSString
        // key="value" OR key "value". Alternation groups: the branch that did
        // NOT match has NSNotFound ranges — guard before substring.
        let quoted = "([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*\\\"([^\\\"]*)\\\"|([A-Za-z_][A-Za-z0-9_]*)\\s+\\\"([^\\\"]*)\\\""
        guard let regex = try? NSRegularExpression(pattern: quoted) else { return args }
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: scanner.length))
        for m in matches where m.numberOfRanges >= 5 {
            if let key = substring(in: m, at: 1, of: scanner),
               let value = substring(in: m, at: 2, of: scanner) {
                args[key] = value
            } else if let key = substring(in: m, at: 3, of: scanner),
                      let value = substring(in: m, at: 4, of: scanner) {
                args[key] = value
            }
        }
        return args
    }

    /// Safe group extraction: returns nil for NSNotFound so the alternation
    /// branches of an NSRegularExpression never crash `substring(with:)`.
    private static func substring(in match: NSTextCheckingResult, at index: Int,
                                  of scanner: NSString) -> String? {
        let range = match.range(at: index)
        guard range.location != NSNotFound, range.length > 0 else { return nil }
        return scanner.substring(with: range)
    }

    /// Map a model's informal tool spelling to the canonical tool name.
    /// Web models write "LS"/"ls" for list_dir, "Read" for read_file, etc.
    /// Unknown names → nil so they surface as `.unknownTool` validation errors
    /// instead of being silently dropped.
    static func canonicalToolName(_ name: String) -> String? {
        let lower = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch lower {
        case "ls", "list_dir", "list", "dir", "directory":
            return WebEmulatedTool.listDir.rawValue
        case "read_file", "read", "cat", "view":
            return WebEmulatedTool.readFile.rawValue
        case "write_file", "write", "create":
            return WebEmulatedTool.writeFile.rawValue
        case "edit_file", "edit", "replace":
            return WebEmulatedTool.editFile.rawValue
        case "grep", "search", "find":
            return WebEmulatedTool.grep.rawValue
        case "run_command", "run", "execute", "shell":
            return WebEmulatedTool.runCommand.rawValue
        // Git operations
        case "git_status", "status", "gs":
            return WebEmulatedTool.gitStatus.rawValue
        case "git_diff", "diff", "gd":
            return WebEmulatedTool.gitDiff.rawValue
        case "git_log", "log":
            return WebEmulatedTool.gitLog.rawValue
        case "git_branch", "branch", "gb":
            return WebEmulatedTool.gitBranch.rawValue
        case "git_checkout", "checkout", "co", "gco":
            return WebEmulatedTool.gitCheckout.rawValue
        case "git_commit", "commit", "gc":
            return WebEmulatedTool.gitCommit.rawValue
        case "git_push", "push", "gp":
            return WebEmulatedTool.gitPush.rawValue
        case "git_pull", "pull", "gl":
            return WebEmulatedTool.gitPull.rawValue
        // File search & glob
        case "glob", "glob_search", "find_files":
            return WebEmulatedTool.glob.rawValue
        case "todo_read", "todos", "todo":
            return WebEmulatedTool.todoRead.rawValue
        case "todo_write", "todo_add", "todo_update":
            return WebEmulatedTool.todoWrite.rawValue
        // Sub-agent / task tool
        case "task", "subagent", "agent", "spawn":
            return WebEmulatedTool.task.rawValue
        default:
            return nil
        }
    }

    private static func parseSingleCall(_ jsonString: String) -> WebToolCall? {
        guard let data = jsonString.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = obj["name"] as? String else {
            return nil
        }
        var args: [String: String] = [:]
        if let rawArgs = obj["args"] as? [String: Any] {
            for (k, v) in rawArgs {
                if let s = v as? String { args[k] = s }
                else { args[k] = "\(v)" }
            }
        }
        return WebToolCall(name: name, arguments: args)
    }

    /// True when a response contains no tool call → the model produced a final answer.
    static func isFinalResponse(_ responseText: String) -> Bool {
        parseToolCalls(from: responseText).isEmpty
    }

    /// Format a tool result to send back to the web chat as the next message
    /// (plan Блок 2 п.14).
    static func formatToolResult(name: String, result: String) -> String {
        """
        ```tool_result
        {"name": "\(name)", "result": \(jsonEncoded(result))}
        ```
        """
    }

    private static func jsonEncoded(_ s: String) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: [s])) ?? Data()
        // Extract the inner string with quotes from ["..."] → "..."
        if let str = String(data: data, encoding: .utf8) {
            let trimmed = str.dropFirst().dropLast()   // remove [ ]
            return String(trimmed)
        }
        return "\"\(s)\""
    }

    /// Whether the agentic loop should stop (plan Блок 2 п.17): either the model
    /// gave a final answer or the iteration limit is reached.
    static func shouldStopLoop(iteration: Int, maxIterations: Int, lastResponse: String) -> Bool {
        iteration >= maxIterations || isFinalResponse(lastResponse)
    }

    /// Validate a tool call's arguments before executing (plan Блок 2 п.18):
    /// paths must stay within the project root UNLESS accessLevel allows broader access;
    /// destructive tools flagged. Returns `nil` when valid, or the specific validation error.
    static func validate(_ call: WebToolCall, projectRoot: String, accessLevel: AccessLevel = .askBeforeChanges) -> WebToolValidationError? {
        guard WebEmulatedTool(rawValue: call.name) != nil else {
            return .unknownTool(call.name)
        }
        // Path boundary check is now permission-based, not hard restriction.
        // At .fullAccess, any path is allowed. At lower levels, restrict to project root.
        if accessLevel != .fullAccess,
           let path = call.arguments["path"],
           !isPathInsideRoot(path, root: projectRoot) {
            return .pathEscapesProject(path)
        }
        return nil
    }

    static func requiresApproval(_ call: WebToolCall) -> Bool {
        call.name == WebEmulatedTool.writeFile.rawValue
            || call.name == WebEmulatedTool.editFile.rawValue
            || call.name == WebEmulatedTool.runCommand.rawValue
    }

    static func isPathInsideRoot(_ path: String, root: String) -> Bool {
        let normalizedRoot = URL(fileURLWithPath: root).standardizedFileURL.path
        let candidate: String
        if path.hasPrefix("/") {
            candidate = URL(fileURLWithPath: path).standardizedFileURL.path
        } else {
            candidate = URL(fileURLWithPath: root).appendingPathComponent(path).standardizedFileURL.path
        }
        return candidate == normalizedRoot || candidate.hasPrefix(normalizedRoot + "/")
    }
}

enum WebToolValidationError: Error, Equatable {
    case pathEscapesProject(String)
    case unknownTool(String)
}
