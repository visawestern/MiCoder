import Foundation

/// Outcome of the access-level gate for one emulated tool call (Раздел 12 п.18).
enum WebToolPermission: Equatable {
    case allow
    case requireApproval
}

/// Maps the app's `AccessLevel` onto the emulated web-tool protocol (Раздел 12
/// п.18). Read-only tools always run; file-mutating tools keep the executor's
/// established behavior (they are executed, with undo + request_history
/// recording — the file-edit approval prompt is a separate UI concern driven
/// by `requiresApproval`); `run_command` — the only tool that can affect the
/// machine outside the project — is gated: it executes only at `.fullAccess`
/// and requires approval at every lower level. The old executor returned a
/// canned "requires approval" message for commands at every level without ever
/// running them; this gate decides *and* the executor enforces it.
enum WebToolAccessGate {

    static func permission(for call: WebToolCall, accessLevel: AccessLevel) -> WebToolPermission {
        switch WebEmulatedTool(rawValue: call.name) {
        case .readFile, .listDir, .grep, .writeFile, .editFile:
            return .allow
        case .runCommand:
            // Shell access is the strongest capability; only full access runs
            // commands without asking (plan Раздел 12 п.18).
            return accessLevel == .fullAccess ? .allow : .requireApproval
        case .none:
            // Unknown tools are allowed past the gate so the executor reports
            // "unknown tool" (the real error) instead of a misleading approval.
            return .allow
        }
    }
}
