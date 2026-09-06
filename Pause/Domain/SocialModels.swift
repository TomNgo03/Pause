import Foundation

struct PauseProfile: Codable, Identifiable, Equatable {
    var id: UUID
    var displayName: String
    var friendCode: String
    var dailyIntention: String?
}

struct PauseFriend: Codable, Identifiable, Equatable {
    var id: UUID
    var displayName: String
    var status: String
    var badgeSymbols: [String]?
}

struct AccountabilityCircle: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var memberIDs: [UUID]
    var weeklyGoal: Int
    var weeklyProgress: Int
}

struct FocusRoom: Codable, Identifiable, Equatable {
    enum State: String, Codable { case waiting, focusing, completed }
    var id: UUID
    var title: String
    var durationMinutes: Int
    var startedAt: Date?
    var participantIDs: [UUID]
    var state: State
}

struct CooperativeChallenge: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var target: Int
    var progress: Int
    var endsAt: Date
}

struct Encouragement: Codable, Identifiable, Equatable {
    enum Kind: String, Codable, CaseIterable, Identifiable {
        case support = "You’ve got this"
        case plan = "Good plan"
        case focus = "Nice focus session"
        case together = "Thanks for focusing with me"
        var id: String { rawValue }
        var symbol: String {
            switch self { case .support: "hand.thumbsup.fill"; case .plan: "checkmark.seal.fill"; case .focus: "sparkles"; case .together: "person.2.fill" }
        }
    }
    var id: UUID
    var senderName: String
    var kind: Kind
    var createdAt: Date
}
