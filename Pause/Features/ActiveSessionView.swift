import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingCancel = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let journeyProgress = progress(at: context.date)
            let animationPhase = context.date.timeIntervalSinceReferenceDate

            ZStack {
                Image("SpaceVoyage").resizable().scaledToFill().ignoresSafeArea()
                LinearGradient(colors: [.black.opacity(0.18), .clear, PauseTheme.ink.opacity(0.9)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()

                VStack(spacing: 12) {
                    journeyHeader(progress: journeyProgress)
                    SpaceJourneyScene(progress: journeyProgress, phase: animationPhase)
                        .frame(maxHeight: .infinity)

                    VStack(spacing: 6) {
                        Text(remaining(at: context.date))
                            .font(.system(size: 54, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text(model.activeSession?.intention.rawValue.uppercased() ?? "FOCUS VOYAGE")
                            .font(.caption.bold()).tracking(1.8).foregroundStyle(.white.opacity(0.68))
                    }
                    .accessibilityElement(children: .combine)

                    Button { Task { await model.finishSession() } } label: {
                        Label("Complete voyage", systemImage: "flag.checkered").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("finishSession")

                    HStack {
                        Button("Add 5 min") { Task { await model.extendSession() } }
                        Spacer()
                        Button("End journey", role: .destructive) { showingCancel = true }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .foregroundStyle(.white)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("End this journey?", isPresented: $showingCancel) {
            Button("End session", role: .destructive) { Task { await model.cancelSession() } }
            Button("Keep exploring", role: .cancel) {}
        }
    }

    private func journeyHeader(progress: Double) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("DEEP SPACE MISSION").font(.caption2.bold()).tracking(1.7).foregroundStyle(PauseTheme.mint)
                Text(journeyStatus(progress)).font(.headline)
            }
            Spacer()
            Text("\(Int(progress * 100))%")
                .font(.headline.monospacedDigit())
                .padding(.horizontal, 13).padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private func journeyStatus(_ progress: Double) -> String {
        switch progress {
        case ..<0.08: return "Preparing for launch"
        case ..<0.35: return "Leaving orbit"
        case ..<0.7: return "Crossing the nebula"
        case ..<0.95: return "Destination ahead"
        default: return "Planet discovered"
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

private struct SpaceJourneyScene: View {
    let progress: Double
    let phase: TimeInterval

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let start = CGPoint(x: size.width * 0.14, y: size.height * 0.8)
            let control = CGPoint(x: size.width * 0.43, y: size.height * 0.22)
            let finish = CGPoint(x: size.width * 0.83, y: size.height * 0.25)
            let ship = bezierPoint(progress, start: start, control: control, finish: finish)
            let direction = bezierDirection(progress, start: start, control: control, finish: finish)

            ZStack {
                Canvas { context, _ in
                    var route = Path()
                    route.move(to: start)
                    route.addQuadCurve(to: finish, control: control)
                    context.stroke(route, with: .color(.white.opacity(0.18)), style: StrokeStyle(lineWidth: 2, dash: [5, 9]))
                    let travelled = route.trimmedPath(from: 0, to: progress)
                    context.stroke(travelled, with: .linearGradient(
                        Gradient(colors: [PauseTheme.mint.opacity(0.4), PauseTheme.mint]),
                        startPoint: start, endPoint: finish
                    ), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }

                planet(symbol: "circle.grid.cross", color: .purple, name: "HOME", pulse: 0.96 + 0.04 * sin(phase * 2))
                    .position(start)
                planet(symbol: progress >= 0.98 ? "sparkles" : "circle.dotted.circle", color: PauseTheme.mint, name: progress >= 0.98 ? "DISCOVERED" : "UNKNOWN", pulse: 1 + 0.04 * sin(phase * 1.7))
                    .scaleEffect(0.86 + progress * 0.14)
                    .position(finish)

                spacecraft
                    .rotationEffect(.radians(atan2(direction.dy, direction.dx) + .pi / 2))
                    .offset(y: CGFloat(sin(phase * 4)) * 3)
                    .position(ship)
                    .shadow(color: PauseTheme.mint.opacity(0.8), radius: 12)

                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(PauseTheme.mint.opacity(0.5 - Double(index) * 0.12))
                        .frame(width: 4, height: 4)
                        .position(
                            x: ship.x - direction.dx * CGFloat(14 + index * 10),
                            y: ship.y - direction.dy * CGFloat(14 + index * 10)
                        )
                }
            }
        }
        .accessibilityLabel("Space journey \(Int(progress * 100)) percent complete")
    }

    private var spacecraft: some View {
        ZStack {
            Circle().fill(PauseTheme.mint.opacity(0.14)).frame(width: 58, height: 58)
            Image(systemName: "paperplane.fill").font(.system(size: 29, weight: .semibold)).foregroundStyle(.white)
        }
    }

    private func planet(symbol: String, color: Color, name: String, pulse: Double) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(color.opacity(0.18)).frame(width: 94, height: 94).blur(radius: 8)
                Circle().fill(.ultraThinMaterial).frame(width: 72, height: 72)
                Image(systemName: symbol).font(.system(size: 37)).foregroundStyle(color)
            }
            .scaleEffect(pulse)
            Text(name).font(.caption2.bold()).tracking(1.5).foregroundStyle(.white.opacity(0.65))
        }
    }

    private func bezierPoint(_ progress: Double, start: CGPoint, control: CGPoint, finish: CGPoint) -> CGPoint {
        let t = CGFloat(progress)
        let inverse = 1 - t
        return CGPoint(
            x: inverse * inverse * start.x + 2 * inverse * t * control.x + t * t * finish.x,
            y: inverse * inverse * start.y + 2 * inverse * t * control.y + t * t * finish.y
        )
    }

    private func bezierDirection(_ progress: Double, start: CGPoint, control: CGPoint, finish: CGPoint) -> CGVector {
        let t = CGFloat(progress)
        let dx = 2 * (1 - t) * (control.x - start.x) + 2 * t * (finish.x - control.x)
        let dy = 2 * (1 - t) * (control.y - start.y) + 2 * t * (finish.y - control.y)
        let length = max(1, sqrt(dx * dx + dy * dy))
        return CGVector(dx: dx / length, dy: dy / length)
    }
}
