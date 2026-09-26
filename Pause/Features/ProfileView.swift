import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject private var model: AppModel
    @Query private var sessions: [IntentionalSession]
    @State private var name = ""
    @State private var statement = ""
    private var realSessions: [IntentionalSession] { sessions.filter { !$0.isDemoData } }
    private var minutes: Int { realSessions.reduce(0) { $0 + $1.actualMinutes } }
    private var achievements: [MindfulAchievement] { MindfulAchievement.unlocked(from: realSessions, weeklyReflection: UserDefaults.standard.string(forKey: "weeklyReflection") ?? "") }

    var body: some View {
        ZStack { PauseBackground(); ScrollView(showsIndicators: false) { VStack(alignment: .leading, spacing: 24) {
            HStack { Text("YOU").font(.caption.bold()).tracking(1.5).foregroundStyle(PauseTheme.orange); Spacer(); Button { model.route = .settings } label: { Image(systemName: "gearshape.fill").frame(width: 44, height: 44).background(PauseTheme.sage, in: Circle()) }.accessibilityLabel("Settings") }
            profileHero
            VStack(alignment: .leading, spacing: 13) { PauseSectionHeader(title: "Milestones", subtitle: "Evidence of mindful practice, not competition."); if achievements.isEmpty { EmptyStateView(title: "Your first milestone is close", message: "Complete one intentional session to earn First Launch.", symbol: "paperplane") } else { ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(achievements.prefix(3)) { PlanetBadge(achievement: $0) } } } } }
            personalDetails
            shareCard
        }.padding(20).padding(.bottom, 30) } }.foregroundStyle(PauseTheme.ink).toolbar(.hidden, for: .navigationBar).onAppear { name = model.preferences.displayName; statement = model.preferences.focusStatement }
    }

    private var profileHero: some View { EditorialCard(color: PauseTheme.forest) { VStack(alignment: .leading, spacing: 18) { HStack { Text(String((name.isEmpty ? "P" : name).prefix(1)).uppercased()).font(.system(size: 32, weight: .bold, design: .serif)).foregroundStyle(PauseTheme.forest).frame(width: 72, height: 72).background(PauseTheme.sage, in: Circle()); Spacer(); Text(model.preferences.primaryGoal.uppercased()).font(.caption.bold()).tracking(1.2).foregroundStyle(PauseTheme.sage) }; Text(name.isEmpty ? "Your Pause profile" : name).font(.system(size: 32, weight: .bold, design: .serif)).foregroundStyle(.white); Text(statement).foregroundStyle(.white.opacity(0.7)); HStack { MetricPill(value: "\(minutes)m", label: "focused"); MetricPill(value: "\(realSessions.count)", label: "journeys"); MetricPill(value: "\(achievements.count)", label: "milestones") }.foregroundStyle(.white) } } }
    private var personalDetails: some View { EditorialCard { VStack(alignment: .leading, spacing: 14) { Text("Personal profile").font(.title3.bold()); TextField("Display name", text: $name).textFieldStyle(.roundedBorder); TextField("What do you want technology to support?", text: $statement, axis: .vertical).textFieldStyle(.roundedBorder); Button("Save changes") { model.preferences.displayName = name.trimmingCharacters(in: .whitespaces); model.preferences.focusStatement = statement; model.objectWillChange.send() }.buttonStyle(SoftButtonStyle()) } } }
    private var shareCard: some View { EditorialCard(color: PauseTheme.sage) { VStack(alignment: .leading, spacing: 13) { Label("Share progress, not private reflections", systemImage: "lock.shield.fill").font(.headline); Text("Your share card includes only your name and overall journey totals.").font(.subheadline).foregroundStyle(PauseTheme.muted); ShareLink(item: "\(name.isEmpty ? "I" : name) completed \(realSessions.count) intentional focus journeys and \(minutes) mindful minutes with Pause.") { Label("Share my journey", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity) }.buttonStyle(SoftButtonStyle()) } } }
}

struct MindfulAchievement: Identifiable { let id: String; let title: String; let detail: String; let symbol: String
    static func unlocked(from sessions: [IntentionalSession], weeklyReflection: String) -> [Self] {
        var result: [Self] = []
        func add(_ condition: Bool, _ id: String, _ title: String, _ detail: String, _ symbol: String) { if condition { result.append(.init(id: id, title: title, detail: detail, symbol: symbol)) } }
        add(!sessions.isEmpty, "launch", "First Launch", "Completed a first journey", "paperplane.fill")
        add(sessions.filter { !$0.task.isEmpty }.count >= 5, "intent", "Intentional Start", "Named five clear intentions", "scope")
        add(sessions.filter { $0.focusRating > 0 }.count >= 5, "honest", "Honest Explorer", "Reflected five times", "text.bubble.fill")
        add(Set(sessions.map { Calendar.current.startOfDay(for: $0.plannedStart) }).count >= 3, "return", "Returning Traveler", "Focused on three days", "arrow.uturn.backward")
        add(sessions.contains { $0.actualMinutes >= 40 }, "deep", "Deep Orbit", "Completed a 40-minute journey", "circle.dotted")
        add(sessions.count >= 7, "steady", "Steady Journey", "Completed seven journeys", "map.fill")
        add(!weeklyReflection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "week", "Mindful Week", "Wrote a weekly reflection", "calendar")
        return result
    }
}

struct PlanetBadge: View { let achievement: MindfulAchievement
    var body: some View { VStack(spacing: 9) { Image(systemName: achievement.symbol).font(.title2).foregroundStyle(.white).frame(width: 64, height: 64).background(PauseTheme.orange, in: Circle()); Text(achievement.title).font(.caption.bold()); Text(achievement.detail).font(.caption2).foregroundStyle(PauseTheme.muted).multilineTextAlignment(.center).lineLimit(2) }.frame(width: 120) }
}
