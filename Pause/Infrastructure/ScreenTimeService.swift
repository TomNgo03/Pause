import Foundation

protocol ScreenTimeControlling {
    var modeDescription: String { get }
    func requestAuthorization() async throws
    func beginIntentionalSession(until: Date) async throws
    func endIntentionalSession() async
    func protectSelectedApps() async
}

struct PrototypeScreenTimeService: ScreenTimeControlling {
    let modeDescription = "Prototype Mode"
    func requestAuthorization() async throws {}
    func beginIntentionalSession(until: Date) async throws {}
    func endIntentionalSession() async {}
    func protectSelectedApps() async {}
}

enum ScreenTimeServiceFactory {
    static func make() -> ScreenTimeControlling {
        #if PAUSE_SCREEN_TIME
        return AppleScreenTimeService()
        #else
        return PrototypeScreenTimeService()
        #endif
    }
}

#if PAUSE_SCREEN_TIME
import FamilyControls
import ManagedSettings
import DeviceActivity

@available(iOS 16.0, *)
final class AppleScreenTimeService: ScreenTimeControlling {
    let modeDescription = "Screen Time Mode"
    private let store = ManagedSettingsStore(named: .init("Pause"))
    private let defaults = UserDefaults(suiteName: "group.org.pauseproject.shared")!
    private let selectionKey = "familyActivitySelection"

    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }

    func save(selection: FamilyActivitySelection) throws {
        defaults.set(try PropertyListEncoder().encode(selection), forKey: selectionKey)
    }

    private func selection() -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: selectionKey) else { return nil }
        return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    func protectSelectedApps() async {
        guard let selection = selection() else { return }
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
    }

    func beginIntentionalSession(until: Date) async throws {
        defaults.set(until, forKey: "sessionEnd")
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let start = calendar.dateComponents(components, from: .now)
        let end = calendar.dateComponents(components, from: until)
        let schedule = DeviceActivitySchedule(intervalStart: start, intervalEnd: end, repeats: false)
        let center = DeviceActivityCenter()
        center.stopMonitoring([.pauseIntentionalSession])
        try center.startMonitoring(.pauseIntentionalSession, during: schedule)
        store.clearAllSettings()
    }

    func endIntentionalSession() async {
        DeviceActivityCenter().stopMonitoring([.pauseIntentionalSession])
        await protectSelectedApps()
    }
}

private extension DeviceActivityName {
    static let pauseIntentionalSession = Self("pause.intentional.session")
}
#endif
