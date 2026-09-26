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

    func createPlan(_ request: AIPlanRequest) async throws -> AIPlan {
        try await createPlanWithSource(request).plan
    }

    func createPlanWithSource(_ request: AIPlanRequest) async throws -> GeneratedPlan {
        guard !request.task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw PlanningError.emptyTask }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            do {
                let plan = try await createOnDevicePlan(request)
                return GeneratedPlan(plan: try PlanValidator.validate(plan, availableMinutes: request.availableMinutes), source: .onDeviceAI)
            } catch {
                // A useful local plan remains available if generation is interrupted or rejected.
            }
        }
        #endif
        return GeneratedPlan(plan: try PlanValidator.validate(offlinePlan(request), availableMinutes: request.availableMinutes), source: .localPlanner)
    }

    func offlinePlan(_ request: AIPlanRequest) -> AIPlan {
        let available = max(10, min(180, request.availableMinutes))
        let focusLength: Int = switch request.style { case .short: 15; case .balanced: 25; case .deep: 40 }
        var remaining = available
        var steps: [AIPlanStep] = []
        var number = 1
        while remaining > 0 && steps.count < 5 {
            let work = min(focusLength, remaining)
            remaining -= work
            let pause = remaining >= 5 ? 5 : 0
            if pause > 0 { remaining -= pause }
            steps.append(AIPlanStep(title: number == 1 ? "Start: \(request.task)" : "Continue with the next concrete part", durationMinutes: work, breakMinutes: pause, intention: .learning))
            number += 1
        }
        return AIPlan(title: "A realistic plan for \(request.task)", summary: "A private offline draft based on your time and preferred focus style. Edit anything before accepting.", totalMinutes: available, steps: steps, safetyNote: "Protect sleep, meals, movement, and urgent communication.")
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
