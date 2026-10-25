import Foundation

struct CareRoutine: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var reminderHour: Int
    var reminderMinute: Int
    var isEnabled: Bool = true
    var completedDates: [Date] = []
    var postponedUntil: Date?

    var reminderDate: Date {
        Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: .now) ?? .now
    }

    func isCompleted(on date: Date = .now) -> Bool {
        completedDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }
}

struct PersonalGuide: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var purpose: String
    var steps: [String]
    var practiceCount: Int = 0
}

struct PauseLocalState: Codable {
    var routines: [CareRoutine]
    var guides: [PersonalGuide]

    static let starter = PauseLocalState(
        routines: [
            CareRoutine(title: "Check inhaler before leaving", detail: "A quick bag or pocket check—without pressure.", reminderHour: 7, reminderMinute: 30),
            CareRoutine(title: "Evening medication check", detail: "Pause and confirm what you have already taken.", reminderHour: 20, reminderMinute: 0)
        ],
        guides: [
            PersonalGuide(title: "Get ready to leave", purpose: "Feel prepared without holding every detail in your head.", steps: ["Find your keys", "Take your phone", "Check that your inhaler is in your bag"]),
            PersonalGuide(title: "Attach a document to an email", purpose: "A short guide you can use without someone beside you.", steps: ["Open a new email", "Choose the paperclip icon", "Find the folder and select your document", "Check the file name, then send"])
        ]
    )
}

