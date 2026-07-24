import Testing
import Foundation
@testable import MiCoder

@Suite("Edit Shortcuts")
struct EditShortcutsTests {

    @Test("Edit menu replacement keeps Select All (Cmd+A)")
    func selectAllPresentInEditMenu() throws {
        let app = try sourceText("MiCoder/Sources/App/MiCoderApp.swift")
        // Replacing .pasteboard drops the standard Select All item; it must be re-added,
        // otherwise Cmd+A is dead in every text field.
        #expect(app.contains("Select All"))
        #expect(app.contains(#"keyboardShortcut("a", modifiers: .command)"#))
        #expect(app.contains("selectAll"))
    }

    @Test("Cut/Copy/Paste remain wired after menu replacement")
    func cutCopyPasteRemain() throws {
        let app = try sourceText("MiCoder/Sources/App/MiCoderApp.swift")
        #expect(app.contains(#"keyboardShortcut("x", modifiers: .command)"#))
        #expect(app.contains(#"keyboardShortcut("c", modifiers: .command)"#))
        #expect(app.contains(#"keyboardShortcut("v", modifiers: .command)"#))
    }

    @Test("Prompt text views enable undo (Cmd+Z)")
    func promptTextViewsAllowUndo() throws {
        let zeroInset = try sourceText("MiCoder/Sources/Views/Components/ZeroInsetTextField.swift")
        #expect(zeroInset.contains("allowsUndo = true"))

        let pasteAware = try sourceText("MiCoder/Sources/Views/Components/PasteAwareTextField.swift")
        #expect(pasteAware.contains("allowsUndo = true"))
    }

    private func sourceText(_ relativePath: String) throws -> String {
        try RepoRoot.sourceText(relativePath)
    }
}
