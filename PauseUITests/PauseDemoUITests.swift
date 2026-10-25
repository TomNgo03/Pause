import XCTest

final class PauseDemoUITests: XCTestCase {
    @MainActor
    func testAdmissionsDemo() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-demo"]
        app.launch()

        // Let the essay-led opening establish the problem and design process.
        sleep(53)
        let closeStory = app.buttons["demo.close"]
        XCTAssertTrue(closeStory.waitForExistence(timeout: 4))
        closeStory.tap()
        sleep(4)

        // Use the real decision flow and deliberately choose a better moment.
        let choose = app.buttons["today.choose"]
        XCTAssertTrue(choose.waitForExistence(timeout: 4))
        choose.tap()
        sleep(3)
        app.buttons["routine.later"].tap()
        sleep(2)
        app.buttons["In 10 minutes"].tap()
        sleep(4)

        // Inspect the routine and the rationale behind its supportive wording.
        app.buttons["tab.routines"].tap()
        sleep(4)
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Check inhaler")).firstMatch.tap()
        sleep(5)
        app.buttons["routine.detail.close"].tap()
        sleep(3)

        // Practice a real guide whose support intentionally fades.
        app.buttons["tab.guides"].tap()
        sleep(4)
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Attach a document")).firstMatch.tap()
        sleep(4)
        let reveal = app.buttons["guide.reveal"]
        if reveal.waitForExistence(timeout: 3) { reveal.tap() }
        sleep(3)
        for _ in 0..<4 {
            let next = app.buttons["guide.next"]
            guard next.waitForExistence(timeout: 2) else { break }
            next.tap()
            sleep(3)
        }
        sleep(3)

        // Show that each insight is derived from the local interaction history.
        app.buttons["tab.insights"].tap()
        sleep(5)
        app.swipeUp(velocity: .slow)
        sleep(5)
        app.swipeUp(velocity: .slow)
        sleep(5)
        app.swipeDown(velocity: .slow)
        sleep(4)

        // Close on the local profile and its ethical design commitments.
        app.buttons["tab.you"].tap()
        sleep(8)
    }
}
