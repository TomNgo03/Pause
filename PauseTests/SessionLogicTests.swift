import XCTest
@testable import Pause

final class SessionLogicTests: XCTestCase {
    func testPlannedMinutesUsesAbsoluteDates() {
        let start = Date(timeIntervalSince1970: 1_000)
        let draft = SessionDraft(intention: .learning, plannedStart: start, plannedEnd: start.addingTimeInterval(600))
        XCTAssertEqual(draft.plannedMinutes, 10)
    }

    @MainActor
    func testPrototypeServiceStartsSession() async {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let model = AppModel(screenTime: PrototypeScreenTimeService())
        let now = Date.now
        await model.start(SessionDraft(intention: .message, plannedStart: now, plannedEnd: now.addingTimeInterval(300)))
        XCTAssertEqual(model.route, .active)
        XCTAssertNotNil(model.activeSession)
        await model.cancelSession()
    }

    func testOfflineAIPlanStaysWithinAvailableTime() throws {
        let request = AIPlanRequest(task: "Review biology", deadline: .now.addingTimeInterval(86_400), availableMinutes: 45, energy: .medium, style: .short)
        let plan = AIPlanningService().offlinePlan(request)
        let validated = try PlanValidator.validate(plan, availableMinutes: 45)
        XCTAssertLessThanOrEqual(validated.totalMinutes, 45)
        XCTAssertFalse(validated.steps.isEmpty)
    }

    func testValidatorRejectsOversizedPlan() {
        let steps = (0..<3).map { _ in AIPlanStep(title: "Work", durationMinutes: 60, breakMinutes: 20, intention: .learning) }
        let invalid = AIPlan(title: "Too long", summary: "", totalMinutes: 240, steps: steps, safetyNote: nil)
        XCTAssertThrowsError(try PlanValidator.validate(invalid, availableMinutes: 30))
    }
}
