import SwiftUI

#if PAUSE_SCREEN_TIME
import FamilyControls

struct ProtectedAppsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selection = FamilyActivitySelection()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Choose only one to three apps for the first week. Pause never receives their browsing content or messages.")
                .foregroundStyle(.secondary)
            FamilyActivityPicker(selection: $selection)
            Button("Save and protect selection") {
                guard let service = model.screenTime as? AppleScreenTimeService else { return }
                Task {
                    do {
                        try service.save(selection: selection)
                        await service.protectSelectedApps()
                        model.route = .home
                    } catch { model.presentError(error.localizedDescription) }
                }
            }.buttonStyle(PrimaryButtonStyle())
        }
        .padding().navigationTitle("Protected apps")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { model.route = .home } } }
    }
}
#else
struct ProtectedAppsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selected = Set<String>()
    private let examples = ["Social media", "Short videos", "Games", "Streaming"]

    var body: some View {
        List {
            Section {
                Text("Prototype Mode demonstrates the planning experience but cannot shield other apps. Enable the Screen Time build after Apple capability setup.")
                    .foregroundStyle(.secondary)
            }
            Section("Simulated categories") {
                ForEach(examples, id: \.self) { item in
                    Button {
                        if selected.contains(item) { selected.remove(item) } else if selected.count < 3 { selected.insert(item) }
                    } label: {
                        HStack { Text(item); Spacer(); if selected.contains(item) { Image(systemName: "checkmark.circle.fill") } }
                    }.foregroundStyle(.primary)
                }
            }
            Button("Save selection") { model.route = .home }.buttonStyle(PrimaryButtonStyle())
        }
        .navigationTitle("Protected apps")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { model.route = .home } } }
    }
}
#endif

