import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Group {
            if !model.preferences.onboardingComplete {
                OnboardingView()
            } else {
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
        .tint(PauseTheme.indigo)
        .alert("Pause needs attention", isPresented: $model.showingError) {
            Button("OK", role: .cancel) {}
        } message: { Text(model.errorMessage) }
    }
}
