import Foundation
import Testing
@testable import MiCoder

@Suite("SID-07: sidebar session visibility")
struct SidebarSessionLimitLogicTests {
    @Test("shows twelve sessions when a workspace has at least twelve")
    func showsUpToTwelveSessions() {
        let sessions = Array(0..<20)
        #expect(SidebarSessionLimitLogic.visible(sessions).count == 12)
        #expect(SidebarSessionLimitLogic.visible(sessions) == Array(0..<12))
    }

    @Test("does not fabricate rows for fewer sessions")
    func keepsShortListsIntact() {
        let sessions = Array(0..<3)
        #expect(SidebarSessionLimitLogic.visible(sessions) == sessions)
        #expect(SidebarSessionLimitLogic.visible([Int]()).isEmpty)
    }

    @Test("the limit is explicit and not an accidental magic number")
    func limitIsDocumentedInLogic() {
        #expect(SidebarSessionLimitLogic.maximumVisible == 12)
    }
}
