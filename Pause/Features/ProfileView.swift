import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var model: AppModel

    private var completedChecks: Int {
        model.care.routines.reduce(0) { $0 + $1.completedDates.count }
    }
    private var independentTries: Int {
        model.care.guides.reduce(0) { $0 + $1.practiceCount }
    }

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

    private func metric(_ value: String, _ label: String, _ symbol: String) -> some View {
        EditorialCard { VStack(alignment: .leading, spacing: 8) { Image(systemName: symbol).foregroundStyle(PauseTheme.orange); Text(value).font(.title.bold()); Text(label).font(.caption).foregroundStyle(PauseTheme.muted) } }
    }
}
