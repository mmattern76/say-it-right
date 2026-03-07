import XCTest

/// Tests for the Progress dashboard — navigation and basic content.
final class DashboardUITests: SayItRightUITestCase {

    func testProgressButtonNavigatesToDashboard() throws {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        app.buttons["progressButton"].tap()

        let dashboardTitle = app.navigationBars["Progress"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5),
                     "Should navigate to Progress dashboard")
    }

    func testDashboardShowsLevelInfo() throws {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        app.buttons["progressButton"].tap()

        let dashboardTitle = app.navigationBars["Progress"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5))

        // Dashboard should show level information
        let levelText = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS 'Level' OR label CONTAINS 'Klartext' OR label CONTAINS 'Plain Talk'")
        ).firstMatch
        XCTAssertTrue(levelText.waitForExistence(timeout: 3),
                     "Dashboard should show level information")
    }

    func testDashboardBackNavigation() throws {
        app.launch()

        let header = app.staticTexts["What would you like to practise?"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))

        app.buttons["progressButton"].tap()

        let dashboardTitle = app.navigationBars["Progress"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5))

        tapBack()

        XCTAssertTrue(header.waitForExistence(timeout: 5),
                     "Should return to session picker from dashboard")
    }
}
