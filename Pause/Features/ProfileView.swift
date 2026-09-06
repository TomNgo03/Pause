import SwiftUI
import SwiftData

struct ProfileView: View {
    @EnvironmentObject private var model: AppModel
    @State private var name = ""
    @State private var intention = ""
    @State private var showingDelete = false
    @Query private var sessions: [IntentionalSession]

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Circle().fill(PauseTheme.heroGradient).frame(width: 92, height: 92)
                        .overlay(Text(String((name.isEmpty ? "P" : name).prefix(1))).font(.system(size: 36, weight: .bold)))
                        .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 3))
                    Text(name.isEmpty ? "Your Pause profile" : name).font(.title2.bold())
                    Text(model.auth.user?.email ?? "Private account").font(.subheadline).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity).listRowBackground(Color.clear).padding(.vertical, 12)
            }
            Section("Account") {
                if let user = model.auth.user {
                    LabeledContent("Account email", value: user.email ?? "Private account")
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
            Section("Space journey") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(SpaceAchievement.journey(for: sessions.count)) { badge in
                            VStack(spacing: 8) {
                                Image(systemName: badge.symbol).font(.title2)
                                    .foregroundStyle(badge.unlocked ? PauseTheme.mint : .secondary)
                                    .frame(width: 58, height: 58)
                                    .background(badge.unlocked ? PauseTheme.indigo.opacity(0.22) : PauseTheme.elevated,
                                                in: Circle())
                                Text(badge.title).font(.caption.bold()).lineLimit(1)
                                Text(badge.unlocked ? "Discovered" : "\(badge.requiredSessions) trips")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }.frame(width: 92).opacity(badge.unlocked ? 1 : 0.48)
                        }
                    }.padding(.vertical, 6)
                }
                Label("Friends can see earned badge icons, never your private intentions or reflections.", systemImage: "eye.fill")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Friend code") {
                Text(model.social.profile.friendCode).font(.title.monospaced().bold()).foregroundStyle(PauseTheme.mint).textSelection(.enabled)
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
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { model.route = .settings } label: { Image(systemName: "gearshape.fill") } } }
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
