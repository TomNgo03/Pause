import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var model: AppModel
    @State private var name = ""
    @State private var intention = ""
    @State private var showingDelete = false

    var body: some View {
        Form {
            Section("Account") {
                if let user = model.auth.user {
                    LabeledContent("Signed in", value: user.email ?? "Private account")
                    Button("Log out", role: .destructive) {
                        Task { await model.auth.signOut() }
                    }
                }
            }
            Section("Private profile") {
                TextField("Display name", text: $name)
                TextField("Optional daily intention", text: $intention, axis: .vertical)
                Button("Save profile") { model.social.updateProfile(name: name, intention: intention.isEmpty ? nil : intention) }
            }
            Section("Friend code") {
                Text(model.social.profile.friendCode).font(.title2.monospaced().bold()).textSelection(.enabled)
                Text("Share this code only with people you know. Pause has no public people search.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Safety") {
                Label("Private profile", systemImage: "lock.fill")
                Label("Preset encouragement only", systemImage: "message.fill")
                Label("No followers or public ranking", systemImage: "person.2.slash")
            }
            Section { Button("Delete social account data", role: .destructive) { showingDelete = true } }
        }
        .scrollContentBackground(.hidden)
        .background(PauseBackground())
        .navigationTitle("Profile")
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Back") { model.route = .social } } }
        .onAppear { name = model.social.profile.displayName; intention = model.social.profile.dailyIntention ?? "" }
        .confirmationDialog("Delete profile, friends, circles, rooms, and reactions?", isPresented: $showingDelete) {
            Button("Delete social data", role: .destructive) {
                Task {
                    do {
                        try await model.auth.deleteRemoteAccount()
                        model.social.deleteAccountData(); model.route = .home
                    } catch { model.presentError(error.localizedDescription) }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

}
