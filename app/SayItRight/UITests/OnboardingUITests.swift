import XCTest

/// Tests for the onboarding flow that appears after first-launch setup.
///
/// Uses a modified launch config that starts at onboarding (API key set,
/// but hasCompletedOnboarding is NO).
final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        // Onboarding not completed, but API key is set
        app.launchArguments += [
            "-hasCompletedOnboarding", "NO",
            "-appLanguage", "en",
        ]
        app.launchEnvironment["ANTHROPIC_API_KEY_OVERRIDE"] = "sk-ant-test-key-for-ui-tests"
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testOnboardingShowsBarbaraName() throws {
        app.launch()

        // Barbara's name should appear in the speech bubble
        let barbaraLabel = app.staticTexts["Barbara"]
        XCTAssertTrue(barbaraLabel.waitForExistence(timeout: 5),
                     "Should show Barbara's name in onboarding")
    }

    func testOnboardingShowsLetsGoButton() throws {
        app.launch()

        // "Let's go!" button should appear after the typing animation
        let letsGoButton = app.buttons["letsGoButton"]
        XCTAssertTrue(letsGoButton.waitForExistence(timeout: 15),
                     "Let's go button should appear after welcome message")
    }

    func testLetsGoAdvancesToAvatarPicker() throws {
        app.launch()

        let letsGoButton = app.buttons["letsGoButton"]
        XCTAssertTrue(letsGoButton.waitForExistence(timeout: 15))
        letsGoButton.tap()

        // Should show the avatar picker with a name field
        let nameField = app.textFields["nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10),
                     "Should show name field in avatar picker phase")
    }

    func testAvatarPickerRequiresNameAndAvatar() throws {
        app.launch()

        let letsGoButton = app.buttons["letsGoButton"]
        XCTAssertTrue(letsGoButton.waitForExistence(timeout: 15))
        letsGoButton.tap()

        let nameField = app.textFields["nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))

        // Continue button should NOT exist yet (no avatar selected, no name)
        let continueButton = app.buttons["avatarContinueButton"]
        XCTAssertFalse(continueButton.exists,
                      "Continue button should not appear without name and avatar")

        // Type a name
        nameField.tap()
        nameField.typeText("TestUser")

        // Still no continue button (no avatar selected)
        XCTAssertFalse(continueButton.exists,
                      "Continue button should not appear without avatar")
    }
}
