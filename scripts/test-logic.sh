#!/bin/bash
# Quick re-sync of the Foundation-only test package and run tests.
# Usage: scripts/test-logic.sh [swift test args]
set -e
export PATH=/opt/swift-6.0.3-RELEASE-ubuntu24.04/usr/bin:$PATH
REPO=~/.cache/openresearch/repos/visawestern/mimo-macos-de098ca6
PKG=/tmp/opencode/mimo-logic-test

# Recreate the ephemeral package skeleton if /tmp was cleared.
mkdir -p "$PKG/Sources/MiMoLogic" "$PKG/Tests/MiMoLogicTests"
[ -d "$PKG/Sources/MiMoLogic/Resources" ] || cp -r "$REPO/MiCoder/Sources/Resources" "$PKG/Sources/MiMoLogic/Resources"
if [ ! -f "$PKG/Package.swift" ]; then
cat > "$PKG/Package.swift" <<'PKGEOF'
// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "MiCoder",
    platforms: [.macOS(.v13)],
    products: [.library(name: "MiCoder", targets: ["MiCoder"])],
    targets: [
        .target(name: "MiCoder", path: "Sources/MiMoLogic", resources: [.process("Resources")]),
        .testTarget(name: "MiCoderTests", dependencies: ["MiCoder"], path: "Tests/MiMoLogicTests")
    ]
)
PKGEOF
fi
# Test-only stub for PlusMenuItem (real one has UI deps).
cat > "$PKG/Sources/MiMoLogic/PlusMenuItemStub.swift" <<'STUBEOF'
import Foundation
enum PlusMenuItem: String, CaseIterable, Equatable {
    case addAttachment, addPhoto, insertMention, insertCommand, insertSession
}
STUBEOF

# Foundation-only source files (Services that import only Foundation)
SOURCES=(
  SidebarResizeLogic SlashCommandRegistry InputCommandTriggerLogic
  ProviderAutoDetector AgentResourceCatalog AgentResourceInstaller
  AgentResourcesLoader AgentResourceRegistryManager StorageResetLogic
  ACPMessageBuilder ACPMessageTypes
  WebProviderConfig WebToolProtocolEmulator WebSessionLogic WebPromptChunker WebProviderConnectivity WebModelListParser WebChatEventPresenter SendRouteResolver DirectChatClient ProjectWebToolExecutor ChatHistoryBuilder ProjectFilesCacheLogic
  BrowserAutomationBridge WebChatDriver WebSessionManager
  LocalProviderConfig ProviderOption SlashCommandExecutor ModelCallParameters DropdownKeyboardLogic LegacyDataMigrator InputDropdownDataSource SidebarGroupingLogic ProjectFileIndexLogic ProjectFileScanner UsageStatisticsAggregator ProjectRegistryLogic AppLocalization LanguagePickerLogic
)
# Files located under Models/ instead of Services/
MODEL_SOURCES=( SettingsTab Settings )
for f in "${SOURCES[@]}"; do
  ln -sf "$REPO/MiCoder/Sources/Services/$f.swift" "$PKG/Sources/MiMoLogic/$f.swift"
done
for f in "${MODEL_SOURCES[@]}"; do
  ln -sf "$REPO/MiCoder/Sources/Models/$f.swift" "$PKG/Sources/MiMoLogic/$f.swift"
done

# Foundation-only test files
TESTS=(
  SidebarResizeLogicTests SlashCommandRegistryTests InputCommandTriggerTests
  ProviderAutoDetectorTests AgentResourceInstallerTests
  AgentResourceRegistryManagerTests StorageResetLogicTests ACPMessageBuilderTests
  WebProviderTests WebChatDriverTests WebPromptChunkerTests WebProviderConnectivityTests WebModelListParserTests WebChatEventPresenterTests SendRoutingTests ProjectWebToolExecutorTests ChatHistoryBuilderTests ProjectFilesCacheLogicTests LocalProviderConfigTests SlashCommandExecutorTests ModelCallParametersTests DropdownKeyboardLogicTests LegacyDataMigratorTests InputDropdownDataSourceTests SidebarGroupingLogicTests ProjectFileIndexLogicTests ProjectFileScannerTests UsageStatisticsAggregatorTests ProjectRegistryLogicTests LanguagePickerLogicTests RepoRoot RepoRootTests
)
for f in "${TESTS[@]}"; do
  ln -sf "$REPO/MiCoder/Tests/$f.swift" "$PKG/Tests/MiMoLogicTests/$f.swift"
done

cd "$PKG"
swift test --no-parallel "$@"
