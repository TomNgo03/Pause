import Foundation

@MainActor
final class SocialStore: ObservableObject {
    @Published var profile: PauseProfile
    @Published var friends: [PauseFriend]
    @Published var circles: [AccountabilityCircle]
    @Published var rooms: [FocusRoom]
    @Published var challenges: [CooperativeChallenge]
    @Published var encouragements: [Encouragement]

    private let defaults = UserDefaults.standard
    private let key = "pause.social.demo.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key), let state = try? JSONDecoder().decode(State.self, from: data) {
            profile = state.profile; friends = state.friends; circles = state.circles; rooms = state.rooms
            challenges = state.challenges; encouragements = state.encouragements
        } else {
            let me = PauseProfile(id: UUID(), displayName: "Huy", friendCode: Self.code(), dailyIntention: "Finish one meaningful study task")
            let minh = PauseFriend(id: UUID(), displayName: "Minh", status: "Focusing for 18 more minutes", badgeSymbols: ["moon.stars.fill", "paperplane.fill"])
            let lan = PauseFriend(id: UUID(), displayName: "Lan", status: "Available", badgeSymbols: ["globe.americas.fill"])
            profile = me; friends = [minh, lan]
            circles = [AccountabilityCircle(id: UUID(), name: "Study Circle", memberIDs: [me.id, minh.id, lan.id], weeklyGoal: 20, weeklyProgress: 12)]
            rooms = [FocusRoom(id: UUID(), title: "Physics review", durationMinutes: 25, startedAt: nil, participantIDs: [minh.id], state: .waiting)]
            challenges = [CooperativeChallenge(id: UUID(), title: "20 intentional sessions together", target: 20, progress: 12, endsAt: Calendar.current.date(byAdding: .day, value: 5, to: .now)!)]
            encouragements = [Encouragement(id: UUID(), senderName: "Lan", kind: .support, createdAt: .now)]
        }
    }

    func updateProfile(name: String, intention: String?) {
        profile.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.dailyIntention = intention?.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func addFriend(code: String) -> Bool {
        let normalized = code.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count >= 4, !friends.contains(where: { $0.displayName == "New friend" }) else { return false }
        friends.append(PauseFriend(id: UUID(), displayName: "New friend", status: "Invitation accepted", badgeSymbols: [])); save(); return true
    }

    func createCircle(name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        circles.append(AccountabilityCircle(id: UUID(), name: clean, memberIDs: [profile.id], weeklyGoal: 10, weeklyProgress: 0)); save()
    }

    func createRoom(title: String, minutes: Int) {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        rooms.insert(FocusRoom(id: UUID(), title: clean, durationMinutes: minutes, startedAt: nil, participantIDs: [profile.id], state: .waiting), at: 0); save()
    }

    func join(_ room: FocusRoom) {
        guard let index = rooms.firstIndex(where: { $0.id == room.id }) else { return }
        if !rooms[index].participantIDs.contains(profile.id) { rooms[index].participantIDs.append(profile.id) }
        rooms[index].state = .focusing; rooms[index].startedAt = .now; save()
    }

    func send(_ kind: Encouragement.Kind, to friend: PauseFriend) {
        encouragements.insert(Encouragement(id: UUID(), senderName: profile.displayName, kind: kind, createdAt: .now), at: 0); save()
    }

    func deleteAccountData() {
        defaults.removeObject(forKey: key)
        friends = []; circles = []; rooms = []; challenges = []; encouragements = []
        profile = PauseProfile(id: UUID(), displayName: "Student", friendCode: Self.code(), dailyIntention: nil)
    }

    private func save() {
        let state = State(profile: profile, friends: friends, circles: circles, rooms: rooms, challenges: challenges, encouragements: encouragements)
        defaults.set(try? JSONEncoder().encode(state), forKey: key)
    }

    private static func code() -> String { String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8)).uppercased() }
    private struct State: Codable { var profile: PauseProfile; var friends: [PauseFriend]; var circles: [AccountabilityCircle]; var rooms: [FocusRoom]; var challenges: [CooperativeChallenge]; var encouragements: [Encouragement] }
}
