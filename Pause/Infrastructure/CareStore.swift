import Foundation
import Combine

@MainActor
final class CareStore: ObservableObject {
    @Published var routines: [CareRoutine] { didSet { save() } }
    @Published var guides: [PersonalGuide] { didSet { save() } }
    @Published var isPresentationMode: Bool { didSet { save() } }
    @Published var activity: [PauseActivity] { didSet { save() } }
    private let key = "pause.care-state.v1"

    init(defaults: UserDefaults = .standard) {
        if let data = defaults.data(forKey: key), let state = try? JSONDecoder().decode(PauseLocalState.self, from: data) {
            routines = state.routines
            guides = state.guides
            isPresentationMode = state.isPresentationMode
            activity = state.activity
        } else {
            routines = PauseLocalState.starter.routines
            guides = PauseLocalState.starter.guides
            isPresentationMode = false
            activity = []
        }
        if isPresentationMode && activity.isEmpty { loadPresentationDemo() }
    }

    func complete(_ routine: CareRoutine) {
        guard let index = routines.firstIndex(where: { $0.id == routine.id }), !routines[index].isCompleted() else { return }
        routines[index].completedDates.append(.now)
        routines[index].postponedUntil = nil
        activity.insert(PauseActivity(kind: .completed, title: routine.title, note: "Confirmed after a gentle prompt"), at: 0)
        NotificationService().cancelRoutine(id: routine.id)
    }

    func recordFeeling(_ feeling: RoutineResponse.Feeling, for routine: CareRoutine) {
        guard let index = routines.firstIndex(where: { $0.id == routine.id }) else { return }
        routines[index].responses.append(RoutineResponse(feeling: feeling))
    }

    func postpone(_ routine: CareRoutine, minutes: Int = 10) async {
        guard let index = routines.firstIndex(where: { $0.id == routine.id }) else { return }
        let date = Date.now.addingTimeInterval(TimeInterval(minutes * 60))
        routines[index].postponedUntil = date
        activity.insert(PauseActivity(kind: .postponed, title: routine.title, note: "Chose a better moment", delayMinutes: minutes), at: 0)
        await NotificationService().scheduleRoutine(routines[index], at: date)
    }

    func skip(_ routine: CareRoutine) {
        guard let index = routines.firstIndex(where: { $0.id == routine.id }), !routines[index].isCompleted() else { return }
        routines[index].completedDates.append(.now)
        activity.insert(PauseActivity(kind: .skipped, title: routine.title, note: "Marked not relevant today"), at: 0)
    }

    func addRoutine(title: String, detail: String, date: Date, weekdays: [Int], checklistItems: [String]) async {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        let routine = CareRoutine(title: title, detail: detail, reminderHour: parts.hour ?? 9, reminderMinute: parts.minute ?? 0, repeatWeekdays: weekdays, checklistItems: checklistItems)
        routines.append(routine)
        await NotificationService().scheduleDailyRoutine(routine)
    }

    func addGuide(title: String, purpose: String, steps: [String]) {
        guides.append(PersonalGuide(title: title, purpose: purpose, steps: steps.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }))
    }

    func practiced(_ guide: PersonalGuide, independently: Bool) {
        guard let index = guides.firstIndex(where: { $0.id == guide.id }) else { return }
        guides[index].practiceCount += 1
        activity.insert(PauseActivity(kind: independently ? .independent : .guided, title: guide.title, note: independently ? "Attempted without step-by-step help" : "Completed with the guide"), at: 0)
    }

    func reset() {
        routines = PauseLocalState.starter.routines
        guides = PauseLocalState.starter.guides
        isPresentationMode = false
        activity = []
    }

    func loadPresentationDemo() {
        let calendar = Calendar.current
        func daysAgo(_ days: Int, hour: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: -days, to: .now) ?? .now
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        }
        var inhaler = CareRoutine(title: "Check inhaler before leaving", detail: "A quick bag or pocket check—without pressure.", reminderHour: 7, reminderMinute: 30)
        inhaler.completedDates = [daysAgo(6, hour: 7), daysAgo(5, hour: 7), daysAgo(3, hour: 7), daysAgo(2, hour: 7)]
        inhaler.responses = [
            RoutineResponse(date: daysAgo(6, hour: 7), feeling: .stillUnsure),
            RoutineResponse(date: daysAgo(5, hour: 7), feeling: .aboutTheSame),
            RoutineResponse(date: daysAgo(3, hour: 7), feeling: .morePrepared),
            RoutineResponse(date: daysAgo(2, hour: 7), feeling: .morePrepared)
        ]
        var medication = CareRoutine(title: "Evening medication check", detail: "Pause and confirm what you have already taken.", reminderHour: 20, reminderMinute: 0)
        medication.completedDates = [daysAgo(4, hour: 20), daysAgo(2, hour: 20)]
        routines = [inhaler, medication]
        guides = [
            PersonalGuide(title: "Get ready to leave", purpose: "Feel prepared without holding every detail in your head.", steps: ["Find your keys", "Take your phone", "Check that your inhaler is in your bag"], practiceCount: 4),
            PersonalGuide(title: "Attach a document to an email", purpose: "A short guide you can use without someone beside you.", steps: ["Open a new email", "Choose the paperclip icon", "Find the folder and select your document", "Check the file name, then send"], practiceCount: 2)
        ]
        let titles = ["Check inhaler before leaving", "Evening medication check"]
        var demoActivity: [PauseActivity] = []
        for day in 1...14 {
            let title = titles[day % titles.count]
            let date = daysAgo(day, hour: day.isMultiple(of: 2) ? 7 : 20)
            let kind: PauseActivity.Kind = day.isMultiple(of: 5) ? .skipped : (day.isMultiple(of: 3) ? .postponed : .completed)
            demoActivity.append(PauseActivity(date: date, kind: kind, title: title, note: kind == .postponed ? "Returned after finishing homework" : (kind == .skipped ? "Routine was not relevant that day" : "Confirmed after a gentle prompt"), delayMinutes: kind == .postponed ? [5, 10, 15][day % 3] : nil))
        }
        demoActivity += [
            PauseActivity(date: daysAgo(6, hour: 15), kind: .guided, title: "Attach a document to an email", note: "Used all four steps"),
            PauseActivity(date: daysAgo(3, hour: 15), kind: .independent, title: "Attach a document to an email", note: "Completed without opening the guide"),
            PauseActivity(date: daysAgo(2, hour: 8), kind: .guided, title: "Get ready to leave", note: "Used one hint"),
            PauseActivity(date: daysAgo(1, hour: 8), kind: .independent, title: "Get ready to leave", note: "Completed without step-by-step help")
        ]
        activity = demoActivity.sorted { $0.date > $1.date }
        isPresentationMode = true
    }

    private func save() {
        let state = PauseLocalState(routines: routines, guides: guides, isPresentationMode: isPresentationMode, activity: activity)
        UserDefaults.standard.set(try? JSONEncoder().encode(state), forKey: key)
    }
}

