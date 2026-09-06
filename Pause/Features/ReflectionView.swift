import SwiftUI
import SwiftData

struct ReflectionView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.modelContext) private var context
    @State private var outcome: IntentionOutcome = .skipped
    @State private var control: ControlFeeling = .skipped

    var body: some View {
        Form {
            Section("Did you accomplish your intention?") {
                Picker("Outcome", selection: $outcome) {
                    ForEach(IntentionOutcome.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.inline)
            }
            Section("How did this session feel?") {
                Picker("Sense of control", selection: $control) {
                    ForEach(ControlFeeling.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.inline)
            }
            Section {
                Button("Save reflection") { save() }
                    .buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("saveReflection")
                Text("Every question is optional. A skipped answer is stored only as ‘Prefer not to answer.’")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(PauseBackground())
        .navigationTitle("A short reflection")
    }

    private func save() {
        guard let draft = model.activeSession else { model.completeReflection(); return }
        context.insert(IntentionalSession(draft: draft, outcome: outcome, control: control))
        try? context.save()
        model.completeReflection()
    }
}
