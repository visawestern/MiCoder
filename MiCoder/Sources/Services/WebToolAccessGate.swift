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
        // Shell access — strongest capability, only at fullAccess
        case .runCommand:
            return accessLevel == .fullAccess ? .allow : .requireApproval
        // Sub-agent task tool
        case .task:
            return accessLevel == .askBeforeChanges ? .requireApproval : .allow
        case .none:
            return .allow
        }
    }
}
