import Testing
@testable import MiCoder

@Suite("MiMo Copy")
struct MiMoCopyTests {
    
    @Test("Prompt placeholder uses MiMo branding")
    func promptPlaceholder() {
        #expect(MiMoCopy.promptPlaceholder(language: .english).contains("Ask MiMo anything"))
        #expect(!MiMoCopy.promptPlaceholder(language: .english).contains("ZCode"))
    }
    
    @Test("Follow-up placeholder is set")
    func followUpPlaceholder() {
        #expect(MiMoCopy.followUpPlaceholder(language: .english) == "Ask for follow-up changes")
    }
    
    @Test("Watermark text is mi")
    func watermark() {
        #expect(MiMoCopy.watermarkText == "mi")
    }
    
    @Test("Empty state title includes workspace name")
    func emptyStateTitle() {
        #expect(MiMoCopy.emptyStateTitle(workspaceName: "mimo-macos", language: .english) == "Start a new task in mimo-macos")
    }
}
