import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @Query(sort: \IntentionalSession.plannedStart, order: .reverse) private var sessions: [IntentionalSession]
    private var recent: [IntentionalSession] { sessions.filter { $0.plannedStart >= Calendar.current.date(byAdding: .day, value: -7, to: .now)! } }

    var body: some View {
        let summary = SessionAnalytics.summarize(recent)
        ZStack {
            PauseBackground()
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 22) {
                    header(summary); metrics(summary); chart; insight(summary)
                    Label("These patterns are descriptive—not a measure of addiction, worth, productivity, grades, or mental health.", systemImage: "info.circle").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 4)
                }.padding(20).padding(.bottom, 20)
            }
        }
        .navigationTitle("Your journey").navigationBarTitleDisplayMode(.large)
    }

    private func header(_ summary: DashboardSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { VStack(alignment: .leading, spacing: 4) { Text("Your week, gently reflected").font(.title2.bold()); Text("Look for patterns, not perfection.").foregroundStyle(.secondary) }; Spacer(); PauseIcon(systemName: "chart.line.uptrend.xyaxis", color: PauseTheme.sky, size: 54) }
            if let rate = summary.completionRate { HStack(alignment: .firstTextBaseline, spacing: 5) { Text(rate.formatted(.percent.precision(.fractionLength(0)))).font(.system(size: 44, weight: .bold, design: .rounded)); Text("of answered reflections matched your original intention").font(.subheadline).foregroundStyle(.secondary) } }
            else { Text("Your first reflection will create the beginning of a pattern.").font(.headline).foregroundStyle(.secondary) }
        }.padding(.top, 4)
    }

    private func metrics(_ summary: DashboardSummary) -> some View {
        HStack(spacing: 10) { metric("Sessions", "\(summary.totalSessions)", "timer", PauseTheme.indigo); metric("Reflected", "\(summary.reflectedSessions)", "text.bubble", PauseTheme.mint); metric("Adjusted", "\(summary.extensionCount)", "arrow.triangle.2.circlepath", PauseTheme.coral) }
    }

    private func metric(_ label: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        PauseCard(padding: 13) { VStack(alignment: .leading, spacing: 8) { Image(systemName: icon).foregroundStyle(color); Text(value).font(.title2.bold()); Text(label).font(.caption2).foregroundStyle(.secondary) } }
    }

    @ViewBuilder private var chart: some View {
        PauseCard { VStack(alignment: .leading, spacing: 14) {
            PauseSectionHeader(title: "Intentional sessions", subtitle: "Last seven days")
            if recent.isEmpty { ContentUnavailableView("No sessions yet", systemImage: "chart.bar", description: Text("Start a small plan when you are ready.")) }
            else { Chart(recent, id: \.id) { item in BarMark(x: .value("Day", item.plannedStart, unit: .day), y: .value("Sessions", 1)).foregroundStyle(PauseTheme.heroGradient).cornerRadius(5) }.frame(height: 180).chartYAxis(.hidden).accessibilityLabel("Intentional sessions by day") }
        } }
    }

    private func insight(_ summary: DashboardSummary) -> some View {
        PauseCard { HStack(alignment: .top, spacing: 14) { PauseIcon(systemName: "sparkles", color: PauseTheme.violet); VStack(alignment: .leading, spacing: 5) { Text("A useful next experiment").font(.headline); Text(summary.totalSessions == 0 ? "Try one 10-minute session and notice whether the duration felt realistic." : "Keep the next plan small enough to finish, and change it if circumstances change.").font(.subheadline).foregroundStyle(.secondary) } } }
    }
}
