import Testing
@testable import MiCoder

@Suite("App localization")
struct AppLocalizationTests {

    @Test("English and Russian differ for settings title")
    func localizedSettingsTitle() {
        let en = AppLocalization.string(.settingsGeneralTitle, language: .english)
        let ru = AppLocalization.string(.settingsGeneralTitle, language: .russian)
        #expect(en == "General")
        #expect(ru == "Общие")
        #expect(en != ru)
    }

    @Test("Prompt placeholder switches with language")
    func localizedPrompt() {
        let en = MiMoCopy.promptPlaceholder(language: .english)
        let ru = MiMoCopy.promptPlaceholder(language: .russian)
        #expect(en.contains("Ask MiMo"))
        #expect(ru.contains("Спросите"))
    }

    @Test("Parses stored language")
    func parsesLanguage() {
        #expect(AppLanguage.from(stored: "Russian") == .russian)
        #expect(AppLanguage.from(stored: "unknown") == .english)
    }

    @Test("GitHub publish wizard strings localized in both languages")
    func gitPublishWizardStrings() {
        let keys: [AppLocalizationKey] = [
            .gitInstallGHTitle, .gitInstallGHSubtitle, .gitInstallGHButton,
            .gitSignInTitle, .gitSignInSubtitle, .gitSignInButton,
            .gitCreateAndPush, .gitCancel, .gitInitSubtitle,
            .gitReviewComment, .gitReviewCommentPlaceholder, .gitReviewSummary,
            .gitCommitAndPush, .gitOpenGitHubDocs,
        ]
        for key in keys {
            let en = AppLocalization.string(key, language: .english)
            let ru = AppLocalization.string(key, language: .russian)
            #expect(!en.isEmpty)
            #expect(!ru.isEmpty)
        }
        #expect(AppLocalization.string(.gitSignInButton, language: .english) == "Sign in with browser")
        #expect(AppLocalization.string(.gitCommitAndPush, language: .russian) == "Коммит и пуш")
    }
}
