import Testing
import Foundation
@testable import MiCoder

@Suite("Settings Provider Layout")
struct SettingsProviderLayoutTests {

    private static func settingsViewSource() throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/Views/SettingsView.swift")
        return try String(contentsOf: url, encoding: .utf8)
    }

    @Test("Provider type picker is not segmented (10 cases overflow a 480pt sheet)")
    func providerTypePickerNotSegmented() throws {
        let source = try Self.settingsViewSource()
        guard let sheetRange = source.range(of: "struct AddProviderSheet") else {
            Issue.record("AddProviderSheet not found")
            return
        }
        let sheetSource = String(source[sheetRange.lowerBound...])
        let firstPickerEnd = sheetSource.range(of: ".onChange(of: type)")?.lowerBound ?? sheetSource.endIndex
        let typePickerRegion = String(sheetSource[..<firstPickerEnd])
        #expect(
            !typePickerRegion.contains(".pickerStyle(.segmented)"),
            "Provider type picker must use a menu style; segmented control with \(ProviderType.allCases.count) cases overflows the dialog"
        )
    }

    @Test("Provider type count is too large for a segmented control")
    func providerTypeCountIsLarge() {
        #expect(ProviderType.allCases.count >= 8)
    }

    @Test("Custom provider card truncates provider name and URL")
    func customProviderCardTruncates() throws {
        let source = try Self.settingsViewSource()
        guard let cardRange = source.range(of: "struct CustomProviderCard") else {
            Issue.record("CustomProviderCard not found")
            return
        }
        let cardEnd = source.range(of: "struct AddProviderSheet")?.lowerBound ?? source.endIndex
        let cardSource = String(source[cardRange.lowerBound..<cardEnd])
        #expect(cardSource.contains("lineLimit"), "Provider card texts must be line-limited to avoid overflow")
    }
}
