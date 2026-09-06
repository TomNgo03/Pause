import SwiftUI

struct AIPlannerView: View {
    @EnvironmentObject private var model: AppModel
    @State private var task = ""
    @State private var deadline = Date.now.addingTimeInterval(86_400)
    @State private var minutes = 45
    @State private var energy: AIPlanRequest.EnergyLevel = .medium
    @State private var style: AIPlanRequest.FocusStyle = .balanced
    @State private var plan: AIPlan?
    @State private var loading = false
    @State private var showingPreferences = false

    var body: some View {
        Form {
            Section("What needs to be done?") {
                TextField("Example: Review two biology chapters", text: $task, axis: .vertical).lineLimit(3...5)
                DatePicker("Deadline", selection: $deadline, in: Date.now...)
                Stepper("Available time: \(minutes) minutes", value: $minutes, in: 10...180, step: 5)
            }
            Section {
                DisclosureGroup("Personalize this plan (optional)", isExpanded: $showingPreferences) {
                    Picker("Energy right now", selection: $energy) { ForEach(AIPlanRequest.EnergyLevel.allCases) { Text($0.rawValue).tag($0) } }
                    Picker("Preferred session length", selection: $style) { ForEach(AIPlanRequest.FocusStyle.allCases) { Text($0.rawValue).tag($0) } }
                }
            }
            Section {
                Button { Task { await generate() } } label: {
                    if loading { ProgressView().frame(maxWidth: .infinity) } else { Label("Create a draft plan", systemImage: "wand.and.stars").frame(maxWidth: .infinity) }
                }.buttonStyle(PrimaryButtonStyle()).disabled(loading || task.trimmingCharacters(in: .whitespaces).isEmpty)
                Text("Your task description may be sent to the configured AI service. Do not include passwords, diagnoses, private names, or confidential school information.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if let plan { planSection(plan) }
        }
        .scrollContentBackground(.hidden)
        .background(PauseBackground())
        .navigationTitle("Planning coach").navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder private func planSection(_ plan: AIPlan) -> some View {
        Section("Editable draft — approval required") {
            Text(plan.title).font(.headline)
            Text(plan.summary).foregroundStyle(.secondary)
            ForEach(Array(plan.steps.enumerated()), id: \.element.id) { index, step in
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(index + 1). \(step.title)").bold()
                    Text("\(step.durationMinutes) min focus" + (step.breakMinutes > 0 ? " · \(step.breakMinutes) min break" : ""))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            if let note = plan.safetyNote { Label(note, systemImage: "heart").font(.footnote) }
            Button("Accept first step and begin") {
                guard let first = plan.steps.first else { return }
                let now = Date.now
                Task { await model.start(SessionDraft(intention: first.intention, plannedStart: now, plannedEnd: now.addingTimeInterval(Double(first.durationMinutes * 60)))) }
            }.buttonStyle(PrimaryButtonStyle())
        }
    }

    private func generate() async {
        loading = true; defer { loading = false }
        do { plan = try await model.planner.createPlan(AIPlanRequest(task: task, deadline: deadline, availableMinutes: minutes, energy: energy, style: style)) }
        catch { model.presentError(error.localizedDescription) }
    }
}
