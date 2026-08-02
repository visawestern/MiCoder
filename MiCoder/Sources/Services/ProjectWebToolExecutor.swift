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
}
