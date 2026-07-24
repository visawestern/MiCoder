import Testing
@testable import MiCoder

@Suite("Spoiler Expand Logic")
struct SpoilerExpandLogicTests {

    @Test("Collapsed spoiler has zero height and opacity")
    func collapsedState() {
        #expect(SpoilerExpandLogic.contentHeight(isExpanded: false, measuredHeight: 500) == 0)
        #expect(SpoilerExpandLogic.contentOpacity(isExpanded: false) == 0)
    }

    @Test("Expanded spoiler fits short content instead of forcing max height")
    func expandedFitsShortContent() {
        let height = SpoilerExpandLogic.contentHeight(isExpanded: true, measuredHeight: 40)
        #expect(height == 40)
        #expect(SpoilerExpandLogic.contentOpacity(isExpanded: true) == 1)
    }

    @Test("Expanded spoiler caps long content at max height")
    func expandedCapsAtMax() {
        let height = SpoilerExpandLogic.contentHeight(isExpanded: true, measuredHeight: 2000)
        #expect(height == SpoilerExpandLogic.contentMaxHeight)
    }

    @Test("Unmeasured content falls back to max height while expanding")
    func unmeasuredFallsBackToMax() {
        let height = SpoilerExpandLogic.contentHeight(isExpanded: true, measuredHeight: 0)
        #expect(height == SpoilerExpandLogic.contentMaxHeight)
    }
}
