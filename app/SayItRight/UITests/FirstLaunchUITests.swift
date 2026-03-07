import XCTest

/// Tests for the first-launch setup flow: API key → language → onboarding.
final class FirstLaunchUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        // Do NOT set hasCompletedOnboarding — we want the first-launch flow
        app.launchArguments += [
            "-hasCompletedOnboarding", "NO",
            "-appLanguage", "en",
        ]
        // No API key override — starts at API key step
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testFirstLaunchShowsAPIKeyScreen() throws {
        app.launch()

        // Should show the API key entry screen
        let title = app.staticTexts["Say it right!"]
        XCTAssertTrue(title.waitForExistence(timeout: 5), "First launch should show 'Say it right!' title")

        // API key text field should exist
        let textField = app.secureTextFields.firstMatch
        XCTAssertTrue(textField.exists, "API key secure field should be visible")
    }

    func testAPIKeyValidation() throws {
        app.launch()

        // Enter an invalid key (no sk-ant- prefix)
        let textField = app.secureTextFields.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("invalid-key")

        // Tap continue
        let continueButton = app.buttons["apiKeyContinueButton"]
        XCTAssertTrue(continueButton.exists)
        continueButton.tap()

        // Should show validation error
        let errorText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'sk-ant-'")).firstMatch
        XCTAssertTrue(errorText.waitForExistence(timeout: 3), "Should show API key format error")
    }

    func testValidAPIKeyAdvancesToLanguage() throws {
        app.launch()

        let textField = app.secureTextFields.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("sk-ant-test-key-12345")

        let continueButton = app.buttons["apiKeyContinueButton"]
        continueButton.tap()

        // Should advance to language selection
        let languageTitle = app.staticTexts["Choose Your Language"]
        XCTAssertTrue(languageTitle.waitForExistence(timeout: 5), "Should show language selection")

        // Both language buttons should exist
        XCTAssertTrue(app.staticTexts["English"].exists)
        XCTAssertTrue(app.staticTexts["Deutsch"].exists)
    }

    func testLanguageSelectionAdvancesToOnboarding() throws {
        app.launch()

        // Enter valid API key
        let textField = app.secureTextFields.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("sk-ant-test-key-12345")
        app.buttons["apiKeyContinueButton"].tap()

        // Wait for language screen
        let languageTitle = app.staticTexts["Choose Your Language"]
        XCTAssertTrue(languageTitle.waitForExistence(timeout: 5))

        // Tap Continue to go to onboarding
        let languageContinue = app.buttons["languageContinueButton"]
        XCTAssertTrue(languageContinue.waitForExistence(timeout: 3))
        languageContinue.tap()

        // Should show Barbara's welcome message (onboarding)
        let barbaraLabel = app.staticTexts["Barbara"]
        XCTAssertTrue(barbaraLabel.waitForExistence(timeout: 5), "Should show Barbara's name in onboarding")
    }
}
