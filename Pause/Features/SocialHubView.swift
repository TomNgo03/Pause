import SwiftUI

struct SocialHubView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingFriend = false
    @State private var showingCircle = false
    @State private var showingRoom = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                header
                friendStrip
                dailyIntention
                circles
                rooms
                challenges
                friends
                encouragements
            }.padding()
        }
        .background(PauseTheme.background)
        .navigationTitle("Together").navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { Button { model.route = .profile } label: { Image(systemName: "person.crop.circle") } }
        }
        .sheet(isPresented: $showingFriend) { AddFriendSheet(store: model.social) }
        .sheet(isPresented: $showingCircle) { CreateCircleSheet(store: model.social) }
        .sheet(isPresented: $showingRoom) { CreateRoomSheet(store: model.social) }
    }

    private var store: SocialStore { model.social }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) { Text("Focus with friends").font(.title2.bold()); Text("You can start alone and invite people later").font(.subheadline).foregroundStyle(.secondary) }
            Spacer(); Button { showingFriend = true } label: { Image(systemName: "person.badge.plus") }.buttonStyle(.bordered)
        }
    }

    private var friendStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                Button { showingFriend = true } label: {
                    VStack(spacing: 7) {
                        Circle().fill(PauseTheme.elevated).frame(width: 62, height: 62)
                            .overlay(Image(systemName: "plus").font(.title2.bold()))
                            .overlay(Circle().stroke(style: StrokeStyle(lineWidth: 2, dash: [4])).foregroundStyle(PauseTheme.indigo))
                        Text("Add friend").font(.caption)
                    }
                }.buttonStyle(.plain)
                ForEach(store.friends) { friend in
                    VStack(spacing: 7) {
                        Circle().fill(PauseTheme.socialGradient).frame(width: 66, height: 66)
                            .overlay(Circle().fill(PauseTheme.background).padding(3))
                            .overlay(Text(String(friend.displayName.prefix(1))).font(.title2.bold()))
                        Text(friend.displayName).font(.caption).lineLimit(1).frame(width: 68)
                    }
                }
            }.padding(.horizontal, 2)
        }
    }

    private var dailyIntention: some View {
        PauseCard { HStack(spacing: 14) {
            PauseIcon(systemName: "quote.opening", color: PauseTheme.mint)
            VStack(alignment: .leading, spacing: 4) { Text("Today’s intention").font(.caption.bold()).foregroundStyle(PauseTheme.mint); Text(store.profile.dailyIntention ?? "Nothing shared today").font(.headline) }
        } }
    }

    private var circles: some View {
        section("Accountability circles", action: { showingCircle = true }) {
            ForEach(store.circles) { circle in
                VStack(alignment: .leading, spacing: 8) {
                    Text(circle.name).font(.headline)
                    ProgressView(value: Double(circle.weeklyProgress), total: Double(max(1, circle.weeklyGoal)))
                    Text("\(circle.weeklyProgress) of \(circle.weeklyGoal) intentional sessions together")
                        .font(.caption).foregroundStyle(.secondary)
                }.card()
            }
        }
    }

    private var rooms: some View {
        section("Live focus rooms", action: { showingRoom = true }) {
            ForEach(store.rooms) { room in
                VStack(alignment: .leading, spacing: 10) {
                    HStack { Text(room.title).font(.headline); Spacer(); Text(room.state.rawValue.capitalized).font(.caption).foregroundStyle(PauseTheme.indigo) }
                    Text("\(room.durationMinutes) minutes · \(room.participantIDs.count) participant(s)").foregroundStyle(.secondary)
                    Button(room.participantIDs.contains(store.profile.id) ? "Start focusing" : "Join room") { store.join(room) }
                        .buttonStyle(.borderedProminent)
                }.card()
            }
        }
    }

    private var challenges: some View {
        section("Cooperative challenge") {
            ForEach(store.challenges) { challenge in
                VStack(alignment: .leading, spacing: 8) {
                    Text(challenge.title).font(.headline)
                    ProgressView(value: Double(challenge.progress), total: Double(max(1, challenge.target)))
                    Text("\(challenge.progress) of \(challenge.target) · no individual leaderboard").font(.caption).foregroundStyle(.secondary)
                }.card()
            }
        }
    }

    private var friends: some View {
        section("Trusted friends") {
            ForEach(store.friends) { friend in
                HStack {
                    Circle().fill(PauseTheme.mint).frame(width: 38, height: 38).overlay(Text(String(friend.displayName.prefix(1))).bold())
                    VStack(alignment: .leading) { Text(friend.displayName).bold(); Text(friend.status).font(.caption).foregroundStyle(.secondary) }
                    Spacer()
                    HStack(spacing: 3) {
                        ForEach(Array((friend.badgeSymbols ?? []).prefix(2)), id: \.self) { symbol in
                            Image(systemName: symbol).font(.caption2).foregroundStyle(PauseTheme.mint)
                        }
                    }
                    Menu { ForEach(Encouragement.Kind.allCases) { kind in Button(kind.rawValue) { store.send(kind, to: friend) } } } label: { Image(systemName: "hand.thumbsup") }
                }.card()
            }
        }
    }

    private var encouragements: some View {
        section("Encouragement") {
            ForEach(store.encouragements.prefix(3)) { item in
                Label("\(item.senderName): \(item.kind.rawValue)", systemImage: item.kind.symbol).card()
            }
        }
    }

    private func section<Content: View>(_ title: String, action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text(title).font(.title3.bold()); Spacer(); if let action { Button(action: action) { Image(systemName: "plus.circle.fill") } } }
            content()
        }
    }
}

private extension View {
    func card() -> some View { self.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(PauseTheme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 0.7)) }
}

private struct AddFriendSheet: View {
    @ObservedObject var store: SocialStore
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    var body: some View { NavigationStack { Form { TextField("Private friend code", text: $code).textInputAutocapitalization(.characters); Button("Send invitation") { if store.addFriend(code: code) { dismiss() } }.disabled(code.count < 4) } .navigationTitle("Add a trusted friend").toolbar { Button("Cancel") { dismiss() } } } }
}

private struct CreateCircleSheet: View {
    @ObservedObject var store: SocialStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    var body: some View { NavigationStack { Form { TextField("Circle name", text: $name); Button("Create private circle") { store.createCircle(name: name); dismiss() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) } .navigationTitle("New circle").toolbar { Button("Cancel") { dismiss() } } } }
}

private struct CreateRoomSheet: View {
    @ObservedObject var store: SocialStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var minutes = 25
    var body: some View { NavigationStack { Form { TextField("Focus topic", text: $title); Stepper("\(minutes) minutes", value: $minutes, in: 5...60, step: 5); Button("Create room") { store.createRoom(title: title, minutes: minutes); dismiss() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty) } .navigationTitle("New focus room").toolbar { Button("Cancel") { dismiss() } } } }
}
