import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if !model.preferences.onboardingComplete { OnboardingView() }
            else { appContent }
        }
        .tint(PauseTheme.orange)
        .preferredColorScheme(.light)
        .alert("Pause needs attention", isPresented: $model.showingError) {
            Button("OK", role: .cancel) {}
        } message: { Text(model.errorMessage) }
    }

    private var appContent: some View {
        NavigationStack {
                    switch model.route {
                    case .home: HomeView()
                    case .appSelection: ProtectedAppsView()
                    case .plan: SessionPlannerView()
                    case .aiPlanner: AIPlannerView()
                    case .profile: ProfileView()
                    case .active: ActiveSessionView()
                    case .reflection: ReflectionView()
                    case .dashboard: DashboardView()
                    case .settings: SettingsView()
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if showsTabBar { PauseTabBar(selection: $model.route) }
                }
    }

    private var showsTabBar: Bool {
        [.home, .dashboard, .aiPlanner, .profile].contains(model.route)
    }
}

private struct PauseTabBar: View {
    @Binding var selection: AppModel.Route
    private let tabs: [(AppModel.Route, String, String)] = [
        (.home, "Today", "sun.max.fill"),
        (.dashboard, "Journey", "chart.bar.fill"),
        (.aiPlanner, "Coach", "sparkles"),
        (.profile, "You", "person.crop.circle.fill")
    ]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(tabs, id: \.1) { route, label, icon in
                Button {
                    selection = route
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icon).font(.system(size: 19, weight: .semibold))
                        Text(label).font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(selection == route ? PauseTheme.ink : PauseTheme.muted)
                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                    .background(selection == route ? PauseTheme.sage : .clear,
                                in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == route ? .isSelected : [])
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(PauseTheme.cream)
        .overlay(alignment: .top) { Rectangle().fill(PauseTheme.ink.opacity(0.10)).frame(height: 0.5) }
    }
}

private struct LaunchView: View {
    var body: some View {
        ZStack {
            PauseTheme.heroGradient.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 104, height: 104)
                    .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                Text("Pause").font(.system(size: 42, weight: .bold, design: .rounded)).foregroundStyle(.white)
                ProgressView().tint(.white).padding(.top, 8).accessibilityLabel("Restoring your account")
            }
        }
    }
}
