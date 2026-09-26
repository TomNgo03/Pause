import SwiftUI

struct SessionPlannerView: View {
    @EnvironmentObject private var model: AppModel
    @FocusState private var taskFieldFocused: Bool
    @State private var step = 0
    @State private var task = ""
    @State private var duration = 25
    @State private var isCustomDuration = false
    private let presets = [15, 25, 40]
    private let suggestions = ["Review today’s class notes", "Draft one clear section", "Practice five problems"]

    var body: some View {
        ZStack {
            PauseBackground()
            VStack(spacing: 0) {
                progressHeader
                Group {
                    switch step {
                    case 0: intentionStep
                    case 1: durationStep
                    default: confirmationStep
                    }
                }
                .id(step)
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                footer
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: 620)
        }
        .foregroundStyle(PauseTheme.ink)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { taskFieldFocused = true }
    }

    private var progressHeader: some View {
        VStack(spacing: 18) {
            HStack {
                Button { goBack() } label: { Image(systemName: step == 0 ? "xmark" : "chevron.left").frame(width: 44, height: 44).background(PauseTheme.paper, in: Circle()) }
                    .accessibilityLabel(step == 0 ? "Cancel" : "Previous question")
                Spacer()
                Text("0\(step + 1) / 03").font(.caption.monospacedDigit().weight(.semibold)).foregroundStyle(PauseTheme.muted)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(PauseTheme.ink.opacity(0.08))
                    Capsule().fill(PauseTheme.orange).frame(width: geometry.size.width * CGFloat(step + 1) / 3)
                }
            }.frame(height: 5)
        }.padding(.top, 10)
    }

    private var intentionStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("What deserves your\nattention right now?").font(.system(size: 39, weight: .bold, design: .serif)).tracking(-0.8)
            Text("Keep it small and specific.").font(.title3).foregroundStyle(PauseTheme.muted)
            TextField("e.g. Draft the introduction", text: $task, axis: .vertical)
                .font(.title3.weight(.medium)).lineLimit(2...4).focused($taskFieldFocused)
                .padding(20).background(PauseTheme.paper, in: RoundedRectangle(cornerRadius: 20)).overlay(RoundedRectangle(cornerRadius: 20).stroke(PauseTheme.ink.opacity(0.1)))
                .submitLabel(.next).onSubmit { if !taskTrimmed.isEmpty { next() } }
            VStack(alignment: .leading, spacing: 10) {
                Text("A FEW IDEAS").font(.caption.bold()).tracking(1.2).foregroundStyle(PauseTheme.muted)
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        task = suggestion
                        taskFieldFocused = false
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.up.left").font(.caption.bold()).foregroundStyle(PauseTheme.orange)
                            Text(suggestion).font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                        .padding(.horizontal, 16).frame(minHeight: 48)
                        .background(PauseTheme.sage.opacity(task == suggestion ? 1 : 0.48), in: RoundedRectangle(cornerRadius: 15))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Uses this as your focus intention")
                }
            }
            Spacer()
        }
    }

    private var durationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("How long feels\nrealistic today?").font(.system(size: 39, weight: .bold, design: .serif)).tracking(-0.8)
            Text("A smaller promise is often easier to keep.").font(.title3).foregroundStyle(PauseTheme.muted)
            VStack(spacing: 10) {
                ForEach(presets, id: \.self) { value in
                    Button { duration = value; isCustomDuration = false } label: {
                        HStack { Text("\(value) minutes").font(.title3.weight(.semibold)); Spacer(); Image(systemName: !isCustomDuration && duration == value ? "checkmark.circle.fill" : "circle").font(.title3).foregroundStyle(!isCustomDuration && duration == value ? PauseTheme.orange : PauseTheme.muted) }
                            .padding(.horizontal, 20).frame(height: 62).background(!isCustomDuration && duration == value ? PauseTheme.sage : PauseTheme.paper, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                }
                Button { if !isCustomDuration { duration = 30 }; isCustomDuration = true } label: {
                    HStack { Text("Custom").font(.title3.weight(.semibold)); Spacer(); Text(isCustomDuration ? "\(duration) min" : "Choose").font(.subheadline.weight(.semibold)).foregroundStyle(PauseTheme.muted); Image(systemName: isCustomDuration ? "checkmark.circle.fill" : "circle").font(.title3).foregroundStyle(isCustomDuration ? PauseTheme.orange : PauseTheme.muted) }
                        .padding(.horizontal, 20).frame(height: 62).background(isCustomDuration ? PauseTheme.sage : PauseTheme.paper, in: RoundedRectangle(cornerRadius: 18))
                }.buttonStyle(.plain)
                if isCustomDuration {
                    HStack(spacing: 22) {
                        Button { duration = max(5, duration - 5) } label: { Image(systemName: "minus").frame(width: 48, height: 48).background(PauseTheme.paper, in: Circle()) }.disabled(duration <= 5).accessibilityLabel("Remove five minutes")
                        Text("\(duration)").font(.system(size: 40, weight: .bold, design: .rounded)).monospacedDigit().frame(minWidth: 72)
                        Text("minutes").font(.subheadline).foregroundStyle(PauseTheme.muted)
                        Button { duration = min(120, duration + 5) } label: { Image(systemName: "plus").frame(width: 48, height: 48).background(PauseTheme.paper, in: Circle()) }.disabled(duration >= 120).accessibilityLabel("Add five minutes")
                    }.frame(maxWidth: .infinity).padding(.vertical, 8)
                }
            }
            Spacer()
        }
    }

    private var confirmationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("One clear promise.").font(.system(size: 39, weight: .bold, design: .serif)).tracking(-0.8)
            Text("Everything can be adjusted later.").font(.title3).foregroundStyle(PauseTheme.muted)
            EditorialCard(color: PauseTheme.sage) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("YOUR COMMITMENT").font(.caption.bold()).tracking(1.4).foregroundStyle(PauseTheme.forest.opacity(0.75))
                    Text("For the next \(duration) minutes, I will \(taskTrimmed.lowercased()).")
                        .font(.system(size: 27, weight: .semibold, design: .serif)).lineSpacing(4)
                    HStack { Label("\(duration) min", systemImage: "timer"); Spacer(); Label("Private", systemImage: "lock.fill") }.font(.caption.weight(.semibold)).foregroundStyle(PauseTheme.muted)
                }
            }
            Spacer()
        }
    }

    private var footer: some View {
        Button(step == 2 ? "Begin focus" : "Continue") {
            step == 2 ? begin() : next()
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(step == 0 && taskTrimmed.isEmpty)
        .accessibilityIdentifier(step == 2 ? "beginSession" : "nextQuestion")
    }

    private var taskTrimmed: String { task.trimmingCharacters(in: .whitespacesAndNewlines) }
    private func next() { taskFieldFocused = false; withAnimation(.easeInOut(duration: 0.25)) { step = min(2, step + 1) } }
    private func goBack() { if step == 0 { model.route = .home } else { withAnimation(.easeInOut(duration: 0.25)) { step -= 1 }; if step == 0 { taskFieldFocused = true } } }
    private func begin() {
        let now = Date.now
        let draft = SessionDraft(intention: .learning, plannedStart: now, plannedEnd: now.addingTimeInterval(Double(duration * 60)), task: taskTrimmed, energy: .steady, expectedDistraction: .none)
        Task { await model.start(draft) }
    }
}
