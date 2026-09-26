import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum PlanGenerationSource: String, Codable {
    case onDeviceAI
    case localPlanner

    var label: String {
        switch self {
        case .onDeviceAI: "Created with on-device AI"
        case .localPlanner: "Created privately with Pause"
        }
    }
}

struct GeneratedPlan {
    let plan: AIPlan
    let source: PlanGenerationSource
}

struct GeneratedPlanOptions {
    let plans: [AIPlan]
    let source: PlanGenerationSource
}

struct AIPlanningService {
    private let session = URLSession.shared

    func onDeviceAIStatus() -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available: return "On-device AI is ready"
            case .unavailable(.appleIntelligenceNotEnabled): return "Enable Apple Intelligence to use on-device AI"
            case .unavailable(.modelNotReady): return "Apple's on-device model is still preparing"
            case .unavailable(.deviceNotEligible): return "On-device AI is unavailable on this device"
            @unknown default: return "On-device AI is currently unavailable"
            }
        }
        #endif
        return "Requires iOS or iPadOS 26"
    }

    func isOnDeviceAIAvailable() -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) { return SystemLanguageModel.default.isAvailable }
        #endif
        return false
    }

    func createPlan(_ request: AIPlanRequest) async throws -> AIPlan {
        try await createPlanWithSource(request).plan
    }

    func createPlanWithSource(_ request: AIPlanRequest) async throws -> GeneratedPlan {
        guard !request.task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw PlanningError.emptyTask }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            do {
                let plan = normalized(try await createOnDevicePlan(request), availableMinutes: request.availableMinutes)
                return GeneratedPlan(plan: try PlanValidator.validate(plan, availableMinutes: request.availableMinutes), source: .onDeviceAI)
            } catch {
                // A useful local plan remains available if generation is interrupted or rejected.
            }
        }
        #endif
        return GeneratedPlan(plan: try PlanValidator.validate(offlinePlan(request), availableMinutes: request.availableMinutes), source: .localPlanner)
    }

    func createPlanOptions(for goal: String, deadline: Date = .now.addingTimeInterval(604_800), availableMinutes: Int = 90) async throws -> GeneratedPlanOptions {
        let cleanGoal = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanGoal.isEmpty else { throw PlanningError.emptyTask }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            do {
                let plans = try await createOnDevicePlanOptions(goal: cleanGoal, deadline: deadline, availableMinutes: availableMinutes).map { normalized($0, availableMinutes: availableMinutes) }
                let validated = try plans.map { try PlanValidator.validate($0, availableMinutes: availableMinutes) }
                guard validated.count == 3 else { throw PlanningError.invalidResponse }
                return GeneratedPlanOptions(plans: validated, source: .onDeviceAI)
            } catch {
                // Fall through to three deterministic options when the model cannot answer safely.
            }
        }
        #endif
        let styles: [AIPlanRequest.FocusStyle] = [.short, .balanced, .deep]
        let titles = ["Gentle foundation", "Balanced path", "Focused challenge"]
        let plans = try zip(styles, titles).map { style, title in
            let request = AIPlanRequest(task: cleanGoal, deadline: deadline, availableMinutes: availableMinutes, energy: .medium, style: style)
            var plan = try PlanValidator.validate(offlinePlan(request), availableMinutes: availableMinutes)
            plan.title = title
            return plan
        }
        return GeneratedPlanOptions(plans: plans, source: .localPlanner)
    }

    func offlinePlan(_ request: AIPlanRequest) -> AIPlan {
        let available = max(10, min(180, request.availableMinutes))
        let focusLength: Int = switch request.style { case .short: 15; case .balanced: 25; case .deep: 40 }
        let actionTitles = [
            "Define the smallest useful outcome and list what you need to know first",
            "Learn one prerequisite concept using a clear worked example",
            "Follow one guided practice problem and explain each step",
            "Try one similar problem without looking at the solution",
            "Review mistakes and write the exact next practice step"
        ]
        var remaining = available
        var steps: [AIPlanStep] = []
        var number = 1
        while remaining > 0 && steps.count < 5 {
            let work = min(focusLength, remaining)
            remaining -= work
            let pause = remaining >= 5 ? 5 : 0
            if pause > 0 { remaining -= pause }
            let action = actionTitles[min(number - 1, actionTitles.count - 1)]
            steps.append(AIPlanStep(title: number == 1 ? "For ‘\(request.task)’: \(action.lowercased())" : action, durationMinutes: work, breakMinutes: pause, intention: .learning))
            number += 1
        }
        return AIPlan(title: "A realistic plan for \(request.task)", summary: "A private offline draft based on your time and preferred focus style. Edit anything before accepting.", totalMinutes: available, steps: steps, safetyNote: "Protect sleep, meals, movement, and urgent communication.")
    }

    private func normalized(_ plan: AIPlan, availableMinutes: Int) -> AIPlan {
        let limit = max(10, min(180, availableMinutes))
        let original = plan.steps.prefix(5)
        let originalTotal = original.reduce(0) { $0 + $1.durationMinutes + $1.breakMinutes }
        guard originalTotal > limit else { return plan }
        let scale = Double(limit) / Double(originalTotal)
        var remaining = limit
        var steps: [AIPlanStep] = []
        for (index, step) in original.enumerated() {
            let stepsLeft = original.count - index - 1
            let maximumWork = max(1, remaining - stepsLeft)
            let work = min(maximumWork, max(1, Int(Double(step.durationMinutes) * scale)))
            remaining -= work
            let suggestedBreak = max(0, Int(Double(step.breakMinutes) * scale))
            let breakMinutes = index == original.count - 1 ? 0 : min(suggestedBreak, max(0, remaining - stepsLeft))
            remaining -= breakMinutes
            steps.append(AIPlanStep(title: step.title, durationMinutes: work, breakMinutes: breakMinutes, intention: step.intention))
        }
        var copy = plan
        copy.steps = steps
        copy.totalMinutes = steps.reduce(0) { $0 + $1.durationMinutes + $1.breakMinutes }
        return copy
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
private extension AIPlanningService {
    func createOnDevicePlan(_ request: AIPlanRequest) async throws -> AIPlan {
        let modelSession = LanguageModelSession(instructions: """
        You are Pause Focus Coach for high-school students. Turn one assignment into a realistic, editable study plan.
        Never diagnose, shame, promise grades, or give medical advice. Protect sleep, meals, movement, safety, and urgent communication.
        Use concrete verbs. Keep the total duration within the available minutes. Create between 3 and 5 steps.
        """)
        let prompt = """
        Task: \(request.task)
        Deadline: \(request.deadline.formatted(date: .abbreviated, time: .shortened))
        Time available today: \(request.availableMinutes) minutes
        Energy: \(request.energy.rawValue)
        Preferred style: \(request.style.rawValue)
        Create a practical plan the student can begin now.
        """
        let response = try await modelSession.respond(
            to: prompt,
            generating: OnDevicePlan.self,
            options: GenerationOptions(sampling: .greedy, temperature: 0.2, maximumResponseTokens: 700)
        )
        let output = response.content
        let steps = output.steps.map {
            AIPlanStep(title: $0.title, durationMinutes: $0.durationMinutes, breakMinutes: $0.breakMinutes, intention: .learning)
        }
        return AIPlan(title: output.title, summary: output.summary, totalMinutes: 0, steps: steps, safetyNote: output.safetyNote)
    }

    func createOnDevicePlanOptions(goal: String, deadline: Date, availableMinutes: Int) async throws -> [AIPlan] {
        let modelSession = LanguageModelSession(instructions: """
        You are Pause Focus Coach for high-school students. Turn a goal and deadline into exactly three distinct, realistic options: a gentle foundation, a balanced path, and a faster challenge.
        Account honestly for the student's stated experience. If the goal is unrealistic, preserve the aspiration but teach prerequisites first instead of pretending it can be completed immediately.
        Every option must be easy to follow, use concrete verbs, contain 3 to 5 chronological steps, and fit within the available focus minutes.
        Never diagnose, shame, promise grades, or give medical advice. Protect sleep, meals, movement, safety, and urgent communication.
        """)
        let response = try await modelSession.respond(
            to: "Goal: \(goal)\nDeadline: \(deadline.formatted(date: .complete, time: .omitted))\nDays remaining: \(max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: deadline)).day ?? 0))\nAvailable focus time for the first planning block: \(availableMinutes) minutes. Create three meaningfully different routes and state an honest pace toward the deadline.",
            generating: OnDevicePlanBundle.self,
            options: GenerationOptions(sampling: .greedy, temperature: 0.25, maximumResponseTokens: 1_600)
        )
        return response.content.plans.map { output in
            AIPlan(title: output.title, summary: output.summary, totalMinutes: 0, steps: output.steps.map { AIPlanStep(title: $0.title, durationMinutes: $0.durationMinutes, breakMinutes: $0.breakMinutes, intention: .learning) }, safetyNote: output.safetyNote)
        }
    }
}

@available(iOS 26.0, *)
@Generable(description: "Exactly three distinct study plan choices")
private struct OnDevicePlanBundle {
    @Guide(description: "Three choices: gentle foundation, balanced path, and faster challenge", .count(3))
    var plans: [OnDevicePlan]
}

@available(iOS 26.0, *)
@Generable(description: "A realistic study plan that fits the student's available time")
private struct OnDevicePlan {
    @Guide(description: "A short encouraging plan title")
    var title: String
    @Guide(description: "One sentence explaining why this plan fits the student's time and energy")
    var summary: String
    @Guide(description: "Three to five concrete steps in chronological order", .count(3...5))
    var steps: [OnDevicePlanStep]
    @Guide(description: "A short reminder to protect wellbeing and adjust the plan when needed")
    var safetyNote: String
}

@available(iOS 26.0, *)
@Generable(description: "One concrete action in a study plan")
private struct OnDevicePlanStep {
    @Guide(description: "A concise action beginning with a verb")
    var title: String
    @Guide(description: "Focus duration in minutes", .range(1...60))
    var durationMinutes: Int
    @Guide(description: "Break after the step in minutes", .range(0...10))
    var breakMinutes: Int
}
#endif

private extension JSONEncoder {
    static var pause: JSONEncoder { let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; return encoder }
}
private extension JSONDecoder {
    static var pause: JSONDecoder { let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601; return decoder }
}
