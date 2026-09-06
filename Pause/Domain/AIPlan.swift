import Foundation

struct AIPlanRequest: Codable, Equatable {
    var task: String
    var deadline: Date
    var availableMinutes: Int
    var energy: EnergyLevel
    var style: FocusStyle

    enum EnergyLevel: String, Codable, CaseIterable, Identifiable { case low = "Low", medium = "Medium", high = "High"; var id: String { rawValue } }
    enum FocusStyle: String, Codable, CaseIterable, Identifiable { case short = "Short sessions", balanced = "Balanced", deep = "Long focus"; var id: String { rawValue } }
}

struct AIPlan: Codable, Equatable, Identifiable {
    var id = UUID()
    var title: String
    var summary: String
    var totalMinutes: Int
    var steps: [AIPlanStep]
    var safetyNote: String?

    enum CodingKeys: String, CodingKey { case title, summary, totalMinutes = "total_minutes", steps, safetyNote = "safety_note" }
}

struct AIPlanStep: Codable, Equatable, Identifiable {
    var id = UUID()
    var title: String
    var durationMinutes: Int
    var breakMinutes: Int
    var intention: IntentionCategory

    enum CodingKeys: String, CodingKey { case title, durationMinutes = "duration_minutes", breakMinutes = "break_minutes", intention }
}

enum PlanValidator {
    static func validate(_ plan: AIPlan, availableMinutes: Int) throws -> AIPlan {
        guard !plan.title.isEmpty, !plan.steps.isEmpty, plan.steps.count <= 5 else { throw PlanningError.invalidResponse }
        guard plan.steps.allSatisfy({ (1...60).contains($0.durationMinutes) && (0...20).contains($0.breakMinutes) }) else { throw PlanningError.invalidResponse }
        let computed = plan.steps.reduce(0) { $0 + $1.durationMinutes + $1.breakMinutes }
        guard computed <= min(180, availableMinutes + 10) else { throw PlanningError.invalidResponse }
        var copy = plan; copy.totalMinutes = computed; return copy
    }
}

enum PlanningError: LocalizedError {
    case emptyTask, invalidResponse, serverUnavailable
    var errorDescription: String? {
        switch self { case .emptyTask: "Describe the task first."; case .invalidResponse: "The suggested plan was not safe or valid."; case .serverUnavailable: "The AI coach is unavailable, so Pause can create a private offline plan instead." }
    }
}

