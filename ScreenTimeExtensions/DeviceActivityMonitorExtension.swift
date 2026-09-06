#if PAUSE_SCREEN_TIME
import DeviceActivity
import FamilyControls
import ManagedSettings

final class PauseDeviceActivityMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: .init("Pause"))
    private let defaults = UserDefaults(suiteName: "group.org.pauseproject.shared")!

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard let data = defaults.data(forKey: "familyActivitySelection"),
              let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
    }
}

private extension DeviceActivityName {
    static let pauseIntentionalSession = Self("pause.intentional.session")
}
#endif
