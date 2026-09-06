import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            PauseBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header; hero; quickActions; today; communityPreview; safetyNote
                }.padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 32)
            }
        }.toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack { RoundedRectangle(cornerRadius: 15).fill(PauseTheme.heroGradient).frame(width: 48, height: 48); Image(systemName: "pause.fill").foregroundStyle(.white).font(.title3.bold()) }
            VStack(alignment: .leading, spacing: 1) { Text("Pause").font(.title2.weight(.heavy)); Text(greeting).font(.subheadline).foregroundStyle(.secondary) }
            Spacer()
            Button { model.route = .settings } label: { Image(systemName: "gearshape.fill").foregroundStyle(.primary).frame(width: 42, height: 42).background(.thinMaterial, in: Circle()) }.accessibilityLabel("Settings")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Label(model.screenTime.modeDescription, systemImage: "shield.lefthalf.filled").font(.caption.weight(.semibold)).padding(.horizontal, 11).padding(.vertical, 7).background(.white.opacity(0.16), in: Capsule()); Spacer(); Image(systemName: "sparkles").font(.title2) }
            Text("What deserves your\nattention right now?").font(.system(.largeTitle, design: .rounded, weight: .bold)).tracking(-0.7)
            Text("Make one conscious choice. Pause will help with the rest.").font(.subheadline).foregroundStyle(.white.opacity(0.82))
            Button { model.route = .plan } label: { Label("Start an intentional session", systemImage: "arrow.right").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15).background(.white, in: RoundedRectangle(cornerRadius: 16)).foregroundStyle(PauseTheme.indigo) }.accessibilityIdentifier("planSession")
        }
        .foregroundStyle(.white).padding(22).background(PauseTheme.heroGradient, in: RoundedRectangle(cornerRadius: 30))
        .overlay(alignment: .topTrailing) { Circle().stroke(.white.opacity(0.10), lineWidth: 24).frame(width: 130).offset(x: 42, y: -42).allowsHitTesting(false) }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: PauseTheme.indigo.opacity(0.30), radius: 24, y: 14)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            PauseSectionHeader(title: "Choose your path", subtitle: "A small plan is still progress")
            HStack(spacing: 12) {
                actionCard("Plan with AI", "A realistic draft", "wand.and.stars", PauseTheme.violet) { model.route = .aiPlanner }
                actionCard("Focus together", "Friends, not rankings", "person.3.fill", PauseTheme.mint) { model.route = .social }
            }
        }
    }

    private var today: some View {
        VStack(alignment: .leading, spacing: 12) {
            PauseSectionHeader(title: "Your space")
            PauseCard { VStack(spacing: 0) {
                row("Protected apps", "Choose what needs a pause", "apps.iphone", PauseTheme.coral) { model.route = .appSelection }
                Divider().padding(.leading, 58)
                row("Weekly reflection", "Notice patterns without judgment", "chart.xyaxis.line", PauseTheme.sky) { model.route = .dashboard }
            } }
        }
    }

    private var communityPreview: some View {
        Button { model.route = .social } label: {
            PauseCard { HStack(spacing: 14) {
                HStack(spacing: -8) { avatar("H", PauseTheme.violet); avatar("M", PauseTheme.mint); avatar("L", PauseTheme.sky) }
                VStack(alignment: .leading, spacing: 3) { Text("Your circle is moving").font(.headline).foregroundStyle(.primary); Text(circleProgress).font(.caption).foregroundStyle(.secondary) }
                Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            } }
        }.buttonStyle(.plain)
    }

    private var safetyNote: some View { Label("Pause supports reflection—it does not judge, diagnose, or replace professional care.", systemImage: "heart.text.square").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 4) }

    private func actionCard(_ title: String, _ subtitle: String, _ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) { VStack(alignment: .leading, spacing: 12) { PauseIcon(systemName: icon, color: color); Text(title).font(.headline).foregroundStyle(.primary); Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1) }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22)) }.buttonStyle(.plain)
    }

    private func row(_ title: String, _ subtitle: String, _ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) { HStack(spacing: 12) { PauseIcon(systemName: icon, color: color, size: 44); VStack(alignment: .leading, spacing: 2) { Text(title).font(.subheadline.bold()); Text(subtitle).font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary) }.padding(.vertical, 10).contentShape(Rectangle()) }.buttonStyle(.plain)
    }

    private func avatar(_ letter: String, _ color: Color) -> some View { Text(letter).font(.caption.bold()).frame(width: 34, height: 34).background(color.gradient, in: Circle()).foregroundStyle(.white).overlay(Circle().stroke(PauseTheme.background, lineWidth: 2)) }
    private var circleProgress: String { guard let circle = model.social.circles.first else { return "Create a private accountability circle" }; return "\(circle.weeklyProgress) of \(circle.weeklyGoal) intentional sessions" }
    private var greeting: String { let hour = Calendar.current.component(.hour, from: .now); return hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening" }
}
