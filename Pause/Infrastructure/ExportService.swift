import Foundation

enum ExportService {
    static func csv(sessions: [IntentionalSession], participantCode: String) -> String {
        var rows = ["participant_code,study_day,intention,planned_minutes,extension_minutes,outcome,control"]
        guard let first = sessions.map(\.plannedStart).min() else { return rows[0] }
        let calendar = Calendar.current
        for item in sessions.sorted(by: { $0.plannedStart < $1.plannedStart }) {
            let day = (calendar.dateComponents([.day], from: calendar.startOfDay(for: first), to: calendar.startOfDay(for: item.plannedStart)).day ?? 0) + 1
            let minutes = max(1, Int(item.plannedEnd.timeIntervalSince(item.plannedStart) / 60))
            rows.append([participantCode, String(day), item.intentionRaw, String(minutes), String(item.extensionMinutes), item.outcomeRaw, item.controlRaw].map(escape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private static func escape(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

