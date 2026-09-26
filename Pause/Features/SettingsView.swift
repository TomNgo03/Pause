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
            Section("Presentation mode") {
                if model.preferences.demoDataEnabled { Label("Demo data is active", systemImage: "sparkles").foregroundStyle(PauseTheme.orange); Button("Remove demo journey", role: .destructive) { removeDemoData() } }
                else { Button("Load labeled sample journey") { addDemoData() } }
                Text("Sample records are clearly labeled and never mixed into your personal profile totals.").font(.footnote).foregroundStyle(PauseTheme.muted)
            }
            Section("Focus support") {
                LabeledContent("App protection", value: model.screenTime.modeDescription)
                Button("Request Screen Time authorization") { Task { do { try await model.screenTime.requestAuthorization() } catch { model.presentError(error.localizedDescription) } } }
                Button("Enable session notifications") { Task { _ = await model.notifications.requestAuthorization() } }
                Text("App protection is experimental. Pause never claims another app is blocked unless iOS authorization is active.").font(.footnote).foregroundStyle(PauseTheme.muted)
            }
            Section("Privacy") {
                Text("Profiles, sessions, and reflections stay on this device. Pause does not collect messages, browsing content, contacts, location, grades, or diagnoses.")
                if let exportURL { ShareLink(item: exportURL) { Label("Share anonymous CSV", systemImage: "square.and.arrow.up") } } else { Button("Prepare anonymous CSV") { prepareExport() } }
            }
            Section("Start over") { Button("Show introduction again") { model.preferences.onboardingComplete = false; model.objectWillChange.send() }; Button("Delete all local data", role: .destructive) { showingDelete = true } }
        }.scrollContentBackground(.hidden).background(PauseBackground()).navigationTitle("Settings").foregroundStyle(PauseTheme.ink)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Done") { model.route = .profile } } }
        .confirmationDialog("Permanently delete all Pause data?", isPresented: $showingDelete) { Button("Delete all data", role: .destructive) { deleteAll() }; Button("Cancel", role: .cancel) {} }
    }

    private func prepareExport() { let csv = ExportService.csv(sessions: sessions.filter { !$0.isDemoData }, participantCode: model.preferences.participantCode); let url = FileManager.default.temporaryDirectory.appendingPathComponent("pause-anonymous-export.csv"); try? csv.write(to: url, atomically: true, encoding: .utf8); exportURL = url }
    private func addDemoData() { removeDemoData(); for index in 0..<8 { let start = Calendar.current.date(byAdding: .day, value: -index, to: .now)!; var draft = SessionDraft(intention: .learning, plannedStart: start, plannedEnd: start.addingTimeInterval(Double((20 + index * 3) * 60)), actualEnd: start.addingTimeInterval(Double((18 + index * 3) * 60)), task: ["Review mathematics", "Draft an essay", "Read computer science notes"][index % 3], energy: index.isMultiple(of: 3) ? .low : .steady, expectedDistraction: index.isMultiple(of: 2) ? .notifications : .thoughts, successStatement: "Finish one clear section"); draft.actualEnd = draft.plannedEnd; let item = IntentionalSession(draft: draft, outcome: index.isMultiple(of: 4) ? .partly : .yes, control: index.isMultiple(of: 3) ? .neutral : .inControl); item.focusRating = 3 + index % 3; item.mainDistraction = draft.expectedDistraction.rawValue; item.reflectionNote = "Sample reflection for presentation."; item.isDemoData = true; context.insert(item) }; try? context.save(); model.preferences.demoDataEnabled = true; model.objectWillChange.send() }
    private func removeDemoData() { sessions.filter(\.isDemoData).forEach(context.delete); try? context.save(); model.preferences.demoDataEnabled = false; model.objectWillChange.send() }
    private func deleteAll() { sessions.forEach(context.delete); try? context.save(); exportURL = nil; Task { await model.clearPrivateState() } }
}
