import SwiftUI

struct GuidesView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selected: PersonalGuide?
    @State private var showingAdd = false

    var body: some View {
        ZStack { PauseBackground(); ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                PauseSectionHeader(title: "Try it yourself", subtitle: "Short guides designed to become less necessary over time.", action: { showingAdd = true })
                EditorialCard(color: PauseTheme.forest) { VStack(alignment: .leading, spacing: 10) { Text("GUIDANCE, NOT CONTROL").font(.caption.bold()).tracking(1.4).foregroundStyle(PauseTheme.sage); Text("The goal is not to follow instructions forever. It is to feel able to act without them.").font(.title3.bold()).foregroundStyle(.white) } }
                ForEach(model.care.guides) { guide in
                    Button { selected = guide } label: {
                        EditorialCard { HStack { VStack(alignment: .leading, spacing: 6) { Text(guide.title).font(.headline); Text(guide.purpose).font(.caption).foregroundStyle(PauseTheme.muted); Text(level(for: guide)).font(.caption.bold()).foregroundStyle(PauseTheme.forest) }; Spacer(); Image(systemName: "arrow.up.right").foregroundStyle(PauseTheme.orange) } }
                    }.buttonStyle(.plain)
                }
            }.padding(20).padding(.bottom, 30)
        }}.toolbar(.hidden, for: .navigationBar).sheet(item: $selected) { GuidePracticeView(guide: $0) }.sheet(isPresented: $showingAdd) { AddGuideView() }
    }

    private func level(for guide: PersonalGuide) -> String { guide.practiceCount >= 4 ? "Ready for independent mode" : guide.practiceCount >= 2 ? "Hint mode · \(guide.practiceCount) practices" : "Step-by-step · \(guide.practiceCount) practices" }
}

private struct GuidePracticeView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let guide: PersonalGuide
    @State private var step = 0
    @State private var showHint = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(guide.practiceCount >= 4 ? "INDEPENDENT MODE" : guide.practiceCount >= 2 ? "HINT MODE" : "STEP \(min(step + 1, guide.steps.count)) OF \(guide.steps.count)").font(.caption.bold()).tracking(1.4).foregroundStyle(PauseTheme.orange)
            Text(guide.title).font(.system(size: 32, weight: .bold, design: .serif))
            if guide.practiceCount >= 4 && !showHint {
                Text("Try the task in your own way. The guide is here only if you decide you need it.").font(.title3).foregroundStyle(PauseTheme.muted).frame(maxHeight: .infinity, alignment: .center)
                Button("I did it without help") { model.care.practiced(guide, independently: true); dismiss() }.buttonStyle(PrimaryButtonStyle())
                Button("Show me one hint") { showHint = true }.buttonStyle(SoftButtonStyle())
            } else if guide.practiceCount >= 2 && !showHint {
                Text("What do you think the first step is?").font(.title2.weight(.semibold)).frame(maxHeight: .infinity, alignment: .center)
                Button("Reveal one hint") { showHint = true }.buttonStyle(SoftButtonStyle())
            } else if step < guide.steps.count {
                Text(guide.steps[step]).font(.title2.weight(.semibold)).frame(maxHeight: .infinity, alignment: .center)
                Button(step == guide.steps.count - 1 ? "I did it" : "Next step") { if step < guide.steps.count - 1 { withAnimation { step += 1 } } else { model.care.practiced(guide, independently: false); dismiss() } }.buttonStyle(PrimaryButtonStyle())
            }
            Button("Try once without the guide") { model.care.practiced(guide, independently: true); dismiss() }.buttonStyle(SoftButtonStyle())
        }.padding(26).presentationDetents([.large]).background(PauseTheme.cream)
    }
}

private struct AddGuideView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var purpose = ""
    @State private var steps = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("What does the person want to do?") { TextField("e.g. Join a video call", text: $title); TextField("Why this matters", text: $purpose, axis: .vertical) }
                Section("Short, clear steps") { TextField("One step per line", text: $steps, axis: .vertical).lineLimit(5...10); Text("Write around the learner’s goal, not around a lesson plan.").font(.footnote).foregroundStyle(PauseTheme.muted) }
                Section("Accessibility") { Label("Large text and VoiceOver supported", systemImage: "accessibility"); Label("One step appears at a time", systemImage: "rectangle.stack") }
            }.navigationTitle("New personal guide").toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Create") { model.care.addGuide(title: title, purpose: purpose, steps: steps.components(separatedBy: .newlines)); dismiss() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || steps.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
        }
    }
}
