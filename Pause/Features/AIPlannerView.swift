import SwiftUI

struct AIPlannerView: View {
    @EnvironmentObject private var model: AppModel
    @State private var task = ""
    @State private var deadline = Date.now.addingTimeInterval(86_400)
    @State private var minutes = 45
    @State private var energy: AIPlanRequest.EnergyLevel = .medium
    @State private var style: AIPlanRequest.FocusStyle = .balanced
    @State private var constraints = ""
    @State private var plan: AIPlan?
    @State private var completed: Set<UUID> = []
    @State private var loading = false

    var body: some View {
        ZStack { PauseBackground(); ScrollView(showsIndicators: false) { VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) { Text("COACH").font(.caption.bold()).tracking(1.5).foregroundStyle(PauseTheme.orange); Text("Turn pressure into\na possible plan.").font(.system(size: 37, weight: .bold, design: .serif)); Text("A useful local plan always works—even without internet.").foregroundStyle(PauseTheme.muted) }
            if let plan { planView(plan) } else { inputView }
        }.padding(20).padding(.bottom, 30).frame(maxWidth: 700) } }.foregroundStyle(PauseTheme.ink).toolbar(.hidden, for: .navigationBar).onAppear { restorePlan() }
    }

    private var inputView: some View { VStack(spacing: 16) {
        coachField("What must be completed?") { TextField("e.g. Review two biology chapters", text: $task, axis: .vertical).lineLimit(2...4) }
        coachField("Deadline") { DatePicker("Deadline", selection: $deadline, in: Date.now...).labelsHidden() }
        coachField("Time available today") { Stepper("\(minutes) minutes", value: $minutes, in: 10...180, step: 5) }
        HStack(spacing: 12) { coachField("Energy") { Picker("Energy", selection: $energy) { ForEach(AIPlanRequest.EnergyLevel.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu) }; coachField("Style") { Picker("Style", selection: $style) { ForEach(AIPlanRequest.FocusStyle.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu) } }
        coachField("Constraints (optional)") { TextField("Breaks, resources, or limits", text: $constraints, axis: .vertical) }
        Button { Task { await generate() } } label: { if loading { ProgressView().tint(.white) } else { Label("Create my plan", systemImage: "wand.and.stars") } }.buttonStyle(PrimaryButtonStyle()).disabled(loading || task.trimmingCharacters(in: .whitespaces).isEmpty)
        Label("Do not enter passwords, diagnoses, or confidential information. Coach is planning support, not professional advice.", systemImage: "lock.fill").font(.caption).foregroundStyle(PauseTheme.muted)
    } }

    private func planView(_ plan: AIPlan) -> some View { VStack(alignment: .leading, spacing: 18) {
        EditorialCard(color: PauseTheme.forest) { VStack(alignment: .leading, spacing: 11) { HStack { Text("LOCAL PLAN").font(.caption.bold()).tracking(1.3).foregroundStyle(PauseTheme.sage); Spacer(); Text("\(plan.totalMinutes)m").font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.65)) }; Text(plan.title).font(.title2.bold()).foregroundStyle(.white); Text(plan.summary).foregroundStyle(.white.opacity(0.7)) } }
        ForEach(Array(plan.steps.enumerated()), id: \.element.id) { index, step in
            EditorialCard { HStack(alignment: .top, spacing: 14) { Button { toggle(step.id) } label: { Image(systemName: completed.contains(step.id) ? "checkmark.circle.fill" : "circle").font(.title2).foregroundStyle(completed.contains(step.id) ? PauseTheme.orange : PauseTheme.muted) }; VStack(alignment: .leading, spacing: 6) { Text("STEP 0\(index + 1)").font(.caption.bold()).tracking(1).foregroundStyle(PauseTheme.orange); Text(step.title).font(.headline).strikethrough(completed.contains(step.id)); Text("\(step.durationMinutes) min focus" + (step.breakMinutes > 0 ? " · \(step.breakMinutes) min break" : "")).font(.caption).foregroundStyle(PauseTheme.muted) }; Spacer(); Button { start(step) } label: { Image(systemName: "play.fill").foregroundStyle(.white).frame(width: 42, height: 42).background(PauseTheme.forest, in: Circle()) }.accessibilityLabel("Start this step") } }
        }
        HStack { Button("Replace plan") { self.plan = nil; completed = []; savePlan(nil) }.buttonStyle(SoftButtonStyle()); if let first = plan.steps.first { Button("Start first step") { start(first) }.buttonStyle(PrimaryButtonStyle()) } }
    } }

    private func coachField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View { EditorialCard { VStack(alignment: .leading, spacing: 10) { Text(title).font(.headline); content() } } }
    private func generate() async { loading = true; defer { loading = false }; do { let request = AIPlanRequest(task: constraints.isEmpty ? task : "\(task). Constraints: \(constraints)", deadline: deadline, availableMinutes: minutes, energy: energy, style: style); let result = try await model.planner.createPlan(request); plan = result; savePlan(result) } catch { model.presentError(error.localizedDescription) } }
    private func start(_ step: AIPlanStep) { let now = Date.now; Task { await model.start(SessionDraft(intention: step.intention, plannedStart: now, plannedEnd: now.addingTimeInterval(Double(step.durationMinutes * 60)), task: step.title)) } }
    private func toggle(_ id: UUID) { if completed.contains(id) { completed.remove(id) } else { completed.insert(id) } }
    private func savePlan(_ plan: AIPlan?) { UserDefaults.standard.set(plan.flatMap { try? JSONEncoder().encode($0) }, forKey: "activeFocusPlan") }
    private func restorePlan() { guard plan == nil, let data = UserDefaults.standard.data(forKey: "activeFocusPlan") else { return }; plan = try? JSONDecoder().decode(AIPlan.self, from: data) }
}
