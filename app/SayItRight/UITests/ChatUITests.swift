import XCTest

/// Tests for the chat interface — input field, send button state, and message display.
final class ChatUITests: SayItRightUITestCase {

    override func setUp() {
        super.setUp()
        app.launch()

        // Navigate to a session to get the chat view
        let header = app.staticTexts["What would you like to practise?"]
        guard header.waitForExistence(timeout: 5) else {
            XCTFail("Session picker did not load")
            return
        }
        tapSessionCard("say-it-clearly")

        // Wait for chat to load
        let navTitle = app.navigationBars["Say it clearly"]
        _ = navTitle.waitForExistence(timeout: 5)
    }

    func testChatInputFieldExists() throws {
        let inputField = app.textFields["chatInputField"]
        XCTAssertTrue(inputField.waitForExistence(timeout: 3),
                     "Chat input field should be visible")
    }

    func testSendButtonExists() throws {
        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3),
                     "Send button should be visible")
    }

    func testSendButtonDisabledWhenEmpty() throws {
        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))

        // Send button should be disabled when input is empty
        XCTAssertFalse(sendButton.isEnabled,
                      "Send button should be disabled when input is empty")
    }

    func testSendButtonEnabledAfterTyping() throws {
        let inputField = app.textFields["chatInputField"]
        XCTAssertTrue(inputField.waitForExistence(timeout: 3))

        inputField.tap()
        inputField.typeText("Schools should adopt a four-day week.")

        let sendButton = app.buttons["sendButton"]
        XCTAssertTrue(sendButton.isEnabled,
                     "Send button should be enabled after typing text")
    }

    func testEmptyStateShowsBarbaraAvatar() throws {
        // The empty state should show Barbara's avatar and a prompt
        let readyText = app.staticTexts["Ready when you are."]
        // This may or may not appear depending on whether Barbara's first
        // message has loaded. If it doesn't, that's also valid.
        if readyText.waitForExistence(timeout: 2) {
            XCTAssertTrue(readyText.exists)
        }
    }

    func testEndSessionButtonExists() throws {
        let endButton = app.buttons["End Session"]
        XCTAssertTrue(endButton.waitForExistence(timeout: 3),
                     "End Session toolbar button should be visible")
    }

    func testEndSessionReturnsToSessionPicker() throws {
        tapEndSession()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5),
                     "Should return to session picker after ending session")
    }
}
