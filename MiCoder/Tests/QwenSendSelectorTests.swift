import Testing
import Foundation
@testable import MiCoder

/// Round 30 — live user-pipeline finding: Qwen's `.message-input-right-button-send`
/// is a DIV wrapper whose programmatic click() is a no-op; only the INNER
/// `<button class="send-button">` actually submits. The sendButton selector must
/// therefore target the inner button BEFORE any wrapper.
@Suite("Round 30 — Qwen sendButton selector targets the real button first")
struct QwenSendSelectorTests {

    private func qwenSendButton() throws -> String {
        let entry = try WebProviderCatalog.loadBundled().selectors(for: "qwen")
        return entry?.sendButton ?? ""
    }

    @Test("first selector candidate is an inner <button>, not the div wrapper")
    func innerButtonComesFirst() throws {
        let selector = try qwenSendButton()
        #expect(!selector.isEmpty, "catalog must define a qwen sendButton")
        let first = selector.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
        #expect(first.contains("button"),
                "first candidate must match a <button> element (wrapper div clicks are no-ops), got: '\(first)'")
    }

    @Test("wrapper fallback is still present for older page versions")
    func wrapperFallbackRetained() throws {
        let selector = try qwenSendButton()
        #expect(selector.contains(".message-input-right-button-send"),
                "old wrapper must remain as a later fallback")
    }
}
