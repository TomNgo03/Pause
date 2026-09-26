import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var page = 0
    @State private var name = ""
    @State private var goal = "Study"
    @State private var minutes = 25
    @State private var attention = "Clear"
    private let goals = ["Study", "Reading", "Creative work", "Wellbeing", "Other"]
    private let attentionOptions = ["Clear", "Restless", "Tired", "Overwhelmed"]

    var body: some View {
        ZStack {
            PauseBackground()
            VStack(spacing: 0) {
                HStack { Text("PAUSE").font(.caption.bold()).tracking(2); Spacer(); Text("0\(page + 1) / 03").font(.caption.monospacedDigit()) }
                    .foregroundStyle(PauseTheme.muted).padding(24)
                Group {
                    if page == 0 { welcome }
                    else if page == 1 { setup }
                    else { checkIn }
                }.frame(maxWidth: 600)
                Spacer()
                Button(page == 2 ? "Enter Pause" : "Continue") { advance() }
                    .buttonStyle(PrimaryButtonStyle()).disabled(page == 1 && name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(24)
            }
        }.foregroundStyle(PauseTheme.ink)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer()
            ZStack { Circle().fill(PauseTheme.sage).frame(width: 150, height: 150); Image(systemName: "pause.fill").font(.system(size: 54, weight: .bold)).foregroundStyle(PauseTheme.forest) }
            Text("Use your attention\nwith intention.").font(.system(size: 43, weight: .bold, design: .serif)).tracking(-1.2)
            Text("Pause helps you choose one meaningful next step, focus without pressure, and learn from what happened.").font(.title3).foregroundStyle(PauseTheme.muted).lineSpacing(5)
            Spacer()
        }.padding(.horizontal, 28)
    }

    private var setup: some View {
        ScrollView { VStack(alignment: .leading, spacing: 24) {
            Text("Make it yours.").font(.system(size: 40, weight: .bold, design: .serif))
            TextField("First name or nickname", text: $name).textFieldStyle(.plain).padding(18).background(PauseTheme.paper, in: RoundedRectangle(cornerRadius: 18))
            choiceSection("What matters most?", values: goals, selection: $goal)
            VStack(alignment: .leading, spacing: 12) {
                Text("Your usual focus time").font(.headline)
                HStack { ForEach([15, 25, 40, 60], id: \.self) { value in
                    Button("\(value)m") { minutes = value }.buttonStyle(ChoiceButtonStyle(selected: minutes == value))
                } }
            }
        }.padding(28) }
    }

    private var checkIn: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Where are you\nstarting today?").font(.system(size: 40, weight: .bold, design: .serif))
            Text("There is no wrong answer. Pause adapts the first suggestion to you.").foregroundStyle(PauseTheme.muted)
            choiceSection("My attention feels…", values: attentionOptions, selection: $attention)
            Spacer()
            EditorialCard(color: PauseTheme.sage) { Label("Your data stays on this device unless you explicitly request an online Coach enhancement.", systemImage: "lock.fill").font(.footnote).foregroundStyle(PauseTheme.forest) }
        }.padding(28)
    }

    private func choiceSection(_ title: String, values: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            FlowLayout(spacing: 9) { ForEach(values, id: \.self) { value in Button(value) { selection.wrappedValue = value }.buttonStyle(ChoiceButtonStyle(selected: selection.wrappedValue == value)) } }
        }
    }

    private func advance() {
        if page < 2 { withAnimation(.easeInOut(duration: 0.25)) { page += 1 } }
        else {
            model.preferences.displayName = name.trimmingCharacters(in: .whitespaces)
            model.preferences.primaryGoal = goal; model.preferences.preferredMinutes = minutes; model.preferences.initialAttention = attention
            model.preferences.onboardingComplete = true; model.objectWillChange.send()
        }
    }
}

private struct ChoiceButtonStyle: ButtonStyle {
    let selected: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold)).padding(.horizontal, 16).frame(minHeight: 46)
            .foregroundStyle(selected ? Color.white : PauseTheme.ink).background(selected ? PauseTheme.forest : PauseTheme.paper, in: Capsule())
            .overlay(Capsule().stroke(PauseTheme.ink.opacity(0.1)))
    }
}

struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content
    var body: some View { ViewThatFits { HStack(spacing: spacing) { content }; VStack(alignment: .leading, spacing: spacing) { content } } }
}
