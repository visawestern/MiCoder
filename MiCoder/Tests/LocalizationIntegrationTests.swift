import XCTest
@testable import MiCoder

/// TDD: localization infrastructure must resolve strings in the current language.
/// Red test: before integration, hardcoded strings are not localized.
final class LocalizationIntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        LocalizationRuntime.currentLanguage = .english
    }

    func testEnglishReturnsKeyAsIs() {
        LocalizationRuntime.currentLanguage = .english
        let result = L.t("New task")
        XCTAssertEqual(result, "New task")
    }

    func testRussianReturnsTranslation() {
        LocalizationRuntime.currentLanguage = .russian
        let result = L.t("New task")
        XCTAssertEqual(result, "Новая задача")
    }

    func testMissingKeyReturnsKeyAsIs() {
        LocalizationRuntime.currentLanguage = .russian
        let result = L.t("UNKNOWN_KEY_THAT_DOES_NOT_EXIST")
        XCTAssertEqual(result, "UNKNOWN_KEY_THAT_DOES_NOT_EXIST")
    }

    func testFormatArgsWork() {
        LocalizationRuntime.currentLanguage = .russian
        let result = L.t("Tool-call delay: %d ms", 800)
        XCTAssertEqual(result, "Задержка вызова инструментов: 800 мс")
    }

    func testSidebarStringsAreLocalized() {
        LocalizationRuntime.currentLanguage = .russian
        XCTAssertEqual(L.t("New task"), "Новая задача")
        XCTAssertEqual(L.t("Search"), "Поиск")
    }

    func testSettingsStringsAreLocalized() {
        LocalizationRuntime.currentLanguage = .russian
        XCTAssertEqual(L.t("Models"), "Модели")
        XCTAssertEqual(L.t("Providers"), "Провайдеры")
    }
}
