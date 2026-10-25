import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedRoutine: CareRoutine?

    private var due: [CareRoutine] { model.care.routines.filter { $0.isEnabled && !$0.isCompleted() } }
    private var completed: Int { model.care.routines.filter { $0.isCompleted() }.count }

    var body: some View {
        ZStack {
            PauseBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if model.care.isPresentationMode { demoBanner }
                    header
                    thought
                    if let next = due.first { nextCheck(next) } else { allDone }
                    HStack(spacing: 12) {
                        summary(value: "\(completed)", label: "checked today", symbol: "checkmark")
                        summary(value: "\(model.care.guides.reduce(0) { $0 + $1.practiceCount })", label: "independent tries", symbol: "hand.raised.fill")
                    }
                    EditorialCard(color: PauseTheme.sage) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("THE IDEA BEHIND PAUSE").font(.caption.bold()).tracking(1.4).foregroundStyle(PauseTheme.forest)
                            Text("A reminder should make room for a choice—not demand obedience.").font(.title3.bold())
                            Text("Your information stays on this device. Pause does not diagnose, judge, or share health data.").font(.footnote).foregroundStyle(PauseTheme.muted)
                        }
                    }
                }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 34)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedRoutine) { routine in ChoiceSheet(routine: routine) }
    }

    private var demoBanner: some View {
        HStack(spacing: 9) {
            Image(systemName: "play.rectangle.fill")
            Text("PRESENTATION DATA").font(.caption.bold()).tracking(1.2)
            Spacer()
            Text("Local & labeled").font(.caption)
        }.foregroundStyle(PauseTheme.forest).padding(13).background(PauseTheme.sage, in: Capsule())
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())).font(.caption.bold()).tracking(1).foregroundStyle(PauseTheme.muted)
                Text("Good \(dayPart),\n\(model.preferences.displayName).").font(.system(size: 38, weight: .bold, design: .serif)).tracking(-1)
            }
            Spacer()
            Button { model.route = .profile } label: {
                Text(String(model.preferences.displayName.prefix(1)).uppercased()).font(.headline).foregroundStyle(.white).frame(width: 46, height: 46).background(PauseTheme.forest, in: Circle())
            }
        }
    }

    private var thought: some View {
        EditorialCard(color: PauseTheme.sage) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "pause.fill").foregroundStyle(PauseTheme.orange)
                Text("Preparation does not remove uncertainty. It gives your attention back.").font(.system(size: 25, weight: .semibold, design: .serif)).lineSpacing(3)
            }
        }
    }

    private func nextCheck(_ routine: CareRoutine) -> some View {
        EditorialCard(color: PauseTheme.forest) {
            VStack(alignment: .leading, spacing: 16) {
                Text("READY FOR A QUICK CHECK?").font(.caption.bold()).tracking(1.4).foregroundStyle(PauseTheme.sage)
                Text(routine.title).font(.system(size: 29, weight: .bold, design: .serif)).foregroundStyle(.white)
                Text(routine.detail).foregroundStyle(.white.opacity(0.72))
                Button { selectedRoutine = routine } label: {
                    Text("Choose what to do").font(.headline).foregroundStyle(PauseTheme.ink).frame(maxWidth: .infinity).padding(.vertical, 14).background(PauseTheme.sage, in: Capsule())
                }.buttonStyle(.plain)
            }
        }
    }

    private var allDone: some View {
        EditorialCard(color: PauseTheme.forest) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "checkmark.circle.fill").font(.title).foregroundStyle(PauseTheme.sage)
                Text("You made room for today.").font(.system(size: 28, weight: .bold, design: .serif)).foregroundStyle(.white)
                Text("No streak to protect and no score to chase. Come back when a check would help.").foregroundStyle(.white.opacity(0.72))
            }
        }
    }

    private func summary(value: String, label: String, symbol: String) -> some View {
        EditorialCard { VStack(alignment: .leading, spacing: 8) { Image(systemName: symbol).foregroundStyle(PauseTheme.orange); Text(value).font(.title.bold()); Text(label).font(.caption).foregroundStyle(PauseTheme.muted) } }
    }

    private var dayPart: String { switch Calendar.current.component(.hour, from: .now) { case 5..<12: "morning"; case 12..<18: "afternoon"; default: "evening" } }
}

private struct ChoiceSheet: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let routine: CareRoutine
    @State private var completed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Capsule().fill(PauseTheme.ink.opacity(0.15)).frame(width: 40, height: 5).frame(maxWidth: .infinity)
            if completed {
                Text("One question—not a score.").font(.system(size: 32, weight: .bold, design: .serif))
                Text("Did this check help you feel prepared?").font(.title3.weight(.semibold))
                Text("A completed reminder only records a tap. This answer helps Pause understand whether the design supported you.").foregroundStyle(PauseTheme.muted)
                ForEach(RoutineResponse.Feeling.allCases, id: \.self) { feeling in
                    if feeling == .morePrepared {
                        Button(feeling.rawValue) { model.care.recordFeeling(feeling, for: routine); dismiss() }.buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button(feeling.rawValue) { model.care.recordFeeling(feeling, for: routine); dismiss() }.buttonStyle(SoftButtonStyle())
                    }
                }
                Button("Skip reflection") { dismiss() }.foregroundStyle(PauseTheme.muted).frame(maxWidth: .infinity)
            } else {
                Text("A pause is a choice.").font(.system(size: 32, weight: .bold, design: .serif))
                Text(routine.title).font(.title3.weight(.semibold))
                Text("Choose what fits this moment. ‘Later’ is not failure—it is a plan to return.").foregroundStyle(PauseTheme.muted)
                Button { model.care.complete(routine); withAnimation { completed = true } } label: { Label("I checked", systemImage: "checkmark.circle.fill") }.buttonStyle(PrimaryButtonStyle())
                Button { Task { await model.care.postpone(routine); dismiss() } } label: { Label("Remind me in 10 minutes", systemImage: "clock.arrow.circlepath") }.buttonStyle(SoftButtonStyle())
                Button("Not needed today") { model.care.complete(routine); dismiss() }.foregroundStyle(PauseTheme.muted).frame(maxWidth: .infinity)
            }
            Spacer()
        }.padding(24).presentationDetents([completed ? .large : .medium]).background(PauseTheme.cream)
    }
}
