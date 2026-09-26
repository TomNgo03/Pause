import SwiftUI

struct AIPlannerView: View {
    @EnvironmentObject private var model: AppModel
    @FocusState private var promptFocused: Bool
    @State private var screen: CoachScreen = .prompt
    @State private var goal = ""
    @State private var deadline = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var plans: [AIPlan] = []
    @State private var selectedIndex = 0
    @State private var chosenIndex: Int?
    @State private var generationSource: PlanGenerationSource = .localPlanner

    var body: some View {
        ZStack {
            PauseBackground()
            switch screen {
            case .prompt: promptScreen
            case .generating: generatingScreen
            case .choices: choicesScreen
            }
        }
        .foregroundStyle(PauseTheme.ink)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { restoreSavedPlan() }
    }

    private var promptScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("AI FOCUS COACH").font(.caption.bold()).tracking(1.5).foregroundStyle(PauseTheme.orange)
                    Text("What do you want\nto accomplish?").font(.system(size: 39, weight: .bold, design: .serif)).tracking(-0.8)
                    Text("Describe the goal naturally. Coach will make three routes you can actually follow.").font(.title3).foregroundStyle(PauseTheme.muted)
                }

                TextField("Example: Do 20 hard LeetCode questions with no coding background", text: $goal, axis: .vertical)
                    .font(.title3.weight(.medium)).lineLimit(4...8).focused($promptFocused)
                    .padding(20).background(PauseTheme.paper, in: RoundedRectangle(cornerRadius: 22)).overlay(RoundedRectangle(cornerRadius: 22).stroke(PauseTheme.ink.opacity(0.1)))

                EditorialCard {
                    HStack(spacing: 14) {
                        Image(systemName: "calendar.badge.clock").font(.title2).foregroundStyle(PauseTheme.orange)
                        VStack(alignment: .leading, spacing: 3) { Text("Deadline").font(.headline); Text(deadlineHint).font(.caption).foregroundStyle(PauseTheme.muted) }
                        Spacer()
                        DatePicker("Deadline", selection: $deadline, in: Calendar.current.startOfDay(for: .now)..., displayedComponents: .date).labelsHidden()
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("TRY AN EXAMPLE").font(.caption.bold()).tracking(1.2).foregroundStyle(PauseTheme.muted)
                    Button { goal = "Do 20 hard LeetCode questions with no coding background"; promptFocused = false } label: {
                        HStack { Image(systemName: "arrow.up.left").foregroundStyle(PauseTheme.orange); Text("Learn enough coding to begin LeetCode").font(.subheadline.weight(.semibold)); Spacer() }
                            .padding(16).background(PauseTheme.sage.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
                    }.buttonStyle(.plain)
                }

                aiStatus

                Button { makePlans() } label: {
                    Label(model.planner.isOnDeviceAIAvailable() ? "Make three plans with AI" : "Make three private plans", systemImage: model.planner.isOnDeviceAIAvailable() ? "apple.intelligence" : "wand.and.stars")
                }.buttonStyle(PrimaryButtonStyle()).disabled(cleanGoal.isEmpty)

                Text("Coach may challenge an unrealistic goal instead of pretending it can be completed immediately.").font(.caption).foregroundStyle(PauseTheme.muted)
            }.padding(20).padding(.bottom, 30).frame(maxWidth: 700)
        }
    }

    private var aiStatus: some View {
        HStack(spacing: 12) {
            Image(systemName: model.planner.isOnDeviceAIAvailable() ? "apple.intelligence" : "lock.fill").font(.title3).foregroundStyle(PauseTheme.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.planner.isOnDeviceAIAvailable() ? "On-device AI ready" : "Private local planner ready").font(.subheadline.bold())
                Text(model.planner.onDeviceAIStatus()).font(.caption).foregroundStyle(PauseTheme.muted)
            }
        }.padding(15).frame(maxWidth: .infinity, alignment: .leading).background(PauseTheme.sage, in: RoundedRectangle(cornerRadius: 16))
    }

    private var generatingScreen: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(PauseTheme.sage).frame(width: 132, height: 132)
                Image(systemName: model.planner.isOnDeviceAIAvailable() ? "apple.intelligence" : "wand.and.stars").font(.system(size: 45)).foregroundStyle(PauseTheme.forest)
                ProgressView().tint(PauseTheme.orange).scaleEffect(1.25).offset(y: 88)
            }
            VStack(spacing: 10) {
                Text("Making three paths…").font(.system(size: 34, weight: .bold, design: .serif))
                Text("Checking the starting point, prerequisites, and a realistic first step.").font(.title3).foregroundStyle(PauseTheme.muted).multilineTextAlignment(.center).lineSpacing(4)
            }
            EditorialCard { VStack(alignment: .leading, spacing: 8) { Text("YOUR GOAL").font(.caption.bold()).tracking(1.2).foregroundStyle(PauseTheme.orange); Text(cleanGoal).font(.headline); Label("Due \(deadline.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar").font(.caption).foregroundStyle(PauseTheme.muted) } }
            Spacer()
        }.padding(26).frame(maxWidth: 600)
    }

    private var choicesScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                HStack { Button { reset() } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44).background(PauseTheme.paper, in: Circle()) }.accessibilityLabel("Create new plans"); Spacer(); Label(generationSource.label, systemImage: generationSource == .onDeviceAI ? "apple.intelligence" : "lock.fill").font(.caption.bold()).foregroundStyle(PauseTheme.muted) }
                VStack(alignment: .leading, spacing: 6) { Text("Choose your path.").font(.system(size: 38, weight: .bold, design: .serif)); Text("All three move toward the same goal with a different pace.").foregroundStyle(PauseTheme.muted) }
                optionPicker
                if plans.indices.contains(selectedIndex) { planDetail(plans[selectedIndex], index: selectedIndex) }
            }.padding(20).padding(.bottom, 34).frame(maxWidth: 760)
        }
    }

    private var optionPicker: some View {
        VStack(spacing: 10) {
            ForEach(Array(plans.enumerated()), id: \.element.id) { index, plan in
                Button { withAnimation(.easeOut(duration: 0.2)) { selectedIndex = index } } label: {
                    HStack(spacing: 14) {
                        Text("0\(index + 1)").font(.caption.monospacedDigit().bold()).foregroundStyle(selectedIndex == index ? .white : PauseTheme.orange).frame(width: 42, height: 42).background(selectedIndex == index ? PauseTheme.orange : PauseTheme.sage, in: Circle())
                        VStack(alignment: .leading, spacing: 4) { Text(plan.title).font(.headline); Text("\(plan.totalMinutes) min · \(plan.steps.count) steps").font(.caption).foregroundStyle(selectedIndex == index ? .white.opacity(0.72) : PauseTheme.muted) }
                        Spacer(); Image(systemName: chosenIndex == index ? "checkmark.seal.fill" : "chevron.right").foregroundStyle(selectedIndex == index ? .white : PauseTheme.muted)
                    }.padding(16).foregroundStyle(selectedIndex == index ? Color.white : PauseTheme.ink).background(selectedIndex == index ? PauseTheme.forest : PauseTheme.paper, in: RoundedRectangle(cornerRadius: 19))
                }.buttonStyle(.plain)
            }
        }
    }

    private func planDetail(_ plan: AIPlan, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            EditorialCard(color: PauseTheme.sage) { VStack(alignment: .leading, spacing: 10) { Text("WHY THIS PATH").font(.caption.bold()).tracking(1.2).foregroundStyle(PauseTheme.orange); Text(plan.summary).font(.title3.weight(.semibold)); if let note = plan.safetyNote { Label(note, systemImage: "heart.fill").font(.caption).foregroundStyle(PauseTheme.muted) } } }
            Text("Step by step").font(.title2.bold())
            ForEach(Array(plan.steps.enumerated()), id: \.element.id) { stepIndex, step in
                HStack(alignment: .top, spacing: 14) {
                    Text("\(stepIndex + 1)").font(.subheadline.bold()).foregroundStyle(.white).frame(width: 34, height: 34).background(PauseTheme.orange, in: Circle())
                    VStack(alignment: .leading, spacing: 5) { Text(step.title).font(.headline); Text("Focus for \(step.durationMinutes) minutes" + (step.breakMinutes > 0 ? ", then take a \(step.breakMinutes)-minute break." : ".")).font(.subheadline).foregroundStyle(PauseTheme.muted) }
                }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(PauseTheme.paper, in: RoundedRectangle(cornerRadius: 18))
            }
            if chosenIndex == index {
                Label("This is your selected plan", systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(PauseTheme.forest).frame(maxWidth: .infinity)
                if let first = plan.steps.first { Button("Start step one") { start(first) }.buttonStyle(PrimaryButtonStyle()) }
            } else {
                Button("Choose this plan") { chosenIndex = index; save(plan) }.buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private var cleanGoal: String { goal.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var deadlineHint: String { let days = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: deadline)).day ?? 0); return days == 0 ? "Today" : days == 1 ? "Tomorrow" : "\(days) days remaining" }
    private func makePlans() { promptFocused = false; withAnimation { screen = .generating }; Task { do { let result = try await model.planner.createPlanOptions(for: cleanGoal, deadline: deadline); await MainActor.run { plans = result.plans; generationSource = result.source; selectedIndex = 0; chosenIndex = nil; withAnimation { screen = .choices } } } catch { await MainActor.run { model.presentError(error.localizedDescription); screen = .prompt } } } }
    private func save(_ plan: AIPlan) { UserDefaults.standard.set(try? JSONEncoder().encode(plan), forKey: "activeFocusPlan"); UserDefaults.standard.set(generationSource.rawValue, forKey: "activeFocusPlanSource") }
    private func start(_ step: AIPlanStep) { let now = Date.now; Task { await model.start(SessionDraft(intention: step.intention, plannedStart: now, plannedEnd: now.addingTimeInterval(Double(step.durationMinutes * 60)), task: step.title)) } }
    private func reset() { plans = []; chosenIndex = nil; selectedIndex = 0; screen = .prompt; UserDefaults.standard.removeObject(forKey: "activeFocusPlan") }
    private func restoreSavedPlan() {
        guard plans.isEmpty, let data = UserDefaults.standard.data(forKey: "activeFocusPlan"), let saved = try? JSONDecoder().decode(AIPlan.self, from: data) else { return }
        if saved.steps.contains(where: { $0.title == "Continue with the next concrete part" }) {
            UserDefaults.standard.removeObject(forKey: "activeFocusPlan")
            UserDefaults.standard.removeObject(forKey: "activeFocusPlanSource")
            return
        }
        plans = [saved]; selectedIndex = 0; chosenIndex = 0
        generationSource = PlanGenerationSource(rawValue: UserDefaults.standard.string(forKey: "activeFocusPlanSource") ?? "") ?? .localPlanner
        screen = .choices
    }
}

private enum CoachScreen { case prompt, generating, choices }
