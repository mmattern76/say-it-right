import XCTest

/// Base class for Say it right! UI tests.
///
/// Sets up the app with launch arguments to bypass API key validation
/// and onboarding, placing the user directly on the session picker.
class SayItRightUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        // Set UserDefaults to bypass first-launch setup
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-appLanguage", "en",
            "-displayName", "TestUser",
        ]
        // Set a fake API key via launch environment so effectiveAPIKey is non-nil
        app.launchEnvironment["ANTHROPIC_API_KEY_OVERRIDE"] = "sk-ant-test-key-for-ui-tests"
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Wait for an element to exist with a timeout.
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    /// Tap a session card by its raw value identifier.
    func tapSessionCard(_ rawValue: String) {
        let card = app.buttons["sessionCard_\(rawValue)"]
        if card.waitForExistence(timeout: 3) {
            card.tap()
        } else {
            // Fallback: try scrolling to find it
            let scrollView = app.scrollViews.firstMatch
            scrollView.swipeUp()
            XCTAssertTrue(card.waitForExistence(timeout: 3), "Session card '\(rawValue)' not found")
            card.tap()
        }
    }

    /// Tap the "End Session" / "Beenden" toolbar button.
    func tapEndSession() {
        let endButton = app.buttons["End Session"]
        if endButton.exists {
            endButton.tap()
        } else {
            // Try German label
            let beendenButton = app.buttons["Beenden"]
            if beendenButton.exists {
                beendenButton.tap()
            }
        }
    }

    /// Navigate back (tap the back button in the navigation bar).
    func tapBack() {
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
    }
}
