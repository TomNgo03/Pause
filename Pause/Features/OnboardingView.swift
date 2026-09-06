import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var page = 0

    private let pages = [
        Page(icon: "pause.fill", title: "A small pause can change the next hour.", body: "Choose why you are opening an app, decide what enough looks like, and move forward on purpose.", color: PauseTheme.indigo),
        Page(icon: "hand.raised.fill", title: "You stay in control.", body: "No shame, punishment, or public rankings. Plans can change and every reflection is optional.", color: PauseTheme.coral),
        Page(icon: "lock.shield.fill", title: "Private by design.", body: "Pause does not read messages, browsing content, contacts, grades, diagnoses, or location.", color: PauseTheme.mint)
    ]

    var body: some View {
        ZStack {
            PauseBackground()
            VStack(spacing: 0) {
                HStack { Spacer(); Button("Skip") { finish() }.font(.subheadline.weight(.semibold)).opacity(page == pages.count - 1 ? 0 : 1).disabled(page == pages.count - 1) }.padding()
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 28) {
                            Spacer()
                            ZStack {
                                Circle().fill(item.color.opacity(0.10)).frame(width: 210, height: 210)
                                Circle().fill(item.color.opacity(0.14)).frame(width: 150, height: 150)
                                Image(systemName: item.icon).font(.system(size: 58, weight: .bold)).foregroundStyle(item.color.gradient)
                            }
                            VStack(spacing: 14) {
                                Text(item.title).font(.system(.largeTitle, design: .rounded, weight: .bold)).multilineTextAlignment(.center).tracking(-0.7)
                                Text(item.body).font(.title3).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(4)
                            }.padding(.horizontal, 24)
                            Spacer()
                        }.tag(index)
                    }
                }.tabViewStyle(.page(indexDisplayMode: .always))
                Button(page == pages.count - 1 ? "Begin with intention" : "Continue") {
                    if page < pages.count - 1 { withAnimation(.snappy) { page += 1 } } else { finish() }
                }.buttonStyle(PrimaryButtonStyle()).padding(.horizontal, 24).padding(.bottom, 24).accessibilityIdentifier("onboardingContinue")
            }
        }
    }

    private func finish() { model.preferences.onboardingComplete = true; model.objectWillChange.send() }
    private struct Page { let icon: String; let title: String; let body: String; let color: Color }
}
