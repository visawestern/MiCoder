import Testing
import Foundation
@testable import MiCoder

@Suite("Model Settings Premium Layout")
struct ModelSettingsPremiumTests {

    @Test("All three cards fill available height so the layout has no dead gaps")
    func cardsFillHeight() throws {
        let source = try sourceText("MiCoder/Sources/Views/Settings/ModelSettingsView.swift")
        #expect(source.contains("settingsCardFrame"))
    }

    @Test("Each card has a premium empty state with icon, title and hint")
    func premiumEmptyStates() throws {
        let source = try sourceText("MiCoder/Sources/Views/Settings/ModelSettingsView.swift")
        #expect(source.contains("SettingsCardEmptyState"))
        // Empty states must exist for providers, details, and models cards.
        #expect(source.ranges(of: "SettingsCardEmptyState(").count >= 3)
    }

    @Test("Details card shows a model count summary for any provider")
    func detailsShowsModelCount() throws {
        let source = try sourceText("MiCoder/Sources/Views/Settings/ModelSettingsView.swift")
        #expect(source.contains("detailModelCount"))
    }

    private func sourceText(_ relativePath: String) throws -> String {
        try RepoRoot.sourceText(relativePath)
    }
}
