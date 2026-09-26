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

    var displayName: String {
        get { defaults.string(forKey: "displayName") ?? "Huy" }
        set { defaults.set(newValue, forKey: "displayName") }
    }

    var primaryGoal: String {
        get { defaults.string(forKey: "primaryGoal") ?? "Study" }
        set { defaults.set(newValue, forKey: "primaryGoal") }
    }

    var preferredMinutes: Int {
        get { let value = defaults.integer(forKey: "preferredMinutes"); return value == 0 ? 25 : value }
        set { defaults.set(newValue, forKey: "preferredMinutes") }
    }

    var initialAttention: String {
        get { defaults.string(forKey: "initialAttention") ?? "Clear" }
        set { defaults.set(newValue, forKey: "initialAttention") }
    }

    var focusStatement: String {
        get { defaults.string(forKey: "focusStatement") ?? "I want technology to support what matters to me." }
        set { defaults.set(newValue, forKey: "focusStatement") }
    }

    var demoDataEnabled: Bool {
        get { defaults.bool(forKey: "demoDataEnabled") }
        set { defaults.set(newValue, forKey: "demoDataEnabled") }
    }

    func reset() {
        ["onboardingComplete", "participantCode", "displayName", "primaryGoal", "preferredMinutes", "initialAttention", "focusStatement", "demoDataEnabled"].forEach { defaults.removeObject(forKey: $0) }
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
