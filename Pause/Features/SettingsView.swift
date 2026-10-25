import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.modelContext) private var context
    @Query private var sessions: [IntentionalSession]
    @State private var showingDelete = false

    var body: some View {
        Form {
            Section("Demo studio") {
                if model.care.isPresentationMode {
                    Button("Refresh illustrative journey") { model.care.loadPresentationDemo() }
                    Button("Restore personal starter data", role: .destructive) { model.care.reset() }
                } else {
                    Button("Load illustrative journey") { model.care.loadPresentationDemo() }
                }
                Button("Play self-running product story") { model.route = .demoStory }
                Text("Illustrative information stays local and never represents real users or clinical outcomes.").font(.footnote).foregroundStyle(PauseTheme.muted)
            }
            Section("Reminders") {
                Button("Enable gentle notifications") { Task { _ = await model.notifications.requestAuthorization() } }
                Text("Notifications use supportive language and always leave the decision with you.").font(.footnote).foregroundStyle(PauseTheme.muted)
            }
            Section("Privacy") {
                Text("Your name, routines, checks, and personal guides stay on this device. Pause does not collect contacts, location, diagnoses, or medical records.")
                Label("Pause is a memory aid, not medical advice.", systemImage: "checkmark.shield")
            }
            Section("Start over") { Button("Show introduction again") { model.preferences.onboardingComplete = false; model.objectWillChange.send() }; Button("Delete all local data", role: .destructive) { showingDelete = true } }
        }.scrollContentBackground(.hidden).background(PauseBackground()).navigationTitle("Settings").foregroundStyle(PauseTheme.ink)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Done") { model.route = .profile } } }
        .confirmationDialog("Permanently delete all Pause data?", isPresented: $showingDelete) { Button("Delete all data", role: .destructive) { deleteAll() }; Button("Cancel", role: .cancel) {} }
    }

    private func deleteAll() { sessions.forEach(context.delete); try? context.save(); model.care.reset(); Task { await model.clearPrivateState() } }
}
