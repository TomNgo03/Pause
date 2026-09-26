import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    @Query(sort: \IntentionalSession.plannedStart, order: .reverse) private var allSessions: [IntentionalSession]
    @AppStorage("weeklyReflection") private var weeklyReflection = ""
    private var sessions: [IntentionalSession] { model.preferences.demoDataEnabled ? allSessions : allSessions.filter { !$0.isDemoData } }
    private var totalMinutes: Int { sessions.reduce(0) { $0 + $1.actualMinutes } }

    var body: some View {
        ZStack { PauseBackground(); ScrollView(showsIndicators: false) { LazyVStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 5) { Text("JOURNEY").font(.caption.bold()).tracking(1.5).foregroundStyle(PauseTheme.orange); Text("See where your\nattention has taken you.").font(.system(size: 36, weight: .bold, design: .serif)) }
            if model.preferences.demoDataEnabled { Label("Presentation mode · Demo data", systemImage: "sparkles").font(.caption.bold()).foregroundStyle(PauseTheme.orange) }
            spaceMap
            insights
            weeklyChart
            reflection
            Label("These patterns describe sessions—not your worth, health, or ability.", systemImage: "info.circle").font(.caption).foregroundStyle(PauseTheme.muted)
        }.padding(20).padding(.bottom, 30) } }.foregroundStyle(PauseTheme.ink).toolbar(.hidden, for: .navigationBar)
    }

    private var spaceMap: some View {
        VStack(alignment: .leading, spacing: 14) { PauseSectionHeader(title: "Your solar path", subtitle: "Every meaningful minute adds distance.")
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 14) { ForEach(Array(PlanetJourney.milestones.enumerated()), id: \.offset) { index, planet in
                let unlocked = totalMinutes >= planet.1
                VStack(spacing: 10) { ZStack { Circle().fill(unlocked ? [PauseTheme.orange, PauseTheme.sage, PauseTheme.violet, PauseTheme.coral][index % 4] : PauseTheme.ink.opacity(0.08)).frame(width: 72, height: 72); Image(systemName: unlocked ? "sparkles" : "lock.fill").foregroundStyle(unlocked ? .white : PauseTheme.muted) }; Text(planet.0).font(.subheadline.bold()); Text(unlocked ? "Discovered" : "\(planet.1)m").font(.caption).foregroundStyle(PauseTheme.muted) }.frame(width: 96).opacity(unlocked ? 1 : 0.6)
            } }.padding(.vertical, 5) }
        }
    }

    private var insights: some View { EditorialCard(color: PauseTheme.forest) { VStack(alignment: .leading, spacing: 18) { Text("THE SIGNALS THAT MATTER").font(.caption.bold()).tracking(1.3).foregroundStyle(PauseTheme.sage); HStack { MetricPill(value: "\(totalMinutes)m", label: "intentional time"); MetricPill(value: averageFocus, label: "average focus"); MetricPill(value: completionRate, label: "completed") }.foregroundStyle(.white); Divider().overlay(.white.opacity(0.2)); Text(insightText).font(.subheadline).foregroundStyle(.white.opacity(0.75)) } } }

    private var weeklyChart: some View { EditorialCard { VStack(alignment: .leading, spacing: 14) { PauseSectionHeader(title: "Last seven days"); if recent.isEmpty { EmptyStateView(title: "Your path starts here", message: "Complete one focus journey to create the first point.", symbol: "circle.dotted") } else { Chart(recent, id: \.id) { item in BarMark(x: .value("Day", item.plannedStart, unit: .day), y: .value("Minutes", item.actualMinutes)).foregroundStyle(PauseTheme.orange).cornerRadius(5) }.frame(height: 170).chartYAxis { AxisMarks(position: .leading) }.accessibilityLabel("Focus minutes during the last seven days") } } } }

    private var reflection: some View { EditorialCard(color: PauseTheme.sage) { VStack(alignment: .leading, spacing: 12) { Text("A note for this week").font(.title3.bold()); Text(sessions.isEmpty ? "After a few sessions, reflect on what helped your attention." : "What helped you return to what mattered?").foregroundStyle(PauseTheme.muted); TextField("Write a private reflection…", text: $weeklyReflection, axis: .vertical).lineLimit(3...6).padding(14).background(PauseTheme.paper, in: RoundedRectangle(cornerRadius: 14)) } } }
    private var recent: [IntentionalSession] { sessions.filter { $0.plannedStart >= Calendar.current.date(byAdding: .day, value: -7, to: .now)! } }
    private var averageFocus: String { let values = sessions.map(\.focusRating).filter { $0 > 0 }; guard !values.isEmpty else { return "—" }; return String(format: "%.1f/5", Double(values.reduce(0,+)) / Double(values.count)) }
    private var completionRate: String { let answered = sessions.filter { $0.outcome != .skipped }; guard !answered.isEmpty else { return "—" }; let rate = Double(answered.filter { $0.outcome == .yes }.count) / Double(answered.count); return rate.formatted(.percent.precision(.fractionLength(0))) }
    private var insightText: String { guard let common = sessions.map(\.mainDistraction).filter({ !$0.isEmpty && $0 != SessionDistraction.none.rawValue }).reduce(into: [:], { $0[$1, default: 0] += 1 }).max(by: { $0.value < $1.value })?.key else { return "Your reflections will reveal useful patterns without turning them into judgments." }; return "\(common) appears most often. Before the next session, try changing one small condition around it." }
}

struct EmptyStateView: View { let title: String; let message: String; let symbol: String
    var body: some View { VStack(spacing: 10) { Image(systemName: symbol).font(.largeTitle).foregroundStyle(PauseTheme.orange); Text(title).font(.headline); Text(message).font(.subheadline).foregroundStyle(PauseTheme.muted).multilineTextAlignment(.center) }.frame(maxWidth: .infinity).padding(.vertical, 24) }
}
