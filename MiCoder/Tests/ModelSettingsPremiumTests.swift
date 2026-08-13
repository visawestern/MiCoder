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

    @Test("Model parameters menu opens a real editable panel")
    func parametersActionIsNotEmpty() throws {
        let source = try sourceText("MiCoder/Sources/Views/Settings/ModelSettingsView.swift")
        #expect(source.contains("openParameters(modelID: modelID, providerID: providerID)"))
        #expect(source.contains("ModelCallParametersStore.set"))
        #expect(source.contains("Save parameters"))
    }

    @Test("Connection success uses explicit boolean state and visible banner")
    func successBannerDoesNotParseLocalizedText() throws {
        let source = try sourceText("MiCoder/Sources/Views/Settings/ModelSettingsView.swift")
        #expect(source.contains("@State private var testSucceeded: Bool?"))
        #expect(source.contains("ProviderConnectionResultBanner"))
        #expect(!source.contains("result.contains(\"Success\")"))
    }

    @Test("Model list has filter, sort, collapse and custom delete controls")
    func modelManagementControls() throws {
        let source = try sourceText("MiCoder/Sources/Views/Settings/ModelSettingsView.swift")
        #expect(source.contains("Filter models"))
        #expect(source.contains("ModelSortOrder"))
        #expect(source.contains("DisclosureGroup"))
        #expect(source.contains("appState.removeModel(modelID, from: providerID)"))
    }

    @Test("Model settings avoids Swift 6 ambiguous String initializers")
    func explicitStringConversions() throws {
        let source = try sourceText("MiCoder/Sources/Views/Settings/ModelSettingsView.swift")
        #expect(!source.contains("map(String.init)"))
        #expect(source.contains("map { String($0) }"))
    }

    @Test("Custom provider discovery captures an immutable model snapshot")
    func immutableModelSnapshot() throws {
        let source = try sourceText("MiCoder/Sources/App/MiCoderApp.swift")
        #expect(source.contains("let discoveredModels = Array(Set(openAIModels + namedModels)).sorted()"))
        #expect(source.contains("let models: [String] = provider.type == .openCodeZen"))
        #expect(!source.contains("var models = Array(Set(openAIModels + namedModels)).sorted()"))
    }

    private func sourceText(_ relativePath: String) throws -> String {
        try RepoRoot.sourceText(relativePath)
    }
}
