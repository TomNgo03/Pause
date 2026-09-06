import Foundation

struct DashboardSummary {
    let totalSessions: Int
    let reflectedSessions: Int
    let completedIntentions: Int
    let extensionCount: Int
    let inControlCount: Int

    var completionRate: Double? {
        guard reflectedSessions > 0 else { return nil }
        return Double(completedIntentions) / Double(reflectedSessions)
    }
}

enum SessionAnalytics {
    static func summarize(_ sessions: [IntentionalSession]) -> DashboardSummary {
        let answered = sessions.filter { $0.outcome != .skipped }
        return DashboardSummary(
            totalSessions: sessions.count,
            reflectedSessions: answered.count,
            completedIntentions: answered.filter { $0.outcome == .yes }.count,
            extensionCount: sessions.filter { $0.extensionMinutes > 0 }.count,
            inControlCount: sessions.filter { $0.control == .inControl }.count
        )
    }
}

