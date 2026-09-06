import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingCancel = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [PauseTheme.ink, PauseTheme.indigo.opacity(0.92)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let progress = progress(at: context.date)
                VStack(spacing: 26) {
                    HStack { Label("FOCUSING", systemImage: "circle.fill").font(.caption.bold()).foregroundStyle(PauseTheme.mint); Spacer(); Text(model.screenTime.modeDescription).font(.caption).foregroundStyle(.white.opacity(0.62)) }
                    Spacer()
                    ZStack {
                        Circle().stroke(.white.opacity(0.10), lineWidth: 14)
                        Circle().trim(from: 0, to: progress).stroke(AngularGradient(colors: [.white, PauseTheme.mint], center: .center), style: StrokeStyle(lineWidth: 14, lineCap: .round)).rotationEffect(.degrees(-90)).animation(.linear(duration: 0.8), value: progress)
                        VStack(spacing: 6) { Text(remaining(at: context.date)).font(.system(size: 54, weight: .bold, design: .rounded)).monospacedDigit(); Text("remaining").font(.subheadline).foregroundStyle(.white.opacity(0.60)) }
                    }.frame(width: 250, height: 250).accessibilityElement(children: .combine)
                    VStack(spacing: 7) { Text("Your intention").font(.caption.weight(.semibold)).textCase(.uppercase).foregroundStyle(.white.opacity(0.55)); Text(model.activeSession?.intention.rawValue ?? "Your intention").font(.title2.bold()).multilineTextAlignment(.center) }
                    Spacer()
                    Button("Finish and reflect") { Task { await model.finishSession() } }.buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("finishSession")
                    HStack { Button("Add 5 min") { Task { await model.extendSession() } }; Spacer(); Button("Cancel", role: .destructive) { showingCancel = true } }.font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.78)).padding(.horizontal, 8)
                }.padding(24).foregroundStyle(.white)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Cancel this session?", isPresented: $showingCancel) {
            Button("Cancel session", role: .destructive) { Task { await model.cancelSession() } }; Button("Keep focusing", role: .cancel) {}
        }
    }

    private func remaining(at date: Date) -> String {
        guard let end = model.activeSession?.plannedEnd else { return "00:00" }
        let seconds = max(0, Int(end.timeIntervalSince(date)))
        if seconds == 0 { Task { await model.finishSession() } }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func progress(at date: Date) -> Double {
        guard let session = model.activeSession else { return 0 }
        let total = session.plannedEnd.timeIntervalSince(session.plannedStart)
        guard total > 0 else { return 0 }
        return min(1, max(0, date.timeIntervalSince(session.plannedStart) / total))
    }
}

