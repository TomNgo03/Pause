import Foundation

struct CareRoutine: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var reminderHour: Int
    var reminderMinute: Int
    var isEnabled: Bool = true
    var completedDates: [Date] = []
    var responses: [RoutineResponse] = []
    var postponedUntil: Date?
    var repeatWeekdays: [Int] = Array(1...7)
    var checklistItems: [String] = []

    enum CodingKeys: String, CodingKey { case id, title, detail, reminderHour, reminderMinute, isEnabled, completedDates, responses, postponedUntil, repeatWeekdays, checklistItems }

    init(id: UUID = UUID(), title: String, detail: String, reminderHour: Int, reminderMinute: Int, isEnabled: Bool = true, completedDates: [Date] = [], responses: [RoutineResponse] = [], postponedUntil: Date? = nil, repeatWeekdays: [Int] = Array(1...7), checklistItems: [String] = []) {
        self.id = id; self.title = title; self.detail = detail; self.reminderHour = reminderHour; self.reminderMinute = reminderMinute
        self.isEnabled = isEnabled; self.completedDates = completedDates; self.responses = responses; self.postponedUntil = postponedUntil
        self.repeatWeekdays = repeatWeekdays; self.checklistItems = checklistItems
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try values.decode(String.self, forKey: .title)
        detail = try values.decode(String.self, forKey: .detail)
        reminderHour = try values.decode(Int.self, forKey: .reminderHour)
        reminderMinute = try values.decode(Int.self, forKey: .reminderMinute)
        isEnabled = try values.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        completedDates = try values.decodeIfPresent([Date].self, forKey: .completedDates) ?? []
        responses = try values.decodeIfPresent([RoutineResponse].self, forKey: .responses) ?? []
        postponedUntil = try values.decodeIfPresent(Date.self, forKey: .postponedUntil)
        repeatWeekdays = try values.decodeIfPresent([Int].self, forKey: .repeatWeekdays) ?? Array(1...7)
        checklistItems = try values.decodeIfPresent([String].self, forKey: .checklistItems) ?? []
    }

    var reminderDate: Date {
        Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: .now) ?? .now
    }

    func isCompleted(on date: Date = .now) -> Bool {
        completedDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
    }
}

struct RoutineResponse: Identifiable, Codable, Equatable {
    enum Feeling: String, Codable, CaseIterable {
        case morePrepared = "More prepared"
        case aboutTheSame = "About the same"
        case stillUnsure = "Still unsure"
    }

    var id: UUID = UUID()
    var date: Date = .now
    var feeling: Feeling
}

struct PauseActivity: Identifiable, Codable, Equatable {
    enum Kind: String, Codable, CaseIterable {
        case completed = "Checked"
        case postponed = "Postponed"
        case skipped = "Not needed"
        case guided = "Used guide"
        case independent = "Tried independently"

        var symbol: String {
            switch self {
            case .completed: "checkmark.circle.fill"
            case .postponed: "clock.arrow.circlepath"
            case .skipped: "minus.circle.fill"
            case .guided: "book.pages.fill"
            case .independent: "hand.raised.fill"
            }
        }
    }

    var id: UUID = UUID()
    var date: Date = .now
    var kind: Kind
    var title: String
    var note: String
    var delayMinutes: Int?
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
    var isPresentationMode: Bool = false
    var activity: [PauseActivity] = []

    enum CodingKeys: String, CodingKey { case routines, guides, isPresentationMode, activity }

    init(routines: [CareRoutine], guides: [PersonalGuide], isPresentationMode: Bool = false, activity: [PauseActivity] = []) {
        self.routines = routines; self.guides = guides; self.isPresentationMode = isPresentationMode; self.activity = activity
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        routines = try values.decode([CareRoutine].self, forKey: .routines)
        guides = try values.decode([PersonalGuide].self, forKey: .guides)
        isPresentationMode = try values.decodeIfPresent(Bool.self, forKey: .isPresentationMode) ?? false
        activity = try values.decodeIfPresent([PauseActivity].self, forKey: .activity) ?? []
    }

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

