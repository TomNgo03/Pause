import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @Query(sort: \IntentionalSession.plannedStart, order: .reverse) private var sessions: [IntentionalSession]
    @State private var attention: AttentionState?

    var body: some View {
        ZStack {
            PauseBackground()
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    header
                    DailyPauseCard(message: DailyPause.message())
                    checkIn
                    recommendation
                    overview
                }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 34)
            }
        }.toolbar(.hidden, for: .navigationBar).foregroundStyle(PauseTheme.ink)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())).font(.caption.weight(.semibold)).textCase(.uppercase).tracking(1).foregroundStyle(PauseTheme.muted)
                Text("\(greeting),\n\(model.preferences.displayName).").font(.system(size: 38, weight: .bold, design: .serif)).tracking(-1)
            }
            Spacer()
            Button { model.route = .profile } label: {
                Text(String(model.preferences.displayName.prefix(1)).uppercased()).font(.headline).foregroundStyle(.white).frame(width: 46, height: 46).background(PauseTheme.forest, in: Circle())
            }.accessibilityLabel("Open your profile")
        }
    }

    private var checkIn: some View {
        VStack(alignment: .leading, spacing: 14) {
            PauseSectionHeader(title: "How is your attention feeling?", subtitle: "Choose what feels closest right now.")
            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 9) { ForEach(AttentionState.allCases) { item in
                Button(item.rawValue) { withAnimation(.easeOut(duration: 0.2)) { attention = item } }
                    .buttonStyle(MoodChipStyle(selected: attention == item))
            } } }
        }
    }

    private var recommendation: some View {
        let item = Recommendation.forState(attention ?? AttentionState(rawValue: model.preferences.initialAttention) ?? .clear, preferred: model.preferences.preferredMinutes)
        return EditorialCard(color: PauseTheme.forest) {
            VStack(alignment: .leading, spacing: 15) {
                Text("YOUR NEXT MOVE").font(.caption.bold()).tracking(1.5).foregroundStyle(PauseTheme.sage)
                Text(item.title).font(.system(size: 27, weight: .bold, design: .serif)).foregroundStyle(.white)
                Text(item.reason).font(.subheadline).foregroundStyle(.white.opacity(0.72))
                Button { if item.opensCoach { model.route = .aiPlanner } else { model.route = .plan } } label: {
                    Label(item.opensCoach ? "Build a plan" : "Begin journey", systemImage: "arrow.up.right")
                        .font(.headline).foregroundStyle(PauseTheme.ink).padding(.horizontal, 18).frame(height: 48).background(PauseTheme.sage, in: Capsule())
                }.buttonStyle(.plain)
            }
        }
    }

    private var overview: some View {
        let today = sessions.filter { Calendar.current.isDateInToday($0.plannedStart) }
        let minutes = today.reduce(0) { $0 + $1.actualMinutes }
        let total = sessions.filter { !$0.isDemoData || model.preferences.demoDataEnabled }.reduce(0) { $0 + $1.actualMinutes }
        return VStack(alignment: .leading, spacing: 13) {
            PauseSectionHeader(title: "Today at a glance")
            EditorialCard { HStack(spacing: 18) {
                MetricPill(value: "\(minutes)", label: "focus minutes")
                Divider().frame(height: 42)
                MetricPill(value: "\(today.count)", label: "sessions")
                Divider().frame(height: 42)
                MetricPill(value: PlanetJourney.nextProgress(totalMinutes: total), label: "next planet")
            } }
        }
    }

    private var greeting: String { switch Calendar.current.component(.hour, from: .now) { case 5..<12: "Good morning"; case 12..<18: "Good afternoon"; default: "Good evening" } }
}

enum AttentionState: String, CaseIterable, Identifiable { case clear = "Clear", restless = "Restless", tired = "Tired", overwhelmed = "Overwhelmed"; var id: String { rawValue } }

