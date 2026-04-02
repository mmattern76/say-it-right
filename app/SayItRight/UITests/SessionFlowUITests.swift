import XCTest

/// Tests that each session type loads correctly and can be ended.
///
/// Verifies that tapping a session card navigates to the chat view,
/// shows the expected nav bar title, and the End Session button works.
final class SessionFlowUITests: SayItRightUITestCase {
    // MARK: - Say It Clearly

    func testSayItClearlyShowsChatUI() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("say-it-clearly")

        // Should show the session nav title
        let navTitle = app.navigationBars["Say it clearly"]
        XCTAssertTrue(
            navTitle.waitForExistence(timeout: 5),
            "Should navigate to Say it clearly"
        )

        // Chat input should be visible
        let inputField = app.textFields["chatInputField"]
        XCTAssertTrue(
            inputField.waitForExistence(timeout: 3),
            "Chat input field should appear"
        )
    }

    func testSayItClearlyEndSession() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("say-it-clearly")

        let navTitle = app.navigationBars["Say it clearly"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        tapEndSession()

        // Should return to the session picker
        XCTAssertTrue(
            header.waitForExistence(timeout: 5),
            "Should return to session picker after ending session"
        )
    }

    // MARK: - Find The Point

    func testFindThePointShowsChatUI() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("find-the-point")

        let navTitle = app.navigationBars["Find the point"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        let inputField = app.textFields["chatInputField"]
        XCTAssertTrue(inputField.waitForExistence(timeout: 3))
    }

    func testFindThePointEndSession() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("find-the-point")

        let navTitle = app.navigationBars["Find the point"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        tapEndSession()

        XCTAssertTrue(
            header.waitForExistence(timeout: 5),
            "Should return to session picker"
        )
    }

    // MARK: - Elevator Pitch

    func testElevatorPitchShowsChatUI() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("elevator-pitch")

        let navTitle = app.navigationBars["The elevator pitch"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        let inputField = app.textFields["chatInputField"]
        XCTAssertTrue(inputField.waitForExistence(timeout: 3))
    }

    func testElevatorPitchEndSession() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("elevator-pitch")

        let navTitle = app.navigationBars["The elevator pitch"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        tapEndSession()

        XCTAssertTrue(
            header.waitForExistence(timeout: 5),
            "Should return to session picker"
        )
    }

    // MARK: - Analyse My Text

    func testAnalyseMyTextShowsChatUI() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("analyse-my-text")

        let navTitle = app.navigationBars["Analyse my text"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        let inputField = app.textFields["chatInputField"]
        XCTAssertTrue(inputField.waitForExistence(timeout: 3))
    }

    func testAnalyseMyTextEndSession() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("analyse-my-text")

        let navTitle = app.navigationBars["Analyse my text"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        tapEndSession()

        XCTAssertTrue(
            header.waitForExistence(timeout: 5),
            "Should return to session picker"
        )
    }

    // MARK: - Fix This Mess

    func testFixThisMessShowsChatUI() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("fix-this-mess")

        let navTitle = app.navigationBars["Fix this mess"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        let inputField = app.textFields["chatInputField"]
        XCTAssertTrue(inputField.waitForExistence(timeout: 3))
    }

    func testFixThisMessEndSession() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("fix-this-mess")

        let navTitle = app.navigationBars["Fix this mess"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        tapEndSession()

        XCTAssertTrue(
            header.waitForExistence(timeout: 5),
            "Should return to session picker"
        )
    }

    // MARK: - Spot The Gap

    func testSpotTheGapShowsChatUI() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("spot-the-gap")

        let navTitle = app.navigationBars["Spot the gap"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        let inputField = app.textFields["chatInputField"]
        XCTAssertTrue(inputField.waitForExistence(timeout: 3))
    }

    func testSpotTheGapEndSession() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("spot-the-gap")

        let navTitle = app.navigationBars["Spot the gap"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        tapEndSession()

        XCTAssertTrue(
            header.waitForExistence(timeout: 5),
            "Should return to session picker"
        )
    }

    // MARK: - Decode and Rebuild

    func testDecodeAndRebuildShowsChatUI() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("decode-and-rebuild")

        let navTitle = app.navigationBars["Decode and rebuild"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        let inputField = app.textFields["chatInputField"]
        XCTAssertTrue(inputField.waitForExistence(timeout: 3))
    }

    func testDecodeAndRebuildEndSession() {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("decode-and-rebuild")

        let navTitle = app.navigationBars["Decode and rebuild"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5))

        tapEndSession()

        XCTAssertTrue(
            header.waitForExistence(timeout: 5),
            "Should return to session picker"
        )
    }
}
