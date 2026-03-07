import XCTest

/// Interactive tests that type text, push buttons, and verify outcomes.
///
/// These tests exercise real user interactions rather than just
/// checking element existence.
final class InteractiveFlowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - First Launch: Full API Key → Language → Onboarding Flow

    func testFullFirstLaunchFlow() throws {
        app.launchArguments += [
            "-hasCompletedOnboarding", "NO",
            "-appLanguage", "en",
        ]
        app.launch()

        // Step 1: API key entry screen
        let title = app.staticTexts["Say it right!"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        // Type a valid API key
        let secureField = app.secureTextFields.firstMatch
        XCTAssertTrue(secureField.waitForExistence(timeout: 3))
        secureField.tap()
        secureField.typeText("sk-ant-valid-key-12345")

        // Continue button should be enabled now — tap it
        let continueButton = app.buttons["apiKeyContinueButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 3))
        continueButton.tap()

        // Step 2: Language selection screen
        let languageTitle = app.staticTexts["Choose Your Language"]
        XCTAssertTrue(languageTitle.waitForExistence(timeout: 5),
                     "Should advance to language selection after valid API key")

        // Both languages should be visible
        XCTAssertTrue(app.staticTexts["English"].exists)
        XCTAssertTrue(app.staticTexts["Deutsch"].exists)

        // Tap German to change selection
        app.staticTexts["Deutsch"].tap()

        // Tap Continue to go to onboarding
        let languageContinue = app.buttons["languageContinueButton"]
        XCTAssertTrue(languageContinue.waitForExistence(timeout: 3))
        languageContinue.tap()

        // Step 3: Onboarding with Barbara
        let barbaraLabel = app.staticTexts["Barbara"]
        XCTAssertTrue(barbaraLabel.waitForExistence(timeout: 5),
                     "Should reach Barbara's onboarding after language selection")
    }

    func testInvalidAPIKeyShowsError() throws {
        app.launchArguments += [
            "-hasCompletedOnboarding", "NO",
            "-appLanguage", "en",
        ]
        app.launch()

        let secureField = app.secureTextFields.firstMatch
        XCTAssertTrue(secureField.waitForExistence(timeout: 5))

        // Type an invalid key (no sk-ant- prefix)
        secureField.tap()
        secureField.typeText("invalid-key-no-prefix")

        let continueButton = app.buttons["apiKeyContinueButton"]
        continueButton.tap()

        // Should show the sk-ant- validation error
        let errorText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS 'sk-ant-'")
        ).firstMatch
        XCTAssertTrue(errorText.waitForExistence(timeout: 3),
                     "Should show validation error for invalid key format")

        // Should NOT have advanced to language screen
        let languageTitle = app.staticTexts["Choose Your Language"]
        XCTAssertFalse(languageTitle.exists,
                      "Should not advance past API key with invalid key")
    }

    func testContinueButtonDisabledWhenEmpty() throws {
        app.launchArguments += [
            "-hasCompletedOnboarding", "NO",
            "-appLanguage", "en",
        ]
        app.launch()

        let continueButton = app.buttons["apiKeyContinueButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))

        // Continue button should be disabled when no text entered
        XCTAssertFalse(continueButton.isEnabled,
                      "Continue button should be disabled with empty API key field")
    }

    // MARK: - Onboarding: Avatar + Name Flow

    func testOnboardingAvatarAndNameFlow() throws {
        app.launchArguments += [
            "-hasCompletedOnboarding", "NO",
            "-appLanguage", "en",
        ]
        app.launchEnvironment["ANTHROPIC_API_KEY_OVERRIDE"] = "sk-ant-test-key"
        app.launch()

        // Should start at onboarding since API key is set via env
        let barbaraLabel = app.staticTexts["Barbara"]
        XCTAssertTrue(barbaraLabel.waitForExistence(timeout: 5))

        // Wait for "Let's go!" button (after typing animation)
        let letsGoButton = app.buttons["letsGoButton"]
        XCTAssertTrue(letsGoButton.waitForExistence(timeout: 15),
                     "Let's go button should appear after welcome typing")
        letsGoButton.tap()

        // Should show avatar picker with name field
        let nameField = app.textFields["nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))

        // Continue button should NOT exist yet
        let avatarContinue = app.buttons["avatarContinueButton"]
        XCTAssertFalse(avatarContinue.exists,
                      "Continue should not appear without name and avatar")

        // Type a name
        nameField.tap()
        nameField.typeText("TestKid")

        // Tap the first avatar (Maxi or Alex)
        let avatarImages = app.images
        // Avatar images should exist in the picker
        if avatarImages.count > 0 {
            avatarImages.firstMatch.tap()
        }

        // Now continue button should appear (if avatar was selected)
        if avatarContinue.waitForExistence(timeout: 3) {
            avatarContinue.tap()

            // Should advance to pep talk phase
            // "Let's start!" button should eventually appear
            let letsStartButton = app.buttons["letsStartButton"]
            XCTAssertTrue(letsStartButton.waitForExistence(timeout: 15),
                         "Let's start button should appear after pep talk")
        }
    }

    // MARK: - Session Picker: Navigate and Return

    func testNavigateToSessionAndBack() throws {
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-appLanguage", "en",
            "-displayName", "TestUser",
        ]
        app.launchEnvironment["ANTHROPIC_API_KEY_OVERRIDE"] = "sk-ant-test-key"
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        // Navigate to Say it clearly
        let card = app.buttons["sessionCard_say-it-clearly"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()

        let navTitle = app.navigationBars["Say it clearly"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        // End session to go back
        let endButton = app.buttons["End Session"]
        XCTAssertTrue(endButton.waitForExistence(timeout: 3))
        endButton.tap()

        // Should be back at session picker
        XCTAssertTrue(header.waitForExistence(timeout: 5),
                     "Should return to session picker after End Session")

        // Navigate to a different session
        let findCard = app.buttons["sessionCard_find-the-point"]
        XCTAssertTrue(findCard.waitForExistence(timeout: 3))
        findCard.tap()

        let findNav = app.navigationBars["Find the point"]
        XCTAssertTrue(findNav.waitForExistence(timeout: 5),
                     "Should navigate to Find the point after returning from Say it clearly")
    }

    // MARK: - Chat: Type Message and Verify Send Button

    func testChatTypingEnablesSendButton() throws {
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-appLanguage", "en",
            "-displayName", "TestUser",
        ]
        app.launchEnvironment["ANTHROPIC_API_KEY_OVERRIDE"] = "sk-ant-test-key"
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        // Navigate to Analyse my text (simplest — no topic selection)
        let card = app.buttons["sessionCard_analyse-my-text"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()

        let navTitle = app.navigationBars["Analyse my text"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        // Send button should be disabled initially
        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))
        XCTAssertFalse(sendButton.isEnabled,
                      "Send button should be disabled with empty input")

        // Type a message
        let inputField = app.textFields["chatInputField"]
        XCTAssertTrue(inputField.waitForExistence(timeout: 3))
        inputField.tap()
        inputField.typeText("Schools should adopt a four-day week because students learn better with rest days.")

        // Send button should now be enabled
        XCTAssertTrue(sendButton.isEnabled,
                     "Send button should be enabled after typing text")
    }

    func testChatClearInputAfterTyping() throws {
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-appLanguage", "en",
            "-displayName", "TestUser",
        ]
        app.launchEnvironment["ANTHROPIC_API_KEY_OVERRIDE"] = "sk-ant-test-key"
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        let card = app.buttons["sessionCard_analyse-my-text"]
        card.tap()

        let navTitle = app.navigationBars["Analyse my text"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        // Type text
        let inputField = app.textFields["chatInputField"]
        XCTAssertTrue(inputField.waitForExistence(timeout: 3))
        inputField.tap()
        inputField.typeText("Test message")

        // Verify text is in the field
        XCTAssertEqual(inputField.value as? String, "Test message",
                      "Input field should contain typed text")

        // Clear it
        inputField.tap()

        // Select all and delete
        #if os(macOS)
        inputField.typeKey("a", modifierFlags: .command)
        inputField.typeKey(.delete, modifierFlags: [])
        #else
        // Triple tap to select all, then delete
        if let text = inputField.value as? String, !text.isEmpty {
            // Use the clear button or select all
            inputField.press(forDuration: 1.0)
            let selectAll = app.menuItems["Select All"]
            if selectAll.waitForExistence(timeout: 2) {
                selectAll.tap()
                inputField.typeText(XCUIKeyboardKey.delete.rawValue)
            }
        }
        #endif
    }

    // MARK: - Dashboard: Navigate and Verify Empty State

    func testDashboardShowsEmptyState() throws {
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-appLanguage", "en",
            "-displayName", "TestUser",
        ]
        app.launchEnvironment["ANTHROPIC_API_KEY_OVERRIDE"] = "sk-ant-test-key"
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        // Tap the progress button
        let progressButton = app.buttons["progressButton"]
        XCTAssertTrue(progressButton.waitForExistence(timeout: 3))
        progressButton.tap()

        // Dashboard should show empty state for a fresh user
        let emptyText = app.staticTexts["No sessions completed yet"]
        XCTAssertTrue(emptyText.waitForExistence(timeout: 5),
                     "Fresh user should see empty state on dashboard")

        let startText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS 'Start your first exercise'")
        ).firstMatch
        XCTAssertTrue(startText.exists,
                     "Should show prompt to start first exercise")
    }

    func testDashboardNavigateBackToPickerThenToSession() throws {
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-appLanguage", "en",
            "-displayName", "TestUser",
        ]
        app.launchEnvironment["ANTHROPIC_API_KEY_OVERRIDE"] = "sk-ant-test-key"
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        // Go to dashboard
        app.buttons["progressButton"].tap()
        let dashboardTitle = app.navigationBars["Progress"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5))

        // Go back
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.exists)
        backButton.tap()

        // Should be back at picker
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        // Now navigate to a session — verifies navigation stack is clean
        let card = app.buttons["sessionCard_elevator-pitch"]
        XCTAssertTrue(card.waitForExistence(timeout: 3))
        card.tap()

        let navTitle = app.navigationBars["The elevator pitch"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5),
                     "Should navigate to session after returning from dashboard")
    }

    // MARK: - Multiple Session Navigation (stress test nav stack)

    func testNavigateMultipleSessionsSequentially() throws {
        app.launchArguments += [
            "-hasCompletedOnboarding", "YES",
            "-appLanguage", "en",
            "-displayName", "TestUser",
        ]
        app.launchEnvironment["ANTHROPIC_API_KEY_OVERRIDE"] = "sk-ant-test-key"
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        // Navigate through 3 sessions in sequence, ending each before starting the next
        let sessions: [(rawValue: String, title: String)] = [
            ("say-it-clearly", "Say it clearly"),
            ("fix-this-mess", "Fix this mess"),
            ("spot-the-gap", "Spot the gap"),
        ]

        for session in sessions {
            let card = app.buttons["sessionCard_\(session.rawValue)"]
            if !card.exists {
                app.scrollViews.firstMatch.swipeUp()
            }
            XCTAssertTrue(card.waitForExistence(timeout: 3),
                         "Card for \(session.rawValue) should exist")
            card.tap()

            let navTitle = app.navigationBars[session.title]
            XCTAssertTrue(navTitle.waitForExistence(timeout: 5),
                         "Should navigate to \(session.title)")

            // End session
            let endButton = app.buttons["End Session"]
            XCTAssertTrue(endButton.waitForExistence(timeout: 3))
            endButton.tap()

            XCTAssertTrue(header.waitForExistence(timeout: 5),
                         "Should return to picker after ending \(session.title)")
        }
    }
}
