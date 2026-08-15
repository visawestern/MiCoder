#!/usr/bin/env python3
"""Round 106 localization regressions.

This is intentionally source-level because SwiftUI/AppKit cannot run in the
Linux sandbox. It protects the language-selection chain and user-visible
screens that were confirmed to bypass the selected language.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def source(relative: str) -> str:
    return (ROOT / relative).read_text()

runtime = source("MiCoder/Sources/Services/LocalizationRuntime.swift")
app_localization = source("MiCoder/Sources/Services/AppLocalization.swift")

# Raw-string runtime localization must resolve through the complete selected-
# language catalog, not through a Russian-only switch with English fallback.
assert "AppLocalization.string(forEnglish:" in runtime
assert "case .russian:\n            return russian[key] ?? key" not in runtime
assert "static func string(forEnglish" in app_localization

# The following user-visible callsites were confirmed to bypass localization.
required_keys = {
    "locSearchLanguage",
    "locOtherAnswer",
    "locCaptchaVerification",
    "locCaptchaInstruction",
    "locDetectionFailed",
    "locNoEffort",
    "locInAppBrowser",
    "locAskMiCoderAutoFree",
    "locModelParameters",
    "locNoModelsMatchFilter",
    "locSaveParameters",
    "locProviderParameters",
    "locChooseFromList",
    "locFreeModelsPrivacy",
    "locLockSelectedModel",
    "locNoEligibleFreeModels",
    "locSavePrompt",
    "locStorageImportReplace",
    "locStorageImportWarning",
    "locStorageExportConfiguration",
    "locStorageImportConfiguration",
    "locCancelDeletion",
    "locProjectRegistryDeletionWarning",
    "locAllWorkspaces",
    "locProjectFiles",
    "locSearchTasks",
}
for key in required_keys:
    assert f"case {key}" in app_localization, f"missing enum key {key}"
    assert f'"{key}": [' in app_localization, f"missing translations for {key}"

file_requirements = {
    "MiCoder/Sources/Views/Components/LanguagePickerDropdown.swift": [
        'L.t(AppLocalizationKey.locSearchLanguage)',
    ],
    "MiCoder/Sources/Views/Components/PlanQuestionCardView.swift": [
        'L.t(AppLocalizationKey.locOtherAnswer)',
    ],
    "MiCoder/Sources/Views/Components/WebCaptchaSolverView.swift": [
        'L.t(AppLocalizationKey.locCaptchaVerification)',
        'L.t(AppLocalizationKey.locCaptchaInstruction)',
    ],
    "MiCoder/Sources/Views/Components/WebProvidersSection.swift": [
        'L.t(AppLocalizationKey.locDetectionFailed)',
        'L.t(AppLocalizationKey.locNoEffort)',
        'L.t(AppLocalizationKey.locInAppBrowser)',
        'L.t(AppLocalizationKey.locAskMiCoderAutoFree)',
    ],
    "MiCoder/Sources/Views/Settings/ModelSettingsView.swift": [
        'L.t(AppLocalizationKey.locModelParameters)',
        'L.t(AppLocalizationKey.locNoModelsMatchFilter)',
        'L.t(AppLocalizationKey.locSaveParameters)',
    ],
    "MiCoder/Sources/Views/Settings/ProvidersSettingsView.swift": [
        'L.t(AppLocalizationKey.locProviderParameters)',
        'L.t(AppLocalizationKey.locChooseFromList)',
        'L.t(AppLocalizationKey.locFreeModelsPrivacy)',
        'L.t(AppLocalizationKey.locLockSelectedModel)',
        'L.t(AppLocalizationKey.locNoEligibleFreeModels)',
        'L.t(AppLocalizationKey.locSavePrompt)',
    ],
    "MiCoder/Sources/Views/Settings/StorageSettingsView.swift": [
        'L.t(AppLocalizationKey.locStorageImportReplace)',
        'L.t(AppLocalizationKey.locStorageImportWarning)',
        'L.t(AppLocalizationKey.locStorageExportConfiguration)',
        'L.t(AppLocalizationKey.locStorageImportConfiguration)',
        'L.t(AppLocalizationKey.locCancelDeletion)',
        'L.t(AppLocalizationKey.locProjectRegistryDeletionWarning)',
    ],
    "MiCoder/Sources/Views/SidebarView.swift": [
        'L.t(AppLocalizationKey.locAllWorkspaces)',
        'L.t(AppLocalizationKey.locProjectFiles)',
        'L.t(AppLocalizationKey.locSearchTasks)',
    ],
}
for relative, needles in file_requirements.items():
    text = source(relative)
    for needle in needles:
        assert needle in text, f"{relative} does not use {needle}"

# Representative bypasses must not return after the fix.
for relative, raw in {
    "MiCoder/Sources/Views/Components/LanguagePickerDropdown.swift": 'TextField("Search language"',
    "MiCoder/Sources/Views/Components/PlanQuestionCardView.swift": 'TextField("Other answer"',
    "MiCoder/Sources/Views/Components/WebCaptchaSolverView.swift": 'Text("Captcha verification")',
    "MiCoder/Sources/Settings/ModelSettingsView.swift": 'Text("Provider metadata")',
}.items():
    path = ROOT / relative
    if path.exists():
        assert raw not in path.read_text(), f"raw localized UI literal returned: {relative}: {raw}"

# Every newly introduced key must carry all supported language entries.
language_codes = ("en", "ru", "es", "fr", "de", "zh", "ja", "ko", "pt", "ar")
for key in required_keys | {
    "locNewBranchName", "locFileAttached", "locFilesAttached", "locPhotoAttached", "locPhotosAttached",
    "locCookiesCount", "locWebModelsFoundCount", "locApiEndpointURL", "locInvalidEndpoint",
    "locNoZenKeyDescription", "locOpenCodeZen", "locActiveCount", "locArchivedCount", "locMessagesCount",
    "locCustomProviders", "locBuiltInProviders", "locAddOrSelectOpenCodeZen",
    "locOpenCodeZenApiKeyOptional", "locSecretKeyPlaceholder", "locProjectDatabaseCorrupted",
    "locNoBackupFound", "locDatabaseRestored", "locRestoreFailed", "locIntegrityCheckFailed",
    "locProjectPathPlaceholder", "locChooseProjectFolder", "locActions", "locFreeModelRateLimitMessage",
    "locFreeModelSwitchedMessage", "locTaskCompleteMessage", "locGitOperation", "locPreviousModel",
    "locAnotherFreeModel", "locProviderError", "locFreeModelRateLimited", "locServerDisconnected",
    "locServerConnected", "locSessionBusy", "locEffortValue", "locTemplates", "locContextValue",
    "locLock", "locUnlock", "locReplaceAppConfiguration", "locDeletingProjectData",
}:
    marker = f'"{key}": ['
    line = next((line for line in app_localization.splitlines() if marker in line), "")
    assert line, f"missing dictionary row for {key}"
    for language in language_codes:
        assert f'"{language}":' in line, f"{key} missing {language} translation"

for relative, needles in {
    "MiCoder/Sources/Views/BottomPanelView.swift": ["L.t(AppLocalizationKey.locNewBranchName"],
    "MiCoder/Sources/Views/Components/InputViews.swift": ["L.t(AppLocalizationKey.locFileAttached", "L.t(AppLocalizationKey.locPhotosAttached"],
    "MiCoder/Sources/Views/Settings/UsageSettingsView.swift": ["L.t(AppLocalizationKey.locMessagesCount"],
    "MiCoder/Sources/App/MiCoderApp.swift": ["L.t(AppLocalizationKey.locCut", "L.t(AppLocalizationKey.locActions"],
    "MiCoder/Sources/Views/ContentView.swift": ["L.t(AppLocalizationKey.locIntegrityCheckFailed"],
    "MiCoder/Sources/Views/NewProjectSheet.swift": ["L.t(AppLocalizationKey.locProjectPathPlaceholder"],
    "MiCoder/Sources/Services/NotificationService.swift": ["L.t(AppLocalizationKey.locFreeModelRateLimitMessage"],
}.items():
    text = source(relative)
    for needle in needles:
        assert needle in text, f"{relative} missing {needle}"

print("Round 106 localization source acceptance: PASS")
