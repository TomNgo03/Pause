import Foundation

struct AIPlanningService {
    private let session = URLSession.shared

    func createPlan(_ request: AIPlanRequest) async throws -> AIPlan {
        guard !request.task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw PlanningError.emptyTask }
        guard let endpoint = Bundle.main.object(forInfoDictionaryKey: "PAUSE_AI_ENDPOINT") as? String,
              !endpoint.isEmpty, let url = URL(string: endpoint) else {
            return try PlanValidator.validate(offlinePlan(request), availableMinutes: request.availableMinutes)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let token = SessionTokenStore.load() else { return try PlanValidator.validate(offlinePlan(request), availableMinutes: request.availableMinutes) }
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder.pause.encode(request)
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw PlanningError.serverUnavailable }
        return try PlanValidator.validate(JSONDecoder.pause.decode(AIPlan.self, from: data), availableMinutes: request.availableMinutes)
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

private extension JSONEncoder {
    static var pause: JSONEncoder { let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; return encoder }
}
private extension JSONDecoder {
    static var pause: JSONDecoder { let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601; return decoder }
}
