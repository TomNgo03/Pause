import SwiftUI
import SwiftData

@main
struct PauseApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
                .task { await appModel.reconcileSession() }
                .onOpenURL { url in
                    if url.host == "reflect" { appModel.route = .reflection }
                }
        }
        .modelContainer(for: IntentionalSession.self)
    }
}

