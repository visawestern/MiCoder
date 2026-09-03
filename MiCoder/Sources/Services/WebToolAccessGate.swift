import Foundation

/// Outcome of the access-level gate for one emulated tool call (Раздел 12 п.18).
enum WebToolPermission: Equatable {
    case allow
    case requireApproval
}

/// Maps the app's `AccessLevel` onto the emulated web-tool protocol (Раздел 12
/// п.18). Read-only tools always run; file-mutating tools require an explicit
/// approval interruption at `askBeforeChanges` and execute with undo +
/// request_history recording at higher edit levels; `run_command` — the only tool that can affect the
/// machine outside the project — is gated: it executes only at `.fullAccess`
/// and requires approval at every lower level. The old executor returned a
/// canned "requires approval" message for commands at every level without ever
/// running them; this gate decides *and* the executor enforces it.
enum WebToolAccessGate {

    static func permission(for call: WebToolCall, accessLevel: AccessLevel) -> WebToolPermission {
        switch WebEmulatedTool(rawValue: call.name) {
        // Read-only tools — always allowed
        case .readFile, .listDir, .grep, .gitStatus, .gitDiff, .gitLog, .glob, .todoRead:
            return .allow
        // File-modifying tools — ask before mutating; higher edit levels allow
        // execution after the user has chosen the corresponding global policy.
        case .writeFile, .editFile, .todoWrite:
            return accessLevel == .askBeforeChanges ? .requireApproval : .allow
        // Git mutating operations
        case .gitBranch, .gitCheckout, .gitCommit, .gitPush, .gitPull:
            return accessLevel == .askBeforeChanges ? .requireApproval : .allow
        // Shell access — strongest capability, only at fullAccess. Read-only
        // commands (pwd, whoami, echo, ls, cat, grep, ...) are safe at any level
        // and always run; anything that can mutate the machine still requires
        // fullAccess (or an explicit approval at lower levels).
        case .runCommand:
            if isReadOnlyCommand(call.arguments["command"] ?? "") {
                return .allow
            }
            return accessLevel == .fullAccess ? .allow : .requireApproval
        // Sub-agent task tool
        case .task:
            return accessLevel == .askBeforeChanges ? .requireApproval : .allow
        case .none:
            return .allow
        }
    }

    /// Whether a shell command only inspects the environment and cannot mutate
    /// the machine (no file writes, package installs, git mutations, process
    /// kills, network changes, etc.). Used so read-only commands like
    /// `pwd && whoami && uname -a` run at any access level, while anything
    /// that can change state still requires fullAccess. Arguments are scanned
    /// respecting quotes; only each sub-command's first word matters.
    static func isReadOnlyCommand(_ command: String) -> Bool {
        let safe: Set<String> = [
            "pwd", "whoami", "uname", "echo", "printf", "ls", "dir", "cat",
            "head", "tail", "wc", "grep", "rg", "awk", "sort", "uniq", "cut",
            "tr", "date", "uptime", "env", "printenv", "which", "type",
            "basename", "dirname", "realpath", "true", "false", "clear",
            "hostname", "id", "groups", "who", "ps", "df", "du", "free",
            "time", "xargs", "sleep", "help", "--help", "-h",
        ]
        let readOnlyGit: Set<String> = [
            "status", "log", "diff", "show", "branch", "stash", "remote",
            "ls-files", "config", "rev-parse", "rev-list", "symbolic-ref", "tag",
        ]

        var inQuote: Character?
        var current = ""
        var words: [String] = []
        var subcommands: [[String]] = []

        func flushWord() {
            let trimmed = current.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty { words.append(trimmed) }
            current = ""
        }
        func flushSub() {
            flushWord()
            if !words.isEmpty {
                subcommands.append(words)
                words = []
            }
        }

        for ch in command {
            if let quote = inQuote {
                if ch == quote { inQuote = nil }
                current.append(ch)
            } else if ch == "\"" || ch == "'" || ch == "`" {
                inQuote = ch
            } else if ch == "&" || ch == ";" || ch == "|" || ch == "\n" {
                flushSub()
            } else if ch == " " || ch == "\t" {
                flushWord()
            } else {
                current.append(ch)
            }
        }
        flushSub()

        guard !subcommands.isEmpty else { return true }
        for sub in subcommands where !sub.isEmpty {
            let cmd = sub[0].lowercased()
            if cmd.hasPrefix("-") { continue }          // flag-only invocation (e.g. `-x e`)
            if safe.contains(cmd) { continue }
            if cmd == "git", sub.count > 1, readOnlyGit.contains(sub[1].lowercased()) {
                continue
            }
            return false
        }
        return true
    }
}
