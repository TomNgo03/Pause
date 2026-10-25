import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var model: AppModel

    private var completedChecks: Int {
        model.care.routines.reduce(0) { $0 + $1.completedDates.count }
    }
    private var independentTries: Int {
        model.care.guides.reduce(0) { $0 + $1.practiceCount }
    }
    private var responses: [RoutineResponse] { model.care.routines.flatMap(\.responses) }
    private var preparedCount: Int { responses.filter { $0.feeling == .morePrepared }.count }

    var body: some View {
        ZStack { PauseBackground(); ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("YOU").font(.caption.bold()).tracking(1.5).foregroundStyle(PauseTheme.orange)
                    Spacer()
                    Button { model.route = .settings } label: { Image(systemName: "gearshape.fill").frame(width: 44, height: 44).background(PauseTheme.sage, in: Circle()) }.accessibilityLabel("Settings")
                }
                EditorialCard(color: PauseTheme.forest) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(String(model.preferences.displayName.prefix(1)).uppercased()).font(.system(size: 32, weight: .bold, design: .serif)).foregroundStyle(PauseTheme.forest).frame(width: 72, height: 72).background(PauseTheme.sage, in: Circle())
                        Text(model.preferences.displayName).font(.system(size: 32, weight: .bold, design: .serif)).foregroundStyle(.white)
                        Text("Technology should support my choices, not replace them.").foregroundStyle(.white.opacity(0.76))
                    }
                }
                PauseSectionHeader(title: "Growing independence", subtitle: "Private evidence of action—not a competitive score.")
                HStack(spacing: 12) {
                    metric("\(completedChecks)", "routine checks", "checkmark.circle.fill")
                    metric("\(independentTries)", "independent tries", "hand.raised.fill")
                }
                EditorialCard(color: PauseTheme.forest) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("THE DIFFERENCE THAT MATTERS").font(.caption.bold()).tracking(1.3).foregroundStyle(PauseTheme.sage)
                        if responses.isEmpty {
                            Text("Completion is not the same as capability.").font(.title2.bold()).foregroundStyle(.white)
                            Text("After a routine check, Pause asks whether the prompt actually helped. That reflection—not the tap—is the meaningful signal.").foregroundStyle(.white.opacity(0.72))
                        } else {
                            Text("\(preparedCount) of \(responses.count) checks felt helpful.").font(.title2.bold()).foregroundStyle(.white)
                            Text(insight).foregroundStyle(.white.opacity(0.72))
                        }
                    }
                }
                EditorialCard(color: PauseTheme.sage) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("What Pause measures", systemImage: "heart.text.square.fill").font(.headline)
                        Text("A tap can show that a reminder was closed. Independence is different: it appears when you can make the next choice yourself. Pause keeps both ideas separate.").font(.subheadline).foregroundStyle(PauseTheme.muted)
                    }
                }
                EditorialCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Privacy by design").font(.headline)
                        Label("No account required", systemImage: "person.crop.circle.badge.xmark")
                        Label("Routines stored on this device", systemImage: "iphone")
                        Label("No diagnosis or health claims", systemImage: "checkmark.shield")
                    }.font(.subheadline)
                }
            }.padding(20).padding(.bottom, 30)
        }}.foregroundStyle(PauseTheme.ink).toolbar(.hidden, for: .navigationBar)
    }

    private var insight: String {
        guard responses.count >= 2 else { return "Pause is beginning to learn whether prompts create confidence, not merely compliance." }
        let recent = responses.suffix(2).filter { $0.feeling == .morePrepared }.count
        return recent == 2 ? "Your two most recent reflections say ‘More prepared’—a stronger outcome than simply dismissing a notification." : "The pattern is mixed, so Pause avoids claiming the reminder solved the problem."
    }

    private func metric(_ value: String, _ label: String, _ symbol: String) -> some View {
        EditorialCard { VStack(alignment: .leading, spacing: 8) { Image(systemName: symbol).foregroundStyle(PauseTheme.orange); Text(value).font(.title.bold()); Text(label).font(.caption).foregroundStyle(PauseTheme.muted) } }
    }
}
