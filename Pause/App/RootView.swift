import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            switch model.auth.state {
            case .restoring:
                LaunchView()
            case .signedOut:
                AuthFlowView()
            case .signedIn:
                if !model.preferences.onboardingComplete {
                    OnboardingView()
                } else {
                    appContent
                }
            }
        }
        .tint(PauseTheme.indigo)
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
                    case .social: SocialHubView()
                    case .profile: ProfileView()
                    case .active: ActiveSessionView()
                    case .reflection: ReflectionView()
                    case .dashboard: DashboardView()
                    case .settings: SettingsView()
                    }
                }
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
