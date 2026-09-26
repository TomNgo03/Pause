import Foundation
import SwiftData

enum IntentionCategory: String, Codable, CaseIterable, Identifiable {
    case message = "Reply to a message"
    case information = "Find specific information"
    case learning = "Learn something"
    case plannedContent = "View planned content"
    case connection = "Connect with someone"
    case breakTime = "Take a short break"
    case other = "Other"
    var id: String { rawValue }
}

enum EnergyLevel: String, Codable, CaseIterable, Identifiable { case low = "Low", steady = "Steady", high = "High"; var id: String { rawValue } }
enum SessionDistraction: String, Codable, CaseIterable, Identifiable { case notifications = "Notifications", social = "Social media", environment = "My environment", thoughts = "My thoughts", none = "Nothing specific"; var id: String { rawValue } }

enum IntentionOutcome: String, Codable, CaseIterable, Identifiable {
    case yes = "Yes"
    case partly = "Partly"
    case no = "No"
    case skipped = "Prefer not to answer"
    var id: String { rawValue }
}

enum ControlFeeling: String, Codable, CaseIterable, Identifiable {
    case inControl = "In control"
    case neutral = "Neutral"
    case distracted = "Distracted"
    case skipped = "Prefer not to answer"
    var id: String { rawValue }
}

struct SessionDraft: Codable, Equatable {
    var id = UUID()
    var intention: IntentionCategory
    var plannedStart = Date.now
    var plannedEnd: Date
    var actualEnd: Date?
    var extensionMinutes = 0
    var task = ""
    var energy: EnergyLevel = .steady
    var expectedDistraction: SessionDistraction = .none
    var successStatement = ""

    var plannedMinutes: Int {
        max(1, Int(plannedEnd.timeIntervalSince(plannedStart) / 60))
    }
}

@Model
final class IntentionalSession {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var plannedStart: Date
    var plannedEnd: Date
    var actualEnd: Date
    var intentionRaw: String
    var extensionMinutes: Int
    var outcomeRaw: String
    var controlRaw: String
    var task: String = ""
    var energyRaw: String = EnergyLevel.steady.rawValue
    var expectedDistractionRaw: String = SessionDistraction.none.rawValue
    var successStatement: String = ""
    var focusRating: Int = 0
    var mainDistraction: String = ""
    var reflectionNote: String = ""
    var nextStep: String = ""
    var isDemoData: Bool = false

    init(draft: SessionDraft, outcome: IntentionOutcome, control: ControlFeeling) {
        id = draft.id
        createdAt = .now
        plannedStart = draft.plannedStart
        plannedEnd = draft.plannedEnd
        actualEnd = draft.actualEnd ?? .now
        intentionRaw = draft.intention.rawValue
        extensionMinutes = draft.extensionMinutes
        outcomeRaw = outcome.rawValue
        controlRaw = control.rawValue
        task = draft.task
        energyRaw = draft.energy.rawValue
        expectedDistractionRaw = draft.expectedDistraction.rawValue
        successStatement = draft.successStatement
    }

    var intention: IntentionCategory { IntentionCategory(rawValue: intentionRaw) ?? .other }
    var outcome: IntentionOutcome { IntentionOutcome(rawValue: outcomeRaw) ?? .skipped }
    var control: ControlFeeling { ControlFeeling(rawValue: controlRaw) ?? .skipped }
    var energy: EnergyLevel { EnergyLevel(rawValue: energyRaw) ?? .steady }
    var expectedDistraction: SessionDistraction { SessionDistraction(rawValue: expectedDistractionRaw) ?? .none }
    var actualMinutes: Int { max(1, Int(actualEnd.timeIntervalSince(plannedStart) / 60)) }
    var plannedMinutes: Int { max(1, Int(plannedEnd.timeIntervalSince(plannedStart) / 60)) }
}
