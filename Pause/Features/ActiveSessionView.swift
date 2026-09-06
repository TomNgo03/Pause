import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingCancel = false

    var body: some View {
        ZStack {
            Image("SpaceVoyage").resizable().scaledToFill().ignoresSafeArea()
            LinearGradient(colors: [.black.opacity(0.08), .clear, PauseTheme.ink.opacity(0.84)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let progress = progress(at: context.date)
                VStack(spacing: 26) {
                    HStack {
                        Label("EN ROUTE", systemImage: "location.north.fill").font(.caption.bold()).tracking(1.2).foregroundStyle(PauseTheme.mint)
                        Spacer()
                        Text("VOYAGE  ·  \(Int(progress * 100))%").font(.caption.bold()).monospacedDigit().foregroundStyle(.white.opacity(0.78))
                    }.padding(.horizontal, 4)
                    Spacer()
                    ZStack {
                        Circle().fill(.ultraThinMaterial).overlay(Circle().fill(PauseTheme.ink.opacity(0.30)))
                        Circle().stroke(.white.opacity(0.10), lineWidth: 11)
                        Circle().trim(from: 0, to: progress).stroke(AngularGradient(colors: [.white, PauseTheme.mint], center: .center), style: StrokeStyle(lineWidth: 11, lineCap: .round)).rotationEffect(.degrees(-90)).animation(.linear(duration: 0.8), value: progress)
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles").foregroundStyle(PauseTheme.mint)
                            Text(remaining(at: context.date)).font(.system(size: 48, weight: .bold, design: .rounded)).monospacedDigit()
                            Text("UNTIL ARRIVAL").font(.caption.bold()).tracking(1.8).foregroundStyle(.white.opacity(0.62))
                        }
                        Image(systemName: "paperplane.fill").foregroundStyle(.white).rotationEffect(.degrees(42))
                            .offset(x: CGFloat(cos(progress * .pi * 2 - .pi / 2)) * 145,
                                    y: CGFloat(sin(progress * .pi * 2 - .pi / 2)) * 145)
                    }.frame(width: 280, height: 280).accessibilityElement(children: .combine)
                    VStack(spacing: 7) { Text("MISSION").font(.caption.weight(.semibold)).tracking(1.8).foregroundStyle(PauseTheme.mint); Text(model.activeSession?.intention.rawValue ?? "Your intention").font(.title2.bold()).multilineTextAlignment(.center) }
                    Spacer()
                    Button { Task { await model.finishSession() } } label: { Label("Complete voyage", systemImage: "flag.checkered").frame(maxWidth: .infinity) }.buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("finishSession")
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
