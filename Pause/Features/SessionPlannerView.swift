import SwiftUI

struct SessionPlannerView: View {
    @EnvironmentObject private var model: AppModel
    @State private var intention: IntentionCategory = .message
    @State private var duration = 10
    private let durations = [2, 5, 10, 15, 20, 30]

    var body: some View {
        Form {
            Section("What do you want to accomplish?") {
                Picker("Intention", selection: $intention) {
                    ForEach(IntentionCategory.allCases) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.inline)
            }
            Section("How much time do you need?") {
                Picker("Duration", selection: $duration) {
                    ForEach(durations, id: \.self) { Text("\($0) minutes").tag($0) }
                }
            }
            Section {
                Text("You plan to \(intention.rawValue.lowercased()) for \(duration) minutes.")
                    .font(.headline)
                Button("Begin session") {
                    let now = Date.now
                    let draft = SessionDraft(intention: intention, plannedStart: now, plannedEnd: now.addingTimeInterval(Double(duration * 60)))
                    Task { await model.start(draft) }
                }
                .buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("beginSession")
            }
        }
        .scrollContentBackground(.hidden)
        .background(PauseBackground())
        .navigationTitle("Make a plan")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { model.route = .home } } }
    }
}
