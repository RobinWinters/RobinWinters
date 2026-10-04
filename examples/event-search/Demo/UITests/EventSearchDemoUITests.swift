import XCTest

final class EventSearchDemoUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.textFields["search-query"].waitForExistence(timeout: 10))
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // Observe past the fixture's 1.5-second non-cooperative completion.
    private func assertNeverAppears(_ element: XCUIElement) {
        let appeared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true"), object: element)
        appeared.isInverted = true
        wait(for: [appeared], timeout: 2.5)
    }

    func testSearchSelectionAndClear() {
        app.buttons["strength-search"].tap()
        let event = app.buttons["event-strength"]
        XCTAssertTrue(event.waitForExistence(timeout: 5))
        event.tap()
        let selection = app.staticTexts["selected-event"]
        XCTAssertTrue(selection.waitForExistence(timeout: 3))
        XCTAssertEqual(selection.label, "Strength meet")
        capture("strength-selected")
        app.buttons["clear-search"].tap()
        XCTAssertFalse(event.exists)
        XCTAssertFalse(selection.exists)
        XCTAssertTrue(app.staticTexts["No matching synthetic events"].exists)
        capture("cleared-results")
    }

    func testErrorAndRetry() {
        let query = app.textFields["search-query"]
        query.tap()
        query.typeText("error\n")
        let error = app.staticTexts["search-error"]
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        capture("synthetic-error")
        app.buttons["strength-search"].tap()
        XCTAssertTrue(app.buttons["event-strength"].waitForExistence(timeout: 5))
        XCTAssertFalse(error.exists)
        capture("successful-retry")
    }

    func testRaceKeepsLatestRequestOnScreen() {
        app.buttons["race-search"].tap()
        let latest = app.buttons["event-fast"]
        XCTAssertTrue(latest.waitForExistence(timeout: 5))
        assertNeverAppears(app.buttons["event-slow"])
        XCTAssertTrue(latest.exists)
        XCTAssertEqual(app.textFields["search-query"].value as? String, "fast")
        capture("latest-request-after-slow-completion")
    }

    func testCancelRejectsLateCompletion() {
        let query = app.textFields["search-query"]
        query.tap()
        query.typeText("slow\n")
        XCTAssertTrue(app.progressIndicators["search-progress"].waitForExistence(timeout: 5))
        app.buttons["cancel-search"].tap()
        let cancelled = app.staticTexts["search-activity"]
        XCTAssertTrue(cancelled.label.hasPrefix("Cancelled."))
        assertNeverAppears(app.buttons["event-slow"])
        XCTAssertFalse(app.progressIndicators["search-progress"].exists)
        capture("cancelled-after-late-completion")
    }
}
