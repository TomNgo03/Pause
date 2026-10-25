import SwiftUI

struct RoutinesView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingAdd = false
    @State private var selected: CareRoutine?

    var body: some View {
        ZStack { PauseBackground(); ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                PauseSectionHeader(title: "Your routines", subtitle: "Gentle prompts for things you choose to remember.", action: { showingAdd = true })
                ForEach(model.care.routines) { routine in
                    Button { selected = routine } label: { EditorialCard {
                            HStack(spacing: 15) {
                                PauseIcon(systemName: routine.isCompleted() ? "checkmark" : "bell.fill", color: routine.isCompleted() ? PauseTheme.forest : PauseTheme.orange)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(routine.title).font(.headline)
                                    Text(routine.detail).font(.caption).foregroundStyle(PauseTheme.muted)
                                    Text(routine.isCompleted() ? "Checked today" : routine.reminderDate.formatted(date: .omitted, time: .shortened)).font(.caption.bold()).foregroundStyle(routine.isCompleted() ? PauseTheme.forest : PauseTheme.orange)
                                }
                                Spacer(); Image(systemName: "chevron.right").foregroundStyle(PauseTheme.muted)
                            }
                        }
                    }.buttonStyle(.plain)
                }
                EditorialCard(color: PauseTheme.sage) { Text("Pause is a memory aid, not medical advice. Always follow the care plan given by a qualified professional.").font(.footnote).foregroundStyle(PauseTheme.forest) }
            }.padding(20).padding(.bottom, 30)
        }}.toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAdd) { AddRoutineView() }
            .sheet(item: $selected) { RoutineDetailView(routine: $0) }
    }
}

private struct RoutineDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let routine: CareRoutine
    private var calendar: Calendar { .current }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack { Text("ROUTINE").font(.caption.bold()).tracking(1.4).foregroundStyle(PauseTheme.orange); Spacer(); Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 38, height: 38).background(PauseTheme.sage, in: Circle()) } }
                Text(routine.title).font(.system(size: 34, weight: .bold, design: .serif))
                Text(routine.detail).foregroundStyle(PauseTheme.muted)
                EditorialCard(color: PauseTheme.forest) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("THE PROMPT").font(.caption.bold()).tracking(1.3).foregroundStyle(PauseTheme.sage)
                        Text("“Ready for a quick check?”").font(.title2.bold()).foregroundStyle(.white)
                        Text("It replaces ‘Don’t forget!’ because support should invite action without scolding.").foregroundStyle(.white.opacity(0.72))
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    PauseSectionHeader(title: "Last seven days", subtitle: "No streaks. Gaps are information, not failure.")
                    HStack(spacing: 8) {
                        ForEach((0..<7).reversed(), id: \.self) { offset in
                            let date = calendar.date(byAdding: .day, value: -offset, to: .now) ?? .now
                            let checked = routine.completedDates.contains { calendar.isDate($0, inSameDayAs: date) }
                            VStack(spacing: 7) {
                                Text(date.formatted(.dateTime.weekday(.narrow))).font(.caption2.bold()).foregroundStyle(PauseTheme.muted)
                                Circle().fill(checked ? PauseTheme.orange : PauseTheme.ink.opacity(0.08)).frame(width: 34, height: 34).overlay(Image(systemName: checked ? "checkmark" : "minus").font(.caption.bold()).foregroundStyle(checked ? .white : PauseTheme.muted))
                            }.frame(maxWidth: .infinity)
                        }
                    }
                }
                EditorialCard(color: PauseTheme.sage) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What Pause learns").font(.headline)
                        Text(routine.responses.isEmpty ? "A check records completion. A reflection reveals whether the reminder helped someone feel more capable." : "\(routine.responses.filter { $0.feeling == .morePrepared }.count) of \(routine.responses.count) reflections said this routine felt more helpful.").font(.subheadline).foregroundStyle(PauseTheme.muted)
                    }
                }
            }.padding(22)
        }.background(PauseTheme.cream).presentationDetents([.large])
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

