import SwiftUI

struct SessionPlannerView: View {
    @EnvironmentObject private var model: AppModel
    @State private var task = ""
    @State private var category: IntentionCategory = .learning
    @State private var duration = 25
    @State private var customDuration = 25.0
    @State private var energy: EnergyLevel = .steady
    @State private var distraction: SessionDistraction = .none
    @State private var success = ""
    private let presets = [15, 25, 40, 60]

    var body: some View {
        ZStack { PauseBackground(); ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Set one clear\nintention.").font(.system(size: 39, weight: .bold, design: .serif))
                field("What will you accomplish?") { TextField("e.g. Draft the introduction", text: $task, axis: .vertical).lineLimit(2...4) }
                field("Category") { Picker("Category", selection: $category) { ForEach(IntentionCategory.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu) }
                field("How long?") {
                    HStack { ForEach(presets, id: \.self) { value in Button("\(value)m") { duration = value; customDuration = Double(value) }.buttonStyle(PlannerChip(selected: duration == value)) } }
                    Slider(value: $customDuration, in: 5...90, step: 5) { Text("Custom duration") }.onChange(of: customDuration) { _, value in duration = Int(value) }
                    Text("\(duration) minutes").font(.caption.bold()).foregroundStyle(PauseTheme.muted)
                }
                field("Your energy") { HStack { ForEach(EnergyLevel.allCases) { value in Button(value.rawValue) { energy = value }.buttonStyle(PlannerChip(selected: energy == value)) } } }
                field("What might pull you away?") { Picker("Likely distraction", selection: $distraction) { ForEach(SessionDistraction.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu) }
                field("Success means… (optional)") { TextField("A small, visible outcome", text: $success, axis: .vertical) }
                if !taskTrimmed.isEmpty { EditorialCard(color: PauseTheme.sage) { VStack(alignment: .leading, spacing: 8) { Text("YOUR COMMITMENT").font(.caption.bold()).tracking(1.4); Text("For the next \(duration) minutes, I will \(taskTrimmed.lowercased()).").font(.title3.weight(.semibold)) } } }
                Button("Begin journey") { begin() }.buttonStyle(PrimaryButtonStyle()).disabled(taskTrimmed.isEmpty)
            }.padding(22).frame(maxWidth: 650)
        } }.foregroundStyle(PauseTheme.ink).navigationTitle("New session").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { model.route = .home } } }
    }

    private var taskTrimmed: String { task.trimmingCharacters(in: .whitespacesAndNewlines) }
    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View { VStack(alignment: .leading, spacing: 10) { Text(label).font(.headline); content().padding(16).frame(maxWidth: .infinity, alignment: .leading).background(PauseTheme.paper, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(PauseTheme.ink.opacity(0.1))) } }
    private func begin() { let now = Date.now; let draft = SessionDraft(intention: category, plannedStart: now, plannedEnd: now.addingTimeInterval(Double(duration * 60)), task: taskTrimmed, energy: energy, expectedDistraction: distraction, successStatement: success); Task { await model.start(draft) } }
}

private struct PlannerChip: ButtonStyle { let selected: Bool
    func makeBody(configuration: Configuration) -> some View { configuration.label.font(.caption.weight(.semibold)).padding(.horizontal, 12).frame(minHeight: 42).foregroundStyle(selected ? Color.white : PauseTheme.ink).background(selected ? PauseTheme.orange : PauseTheme.cream, in: Capsule()) }
}
