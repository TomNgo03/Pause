import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @Query private var sessions: [IntentionalSession]
    @AppStorage("hideGettingStarted") private var hideGettingStarted = false
    @State private var showingHelp = false

    var body: some View {
        ZStack {
            PauseBackground()
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 26) {
                    header
                    dailyHero
                    if sessions.isEmpty && !hideGettingStarted { gettingStarted }
                    primaryChoice
                    moreChoices
                    progressPreview
                    Text("You do not need to use every feature. Start with one small session.")
                        .font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.top, 4)
                }.padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 36)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingHelp) { HowPauseWorksView() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) { Text(greeting).font(.subheadline).foregroundStyle(.secondary); Text(model.social.profile.displayName).font(.title2.weight(.heavy)) }
            Spacer()
            Button { showingHelp = true } label: { Image(systemName: "questionmark").font(.headline).frame(width: 42, height: 42).background(PauseTheme.elevated, in: Circle()) }.accessibilityLabel("How Pause works")
            Button { model.route = .profile } label: {
                Circle().fill(PauseTheme.heroGradient).frame(width: 44, height: 44)
                    .overlay(Text(String(model.social.profile.displayName.prefix(1))).font(.headline).foregroundStyle(.white))
                    .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 2))
            }.accessibilityLabel("Open profile")
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    private var dailyHero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous).fill(PauseTheme.heroGradient)
            Circle().fill(.white.opacity(0.12)).frame(width: 190).offset(x: 230, y: -50)
            Circle().fill(PauseTheme.mint.opacity(0.18)).frame(width: 120).offset(x: 280, y: 55)
            VStack(alignment: .leading, spacing: 11) {
                Label("TODAY", systemImage: "sun.max.fill").font(.caption.bold()).tracking(1.4).foregroundStyle(.white.opacity(0.75))
                Text(sessions.isEmpty ? "Begin with one\nsmall intention." : "You’ve shown up\n\(sessions.count) time\(sessions.count == 1 ? "" : "s").")
                    .font(.system(size: 29, weight: .bold, design: .rounded)).tracking(-0.5)
                Text("No streak pressure. Just your next conscious choice.").font(.subheadline).foregroundStyle(.white.opacity(0.78))
            }.padding(24)
        }
        .frame(height: 220).clipped().clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: PauseTheme.indigo.opacity(0.24), radius: 10, y: 6)
    }

    private var gettingStarted: some View {
        PauseCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack { VStack(alignment: .leading, spacing: 3) { Text("New here?").font(.title3.bold()); Text("Pause has one simple loop").font(.subheadline).foregroundStyle(.secondary) }; Spacer(); Button { hideGettingStarted = true } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary) }.accessibilityLabel("Hide getting started") }
                guideRow(1, "Choose one intention", "Decide what you want before opening an app.")
                guideRow(2, "Set a realistic time", "Two minutes is a perfectly good start.")
                guideRow(3, "Notice what happened", "A reflection is optional and never graded.")
            }
        }
    }

    private var primaryChoice: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ready when you are").font(.title2.bold())
            Button { model.route = .plan } label: {
                HStack(spacing: 16) {
                    Image(systemName: "play.fill").font(.title2).frame(width: 54, height: 54).background(PauseTheme.indigo, in: RoundedRectangle(cornerRadius: 17))
                    VStack(alignment: .leading, spacing: 4) { Text("Start a focus session").font(.title3.bold()); Text("Choose one goal and a realistic time").font(.subheadline).foregroundStyle(.secondary) }
                    Spacer(); Image(systemName: "chevron.right").font(.headline)
                }.padding(20).foregroundStyle(.white).background(PauseTheme.card, in: RoundedRectangle(cornerRadius: 25)).overlay(RoundedRectangle(cornerRadius: 25).stroke(.white.opacity(0.08)))
            }.buttonStyle(.plain).accessibilityIdentifier("planSession")
        }
    }

    private var moreChoices: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Or get a little help").font(.headline).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                friendlyChoice("Make a plan", "AI-assisted", "wand.and.stars", PauseTheme.violet) { model.route = .aiPlanner }
                friendlyChoice("Focus with friends", "Private circles", "person.2.fill", PauseTheme.mint) { model.route = .social }
            }
        }
    }

    private var progressPreview: some View {
        Button { model.route = .dashboard } label: {
            PauseCard { HStack(spacing: 14) {
                PauseIcon(systemName: "chart.line.uptrend.xyaxis", color: PauseTheme.sky)
                VStack(alignment: .leading, spacing: 3) { Text("My reflections").font(.headline).foregroundStyle(.primary); Text(sessions.isEmpty ? "Nothing to review yet" : "\(sessions.count) session\(sessions.count == 1 ? "" : "s") recorded").font(.caption).foregroundStyle(.secondary) }
                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            } }
        }.buttonStyle(.plain)
    }

    private func guideRow(_ number: Int, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) { Text("\(number)").font(.subheadline.bold()).foregroundStyle(.white).frame(width: 28, height: 28).background(PauseTheme.indigo, in: Circle()); VStack(alignment: .leading, spacing: 2) { Text(title).font(.subheadline.bold()); Text(body).font(.caption).foregroundStyle(.secondary) } }
    }

    private func friendlyChoice(_ title: String, _ subtitle: String, _ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) { VStack(alignment: .leading, spacing: 12) { PauseIcon(systemName: icon, color: color); Text(title).font(.headline).foregroundStyle(.primary); Text(subtitle).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(PauseTheme.card, in: RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.07))) }.buttonStyle(.plain)
    }
}
private struct HowPauseWorksView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView { VStack(alignment: .leading, spacing: 20) {
                Text("Pause helps you make one conscious decision before a digital session. You can ignore every advanced feature and use only the basic timer.").font(.title3).foregroundStyle(.secondary)
                help("1", "Choose", "Pick what you want to accomplish.", "scope")
                help("2", "Focus", "Choose a realistic time and begin.", "timer")
                help("3", "Reflect", "Optionally notice what worked. Nothing is graded.", "sparkles")
                PauseCard { Label("Need urgent access? Pause should never prevent safety or important communication.", systemImage: "heart.fill").foregroundStyle(PauseTheme.coral) }
            }.padding(22) }
            .navigationTitle("How Pause works").navigationBarTitleDisplayMode(.inline).toolbar { Button("Done") { dismiss() } }
        }
    }
    private func help(_ number: String, _ title: String, _ body: String, _ icon: String) -> some View { PauseCard { HStack(spacing: 14) { PauseIcon(systemName: icon); VStack(alignment: .leading, spacing: 4) { Text("\(number). \(title)").font(.headline); Text(body).foregroundStyle(.secondary) } } } }
}
