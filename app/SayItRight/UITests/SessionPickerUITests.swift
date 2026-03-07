import XCTest

/// Tests for the session picker screen — verifies all session cards are visible
/// and tappable, and that navigation works correctly.
final class SessionPickerUITests: SayItRightUITestCase {

    func testSessionPickerShowsAllSessions() throws {
        app.launch()

        // Wait for the session picker to load
        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5), "Session picker header should appear")

        // All session types should be visible (may need scrolling)
        let expectedCards = [
            "say-it-clearly",
            "find-the-point",
            "elevator-pitch",
            "analyse-my-text",
            "fix-this-mess",
            "spot-the-gap",
            "decode-and-rebuild",
        ]

        for rawValue in expectedCards {
            let card = app.buttons["sessionCard_\(rawValue)"]
            if !card.exists {
                app.scrollViews.firstMatch.swipeUp()
            }
            XCTAssertTrue(card.waitForExistence(timeout: 3),
                         "Session card '\(rawValue)' should exist")
        }
    }

    func testSessionCardShowsDisplayName() throws {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        // Check that session display names appear
        XCTAssertTrue(app.staticTexts["Say it clearly"].exists,
                     "Should show 'Say it clearly' display name")
        XCTAssertTrue(app.staticTexts["Find the point"].exists,
                     "Should show 'Find the point' display name")
    }

    func testTapSayItClearlyNavigates() throws {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("say-it-clearly")

        // Should navigate to Say It Clearly session view
        let navTitle = app.navigationBars["Say it clearly"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5),
                     "Should navigate to 'Say it clearly' view")
    }

    func testTapAnalyseMyTextNavigates() throws {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("analyse-my-text")

        let navTitle = app.navigationBars["Analyse my text"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5),
                     "Should navigate to 'Analyse my text' view")
    }

    func testTapFindThePointNavigates() throws {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("find-the-point")

        let navTitle = app.navigationBars["Find the point"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5),
                     "Should navigate to 'Find the point' view")
    }

    func testTapElevatorPitchNavigates() throws {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        tapSessionCard("elevator-pitch")

        let navTitle = app.navigationBars["The elevator pitch"]
        XCTAssertTrue(navTitle.waitForExistence(timeout: 5),
                     "Should navigate to 'The elevator pitch' view")
    }

    func testProgressButtonExists() throws {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        // Progress button should be in the toolbar
        let progressButton = app.buttons["progressButton"]
        XCTAssertTrue(progressButton.exists, "Progress toolbar button should exist")
    }

    func testProgressButtonNavigatesToDashboard() throws {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        app.buttons["progressButton"].tap()

        let dashboardTitle = app.navigationBars["Progress"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5),
                     "Should navigate to Progress dashboard")
    }
}
