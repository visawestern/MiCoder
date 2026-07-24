import Testing
import Foundation
@testable import MiCoder

@Suite("Sidebar grouping + relative time (plan Раздел 11 Блок 2)")
struct SidebarGroupingLogicTests {

    @Test func modesHaveLabelsAndIcons() {
        #expect(SidebarGroupingMode.group.label == "Group")
        #expect(SidebarGroupingMode.project.label == "Project")
        #expect(!SidebarGroupingMode.group.icon.isEmpty)
        #expect(SidebarGroupingMode.allCases.count == 2)
    }

    @Test func persistenceRoundTrip() {
        let d = UserDefaults(suiteName: "sidebar-grouping-\(UUID().uuidString)")!
        #expect(SidebarGroupingLogic.load(defaults: d) == .group)   // default
        SidebarGroupingLogic.save(.project, defaults: d)
        #expect(SidebarGroupingLogic.load(defaults: d) == .project)
    }

    @Test func relativeTimeLabels() {
        #expect(SidebarGroupingLogic.relativeTimeLabel(elapsedSeconds: 30) == "now")
        #expect(SidebarGroupingLogic.relativeTimeLabel(elapsedSeconds: 5 * 60) == "5m")
        #expect(SidebarGroupingLogic.relativeTimeLabel(elapsedSeconds: 11 * 3600) == "11h")
        #expect(SidebarGroupingLogic.relativeTimeLabel(elapsedSeconds: 25 * 3600) == "1d")
        #expect(SidebarGroupingLogic.relativeTimeLabel(elapsedSeconds: 9 * 86400) == "9d")
    }

    @Test func relativeTimeClampsNegative() {
        #expect(SidebarGroupingLogic.relativeTimeLabel(elapsedSeconds: -100) == "now")
    }
}
