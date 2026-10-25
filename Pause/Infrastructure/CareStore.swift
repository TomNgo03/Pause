import Foundation
import Combine

@MainActor
final class CareStore: ObservableObject {
    @Published var routines: [CareRoutine] { didSet { save() } }
    @Published var guides: [PersonalGuide] { didSet { save() } }
    private let key = "pause.care-state.v1"

    init(defaults: UserDefaults = .standard) {
        if let data = defaults.data(forKey: key), let state = try? JSONDecoder().decode(PauseLocalState.self, from: data) {
            routines = state.routines
            guides = state.guides
        } else {
            routines = PauseLocalState.starter.routines
            guides = PauseLocalState.starter.guides
        }
    }

    func complete(_ routine: CareRoutine) {
        guard let index = routines.firstIndex(where: { $0.id == routine.id }), !routines[index].isCompleted() else { return }
        routines[index].completedDates.append(.now)
        routines[index].postponedUntil = nil
        NotificationService().cancelRoutine(id: routine.id)
    }

    func postpone(_ routine: CareRoutine, minutes: Int = 10) async {
        guard let index = routines.firstIndex(where: { $0.id == routine.id }) else { return }
        let date = Date.now.addingTimeInterval(TimeInterval(minutes * 60))
        routines[index].postponedUntil = date
        await NotificationService().scheduleRoutine(routines[index], at: date)
    }

    func addRoutine(title: String, detail: String, date: Date) async {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        let routine = CareRoutine(title: title, detail: detail, reminderHour: parts.hour ?? 9, reminderMinute: parts.minute ?? 0)
        routines.append(routine)
        await NotificationService().scheduleDailyRoutine(routine)
    }

    func addGuide(title: String, purpose: String, steps: [String]) {
        guides.append(PersonalGuide(title: title, purpose: purpose, steps: steps.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }))
    }

    func practiced(_ guide: PersonalGuide) {
        guard let index = guides.firstIndex(where: { $0.id == guide.id }) else { return }
        guides[index].practiceCount += 1
    }

    func reset() {
        routines = PauseLocalState.starter.routines
        guides = PauseLocalState.starter.guides
    }

    private func save() {
        let state = PauseLocalState(routines: routines, guides: guides)
        UserDefaults.standard.set(try? JSONEncoder().encode(state), forKey: key)
    }
}

