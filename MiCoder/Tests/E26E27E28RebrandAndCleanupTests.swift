import Testing
import Foundation
@testable import MiCoder

/// Round 23 (E26/E27/E28 — Раздел 13 п.7/п.11 + Раздел 1 п.7 + clean-slate rule):
/// user-facing "MiMo" brand strings must be gone, the overview sheet must not
/// be titled "Workspaces", and dead production code must be removed, not kept.
/// Source-inspection tests match the existing repo pattern (Round 7 B6) —
/// they fail on the current state and pass after the fixes.
@Suite("E26/E27/E28 — rebrand strings, overview title, dead code (Round 23)")
struct E26E27E28RebrandAndCleanupTests {

    // MARK: - E26 (Раздел 13 п.11): user-facing MiMo brand strings

    @Test("no 'MiMo Agent' command-file copy remains in Settings")
    func noMiMoAgentCopy() throws {
        let s = try RepoRoot.sourceText("MiCoder/Sources/Views/SettingsView.swift")
        #expect(!s.contains("Manage MiMo Agent"),
                "SettingsView still shows the pre-rebrand 'Manage MiMo Agent …' copy")
    }

    @Test("local provider description no longer names MiMo CLI/Serve")
    func noMiMoCLIServeCopy() throws {
        let s = try RepoRoot.sourceText("MiCoder/Sources/Views/SettingsView.swift")
        #expect(!s.contains("MiMo CLI/Serve"),
                "SettingsView still advertises the old 'MiMo CLI/Serve' brand")
    }

    @Test("auto-commit message no longer says 'from MiMo'")
    func noMiMoCommitMessage() throws {
        let s = try RepoRoot.sourceText("MiCoder/Sources/Views/BottomPanelView.swift")
        #expect(!s.contains("Auto-commit from MiMo"),
                "BottomPanelView still stamps commits with the old brand")
    }

    // MARK: - E27 (Раздел 13 п.7): overview sheet title

    @Test("workspace overview sheet is not titled 'Workspaces'")
    func overviewSheetNotTitledWorkspaces() throws {
        let s = try RepoRoot.sourceText("MiCoder/Sources/Views/SidebarView.swift")
        #expect(!s.contains("Text(\"Workspaces\")"),
                "SidebarView still titles the overview sheet 'Workspaces'")
    }

    // MARK: - E28 (Раздел 1 п.7 / clean-slate): dead production code

    @Test("no dead neutralizeServeBranding production code remains")
    func noNeutralizeServeBrandingDeadCode() throws {
        let s = try RepoRoot.sourceText("MiCoder/Sources/Services/LocalProviderConfig.swift")
        #expect(!s.contains("neutralizeServeBranding"),
                "neutralizeServeBranding is defined but never called — dead code must be removed")
    }
}