private struct Recommendation { let title: String; let reason: String; let opensCoach: Bool
    static func forState(_ state: AttentionState, preferred: Int) -> Self { switch state {
    case .clear: .init(title: "Go deeper for \(max(25, preferred)) minutes.", reason: "Your attention feels available, so this is a good moment for meaningful work.", opensCoach: false)
    case .restless: .init(title: "Choose one thing for 15 minutes.", reason: "A narrow intention can give restless attention somewhere clear to land.", opensCoach: false)
    case .tired: .init(title: "Make the task smaller.", reason: "A gentle 15-minute session protects momentum without ignoring your energy.", opensCoach: false)
    case .overwhelmed: .init(title: "Turn the pressure into steps.", reason: "Coach can break the work into a realistic first move.", opensCoach: true)
    } }
}

private struct MoodChipStyle: ButtonStyle { let selected: Bool
    func makeBody(configuration: Configuration) -> some View { configuration.label.font(.subheadline.weight(.semibold)).padding(.horizontal, 16).frame(height: 46).foregroundStyle(selected ? Color.white : PauseTheme.ink).background(selected ? PauseTheme.orange : PauseTheme.paper, in: Capsule()).overlay(Capsule().stroke(PauseTheme.ink.opacity(0.1))) }
}

struct DailyPauseCard: View { let message: String
    var body: some View { EditorialCard(color: PauseTheme.sage) { VStack(alignment: .leading, spacing: 14) { HStack { Text("DAILY PAUSE").font(.caption.bold()).tracking(1.5); Spacer(); Image(systemName: "quote.opening").font(.title2) }.foregroundStyle(PauseTheme.forest.opacity(0.72)); Text(message).font(.system(size: 27, weight: .semibold, design: .serif)).lineSpacing(3) } } }
}

enum DailyPause {
    static let messages = [
        "You do not need more time. You need a clear next step.", "Attention grows where you place it gently.", "Begin before you feel completely ready.", "A smaller promise kept is meaningful progress.", "Make room for the work that matters.", "Your pace can be calm and still move forward.", "One honest session is enough for today.", "Choose what deserves the next few minutes.", "Rest is part of sustainable attention.", "Let the next step be specific and kind.", "Focus is returning, not never wandering.", "You can change direction without judging the detour.", "Start with what is possible from here.", "A clear intention makes technology a tool again.", "Progress does not need an audience.", "Protect the beginning; momentum can follow.", "Notice the urge before you follow it.", "Your attention is valuable. Spend it on purpose.", "The goal is awareness, not perfect control.", "Finish one small circle before opening another.", "A pause creates space for a better choice.", "Work with your energy, not against your worth.", "Today’s effort does not need to resemble yesterday’s.", "Name the task. Make it smaller. Begin.", "The most useful plan is the one you can start.", "Quiet progress still counts.", "Give one task the dignity of your full attention.", "You are allowed to begin again without a penalty.", "Clarity often arrives after the first step.", "Choose depth for a few minutes.", "A thoughtful stop can be a form of progress.", "Make the screen serve the intention.", "Leave enough space to notice what you need.", "Your next choice matters more than the last distraction.", "Consistency can be flexible and still be real.", "Attention is a practice, not a personality trait.", "Let enough be enough when the session ends.", "One meaningful action can reshape an afternoon.", "Build trust with yourself in small minutes.", "Do less at once, with more intention.", "The plan can change; the purpose can remain.", "Be curious about distraction instead of ashamed of it.", "A calm start is still a strong start.", "Make the first step easy to recognize.", "Pause long enough to choose, then move.", "What matters now can be simple.", "A break chosen intentionally is not lost time.", "Return to the task without carrying the detour.", "You are practicing how to direct your day.", "Let this session be useful, not perfect."
    ]
    static func message(on date: Date = .now) -> String { let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0; return messages[abs(day) % messages.count] }
}

enum PlanetJourney { static let milestones = [("Launch", 15), ("Moon", 25), ("Mars", 60), ("Saturn", 150), ("Neptune", 300), ("Beyond", 600)]
    static func nextProgress(totalMinutes: Int) -> String { guard let next = milestones.first(where: { totalMinutes < $0.1 }) else { return "Complete" }; return "\(min(100, totalMinutes * 100 / next.1))%" }
}
