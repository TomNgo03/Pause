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
    }

    var intention: IntentionCategory { IntentionCategory(rawValue: intentionRaw) ?? .other }
    var outcome: IntentionOutcome { IntentionOutcome(rawValue: outcomeRaw) ?? .skipped }
    var control: ControlFeeling { ControlFeeling(rawValue: controlRaw) ?? .skipped }
}

