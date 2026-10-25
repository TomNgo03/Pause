import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var page = 0
    @State private var name = ""
    @State private var goal = "Health routine"
    @State private var minutes = 25
    @State private var attention = "Remember a routine"
    private let goals = ["Health routine", "Daily preparation", "Independent living", "Other"]
    private let attentionOptions = ["Remember a routine", "Feel prepared", "Learn a task independently"]

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
            Text("Make room\nfor your choice.").font(.system(size: 43, weight: .bold, design: .serif)).tracking(-1.2)
            Text("Pause offers gentle reminders and personal guides—so technology can support you without taking control.").font(.title3).foregroundStyle(PauseTheme.muted).lineSpacing(5)
            Spacer()
        }.padding(.horizontal, 28)
    }

    private var setup: some View {
        ScrollView { VStack(alignment: .leading, spacing: 24) {
            Text("Make it yours.").font(.system(size: 40, weight: .bold, design: .serif))
            TextField("First name or nickname", text: $name).textFieldStyle(.plain).padding(18).background(PauseTheme.paper, in: RoundedRectangle(cornerRadius: 18))
            choiceSection("Where could Pause help?", values: goals, selection: $goal)
        }.padding(28) }
    }

    private var checkIn: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("What would create\nmore room today?").font(.system(size: 40, weight: .bold, design: .serif))
            Text("There is no score and no wrong answer. You stay in control of every prompt.").foregroundStyle(PauseTheme.muted)
            choiceSection("I want to…", values: attentionOptions, selection: $attention)
            Spacer()
            EditorialCard(color: PauseTheme.sage) { Label("Your routines stay on this device. Pause is a memory aid, not medical advice.", systemImage: "lock.fill").font(.footnote).foregroundStyle(PauseTheme.forest) }
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
