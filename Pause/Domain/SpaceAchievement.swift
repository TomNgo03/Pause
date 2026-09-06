import Foundation

struct SpaceAchievement: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let colorName: String
    let requiredSessions: Int

    var unlocked: Bool = false

    static func journey(for sessionCount: Int) -> [SpaceAchievement] {
        [
            SpaceAchievement(id: "launch", title: "First Launch", detail: "Complete 1 journey", symbol: "paperplane.fill", colorName: "sky", requiredSessions: 1),
            SpaceAchievement(id: "moon", title: "Moon Walker", detail: "Complete 3 journeys", symbol: "moon.stars.fill", colorName: "violet", requiredSessions: 3),
            SpaceAchievement(id: "planet", title: "Planet Finder", detail: "Complete 5 journeys", symbol: "globe.americas.fill", colorName: "mint", requiredSessions: 5),
            SpaceAchievement(id: "constellation", title: "Constellation", detail: "Complete 10 journeys", symbol: "sparkles", colorName: "coral", requiredSessions: 10),
            SpaceAchievement(id: "galaxy", title: "Deep Explorer", detail: "Complete 25 journeys", symbol: "hurricane", colorName: "indigo", requiredSessions: 25)
        ].map { item in
            var copy = item
            copy.unlocked = sessionCount >= item.requiredSessions
            return copy
        }
    }
}
