import SwiftUI
import Charts

struct CareInsightsView: View {
    @EnvironmentObject private var model: AppModel
    private var activity: [PauseActivity] { model.care.activity }
    private var responses: [RoutineResponse] { model.care.routines.flatMap(\.responses).sorted { $0.date < $1.date } }
    private var completed: Int { activity.filter { $0.kind == .completed }.count }
    private var postponed: Int { activity.filter { $0.kind == .postponed }.count }
    private var independent: Int { activity.filter { $0.kind == .independent }.count }

    var body: some View {
        ZStack { PauseBackground(); ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack { Text("INSIGHTS").font(.caption.bold()).tracking(1.5).foregroundStyle(PauseTheme.orange); Spacer(); if model.care.isPresentationMode { Text("DEMO DATA").font(.caption2.bold()).padding(.horizontal, 10).padding(.vertical, 6).background(PauseTheme.sage, in: Capsule()) } }
                    Text("Understand the pause,\nnot just the tap.").font(.system(size: 36, weight: .bold, design: .serif))
                    Text("Transparent patterns from information stored only on this device.").font(.subheadline).foregroundStyle(PauseTheme.muted)
                }
                overview
                responseMix
                confidenceTrend
                adaptiveSuggestion
                timeline
            }.padding(20).padding(.bottom, 32)
        }}.toolbar(.hidden, for: .navigationBar)
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 12) {
            PauseSectionHeader(title: "Fourteen-day picture")
            HStack(spacing: 10) {
                metric("\(completed)", "checked", "checkmark")
                metric("\(postponed)", "postponed", "clock")
                metric("\(independent)", "independent", "hand.raised")
            }
        }
    }

    private var responseMix: some View {
        EditorialCard {
            VStack(alignment: .leading, spacing: 16) {
                PauseSectionHeader(title: "What happened after a prompt?", subtitle: "Postponing is treated as a choice—not a failure.")
                if activity.isEmpty { EmptyStateView(title: "No pattern yet", message: "Actions will appear after you respond to reminders or guides.", symbol: "chart.bar") }
                else {
                    Chart(PauseActivity.Kind.allCases, id: \.self) { kind in
                        let count = activity.filter { $0.kind == kind }.count
                        BarMark(x: .value("Count", count), y: .value("Action", kind.rawValue)).foregroundStyle(color(for: kind)).cornerRadius(5).annotation(position: .trailing) { Text("\(count)").font(.caption.bold()) }
                    }.frame(height: 190).chartXAxis(.hidden).chartLegend(.hidden)
                }
            }
        }
    }

    private var confidenceTrend: some View {
        EditorialCard(color: PauseTheme.forest) {
            VStack(alignment: .leading, spacing: 15) {
                Text("CAPABILITY SIGNAL").font(.caption.bold()).tracking(1.3).foregroundStyle(PauseTheme.sage)
                Text("Did the check help?").font(.title2.bold()).foregroundStyle(.white)
                if responses.isEmpty { Text("Pause asks about preparedness because closing a reminder cannot prove that someone feels more capable.").foregroundStyle(.white.opacity(0.72)) }
                else {
                    Chart(Array(responses.enumerated()), id: \.element.id) { index, response in
                        LineMark(x: .value("Reflection", index + 1), y: .value("Preparedness", score(response.feeling))).foregroundStyle(PauseTheme.sage).interpolationMethod(.catmullRom)
                        PointMark(x: .value("Reflection", index + 1), y: .value("Preparedness", score(response.feeling))).foregroundStyle(PauseTheme.orange).symbolSize(70)
                    }.frame(height: 150).chartYScale(domain: 1...3).chartYAxis { AxisMarks(values: [1, 2, 3]) { value in AxisGridLine().foregroundStyle(.white.opacity(0.12)); AxisValueLabel { if let number = value.as(Int.self) { Text(number == 3 ? "Prepared" : number == 2 ? "Same" : "Unsure").foregroundStyle(.white.opacity(0.7)) } } } }.chartXAxis(.hidden)
                    Text("Recent reflections move from uncertainty toward preparedness. This is descriptive, not a medical outcome claim.").font(.caption).foregroundStyle(.white.opacity(0.68))
                }
            }
        }
    }

    private var adaptiveSuggestion: some View {
        EditorialCard(color: PauseTheme.sage) {
            VStack(alignment: .leading, spacing: 12) {
                Label("A transparent suggestion", systemImage: "lightbulb.fill").font(.headline).foregroundStyle(PauseTheme.forest)
                Text(suggestionTitle).font(.title3.bold())
                Text(suggestionReason).font(.subheadline).foregroundStyle(PauseTheme.muted)
                Text("Pause will never change a reminder without permission.").font(.caption.bold()).foregroundStyle(PauseTheme.forest)
            }
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            PauseSectionHeader(title: "Activity record", subtitle: "Every visible insight can be traced to an action.")
            if activity.isEmpty { EmptyStateView(title: "Nothing recorded yet", message: "Your local activity history will appear here.", symbol: "list.bullet.rectangle") }
            else { ForEach(activity.prefix(12)) { item in
                HStack(alignment: .top, spacing: 13) {
                    Image(systemName: item.kind.symbol).foregroundStyle(color(for: item.kind)).frame(width: 38, height: 38).background(color(for: item.kind).opacity(0.12), in: Circle())
                    VStack(alignment: .leading, spacing: 3) { HStack { Text(item.kind.rawValue).font(.subheadline.bold()); Spacer(); Text(item.date.formatted(.dateTime.month(.abbreviated).day().hour().minute())).font(.caption2).foregroundStyle(PauseTheme.muted) }; Text(item.title).font(.subheadline); Text(item.note).font(.caption).foregroundStyle(PauseTheme.muted) }
                }.padding(15).background(PauseTheme.paper, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(PauseTheme.ink.opacity(0.07)))
            } }
        }
    }

    private func metric(_ value: String, _ label: String, _ symbol: String) -> some View { EditorialCard(padding: 15) { VStack(alignment: .leading, spacing: 6) { Image(systemName: symbol).foregroundStyle(PauseTheme.orange); Text(value).font(.title2.bold()).monospacedDigit(); Text(label).font(.caption2).foregroundStyle(PauseTheme.muted) } } }
    private func score(_ feeling: RoutineResponse.Feeling) -> Int { switch feeling { case .morePrepared: 3; case .aboutTheSame: 2; case .stillUnsure: 1 } }
    private func color(for kind: PauseActivity.Kind) -> Color { switch kind { case .completed: PauseTheme.forest; case .postponed: PauseTheme.orange; case .skipped: PauseTheme.muted; case .guided: PauseTheme.violet; case .independent: PauseTheme.sky } }
    private var averageDelay: Int { let values = activity.compactMap(\.delayMinutes); return values.isEmpty ? 0 : values.reduce(0, +) / values.count }
    private var suggestionTitle: String { postponed >= 2 ? "Try moving the evening prompt 10 minutes later." : "Keep the current reminder times for now." }
    private var suggestionReason: String { postponed >= 2 ? "Several prompts were postponed by about \(averageDelay) minutes. A later reminder may fit the existing routine better." : "There is not enough postponement history to justify recommending a change." }
}
