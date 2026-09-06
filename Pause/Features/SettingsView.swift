import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.modelContext) private var context
    @Query private var sessions: [IntentionalSession]
    @State private var showingDelete = false
    @State private var exportURL: URL?

    var body: some View {
        Form {
            Section("Mode") {
                LabeledContent("Current mode", value: model.screenTime.modeDescription)
                Button("Request Screen Time authorization") {
                    Task { do { try await model.screenTime.requestAuthorization() } catch { model.presentError(error.localizedDescription) } }
                }
                Button("Enable notifications") { Task { _ = await model.notifications.requestAuthorization() } }
            }
            Section("Privacy") {
                Text("Session and reflection records are stored locally. Pause does not collect messages, browsing content, contacts, location, grades, or diagnoses.")
                LabeledContent("Anonymous participant code", value: model.preferences.participantCode)
                if let exportURL { ShareLink(item: exportURL) { Label("Export anonymous CSV", systemImage: "square.and.arrow.up") } }
                else { Button("Prepare anonymous CSV") { prepareExport() } }
            }
            #if DEBUG
            Section("Demo") {
                Button("Add seven days of sample data") { addDemoData() }
                Text("Available only in debug builds for screenshots and demonstrations.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            #endif
            Section {
                Button("Delete all local data", role: .destructive) { showingDelete = true }
            }
        }
        .scrollContentBackground(.hidden)
        .background(PauseBackground())
        .navigationTitle("Settings")
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Home") { model.route = .home } } }
        .confirmationDialog("Permanently delete all Pause data?", isPresented: $showingDelete) {
            Button("Delete all data", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func prepareExport() {
        let csv = ExportService.csv(sessions: sessions, participantCode: model.preferences.participantCode)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pause-anonymous-export.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        exportURL = url
    }

    private func deleteAll() {
        sessions.forEach(context.delete)
        try? context.save()
        exportURL = nil
        Task { await model.clearPrivateState() }
    }

    #if DEBUG
    private func addDemoData() {
        for index in 0..<7 {
            let start = Calendar.current.date(byAdding: .day, value: -index, to: .now)!
            var draft = SessionDraft(
                intention: IntentionCategory.allCases[index % IntentionCategory.allCases.count],
                plannedStart: start,
                plannedEnd: start.addingTimeInterval(Double((5 + index) * 60)),
                actualEnd: start.addingTimeInterval(Double((5 + index) * 60)),
                extensionMinutes: index.isMultiple(of: 3) ? 5 : 0
            )
            draft.actualEnd = draft.plannedEnd
            context.insert(IntentionalSession(
                draft: draft,
                outcome: index.isMultiple(of: 4) ? .partly : .yes,
                control: index.isMultiple(of: 3) ? .neutral : .inControl
            ))
        }
        try? context.save()
    }
    #endif
}
