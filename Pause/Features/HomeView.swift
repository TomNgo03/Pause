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
                VStack(alignment: .leading, spacing: 24) {
                    header
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
            ZStack { RoundedRectangle(cornerRadius: 15).fill(PauseTheme.heroGradient).frame(width: 48, height: 48); Image(systemName: "pause.fill").foregroundStyle(.white).font(.title3.bold()) }
            VStack(alignment: .leading, spacing: 1) { Text("Pause").font(.title2.weight(.heavy)); Text("One thing at a time").font(.subheadline).foregroundStyle(.secondary) }
            Spacer()
            Button { showingHelp = true } label: { Image(systemName: "questionmark").font(.headline).frame(width: 42, height: 42).background(.thinMaterial, in: Circle()) }.accessibilityLabel("How Pause works")
            Menu {
                Button("Choose apps to pause", systemImage: "apps.iphone") { model.route = .appSelection }
                Button("Settings and privacy", systemImage: "gearshape") { model.route = .settings }
                Button("My profile", systemImage: "person.crop.circle") { model.route = .profile }
            } label: { Image(systemName: "ellipsis").font(.headline).frame(width: 42, height: 42).background(.thinMaterial, in: Circle()) }.accessibilityLabel("More options")
        }
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
            Text("What would you like to do?").font(.title2.bold())
            Button { model.route = .plan } label: {
                HStack(spacing: 16) {
                    Image(systemName: "play.fill").font(.title2).frame(width: 54, height: 54).background(.white.opacity(0.17), in: RoundedRectangle(cornerRadius: 17))
                    VStack(alignment: .leading, spacing: 4) { Text("Start a focus session").font(.title3.bold()); Text("Choose a goal and a few minutes").font(.subheadline).foregroundStyle(.white.opacity(0.78)) }
                    Spacer(); Image(systemName: "chevron.right").font(.headline)
                }.padding(20).foregroundStyle(.white).background(PauseTheme.heroGradient, in: RoundedRectangle(cornerRadius: 25)).shadow(color: PauseTheme.indigo.opacity(0.24), radius: 18, y: 10)
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
        Button(action: action) { VStack(alignment: .leading, spacing: 12) { PauseIcon(systemName: icon, color: color); Text(title).font(.headline).foregroundStyle(.primary); Text(subtitle).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22)) }.buttonStyle(.plain)
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
