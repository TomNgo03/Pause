import SwiftUI

struct RoutinesView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingAdd = false

    var body: some View {
        ZStack { PauseBackground(); ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                PauseSectionHeader(title: "Your routines", subtitle: "Gentle prompts for things you choose to remember.", action: { showingAdd = true })
                ForEach(model.care.routines) { routine in
                    EditorialCard {
                        HStack(spacing: 15) {
                            PauseIcon(systemName: routine.isCompleted() ? "checkmark" : "bell.fill", color: routine.isCompleted() ? PauseTheme.forest : PauseTheme.orange)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(routine.title).font(.headline)
                                Text(routine.detail).font(.caption).foregroundStyle(PauseTheme.muted)
                                Text(routine.isCompleted() ? "Checked today" : routine.reminderDate.formatted(date: .omitted, time: .shortened)).font(.caption.bold()).foregroundStyle(routine.isCompleted() ? PauseTheme.forest : PauseTheme.orange)
                            }
                            Spacer()
                        }
                    }
                }
                EditorialCard(color: PauseTheme.sage) { Text("Pause is a memory aid, not medical advice. Always follow the care plan given by a qualified professional.").font(.footnote).foregroundStyle(PauseTheme.forest) }
            }.padding(20).padding(.bottom, 30)
        }}.toolbar(.hidden, for: .navigationBar).sheet(isPresented: $showingAdd) { AddRoutineView() }
    }
}

private struct AddRoutineView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var detail = ""
    @State private var time = Date.now

    var body: some View {
        NavigationStack {
            Form {
                Section("What would you like help remembering?") {
                    TextField("e.g. Check inhaler before leaving", text: $title)
                    TextField("A kind note to yourself", text: $detail, axis: .vertical)
                }
                Section("When") { DatePicker("Reminder", selection: $time, displayedComponents: .hourAndMinute) }
            }
            .navigationTitle("New routine")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Add") { Task { await model.care.addRoutine(title: title, detail: detail, date: time); dismiss() } }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty) }
            }
        }
    }
}

