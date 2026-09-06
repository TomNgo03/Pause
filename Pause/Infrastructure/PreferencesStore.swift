import Foundation

final class PreferencesStore {
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var onboardingComplete: Bool {
        get { defaults.bool(forKey: "onboardingComplete") }
        set { defaults.set(newValue, forKey: "onboardingComplete") }
    }

    var participantCode: String {
        get {
            if let existing = defaults.string(forKey: "participantCode") { return existing }
            let code = "P-" + String(UUID().uuidString.prefix(6)).uppercased()
            defaults.set(code, forKey: "participantCode")
            return code
        }
        set { defaults.set(newValue, forKey: "participantCode") }
    }

    func reset() {
        ["onboardingComplete", "participantCode"].forEach { defaults.removeObject(forKey: $0) }
    }
}

enum SessionRecoveryStore {
    private static let key = "activeSession"
    static func save(_ session: SessionDraft) {
        UserDefaults.standard.set(try? JSONEncoder().encode(session), forKey: key)
    }
    static func load() -> SessionDraft? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SessionDraft.self, from: data)
    }
    static func clear() { UserDefaults.standard.removeObject(forKey: key) }
}
