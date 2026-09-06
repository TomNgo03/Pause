import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingCancel = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [PauseTheme.ink, PauseTheme.indigo.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            StarField().ignoresSafeArea()

            TimelineView(.periodic(from: .now, by: 1)) { context in
                let progress = progress(at: context.date)

                VStack(spacing: 26) {
                    HStack {
                        Label("FOCUSING", systemImage: "circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(PauseTheme.mint)
                        Spacer()
                        Text("\(Int(progress * 100))% complete")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    ZStack {
                        Planet(progress: progress)
                        Circle().stroke(.white.opacity(0.10), lineWidth: 11)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                AngularGradient(colors: [.white, PauseTheme.mint], center: .center),
                                style: StrokeStyle(lineWidth: 11, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.8), value: progress)

                        VStack(spacing: 6) {
                            Text(remaining(at: context.date))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("until arrival")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.66))
                        }

                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(progress * 360 + 42))
                            .offset(
                                x: CGFloat(cos(progress * .pi * 2 - .pi / 2)) * 145,
                                y: CGFloat(sin(progress * .pi * 2 - .pi / 2)) * 145
                            )
                            .shadow(color: PauseTheme.mint.opacity(0.7), radius: 8)
                    }
                    .frame(width: 280, height: 280)
                    .accessibilityElement(children: .combine)

                    VStack(spacing: 7) {
                        Text("Your intention")
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .foregroundStyle(.white.opacity(0.55))
                        Text(model.activeSession?.intention.rawValue ?? "Your intention")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    Button("Finish and reflect") {
                        Task { await model.finishSession() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("finishSession")

                    HStack {
                        Button("Add 5 min") { Task { await model.extendSession() } }
                        Spacer()
                        Button("Cancel", role: .destructive) { showingCancel = true }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.horizontal, 8)
                }
                .padding(24)
                .foregroundStyle(.white)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Cancel this session?", isPresented: $showingCancel) {
            Button("Cancel session", role: .destructive) { Task { await model.cancelSession() } }
            Button("Keep focusing", role: .cancel) {}
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

private struct StarField: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<70 {
                let x = CGFloat((index * 47) % 101) / 100 * size.width
                let y = CGFloat((index * 83) % 103) / 102 * size.height
                let radius: CGFloat = index.isMultiple(of: 9) ? 1.8 : 0.8
                let star = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
                context.fill(
                    Path(ellipseIn: star),
                    with: .color(.white.opacity(index.isMultiple(of: 3) ? 0.72 : 0.35))
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct Planet: View {
    let progress: Double

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        PauseTheme.violet.opacity(0.88),
                        PauseTheme.indigo.opacity(0.70),
                        PauseTheme.ink
                    ],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: 150
                )
            )
            .overlay(alignment: .topLeading) {
                Circle().fill(.white.opacity(0.10)).frame(width: 46).offset(x: 48, y: 55)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle().fill(.black.opacity(0.16)).frame(width: 33).offset(x: -52, y: -48)
            }
            .shadow(color: PauseTheme.violet.opacity(0.38), radius: 32)
            .scaleEffect(0.86 + progress * 0.08)
            .padding(18)
            .accessibilityHidden(true)
    }
}
