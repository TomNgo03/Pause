import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showingEndConfirmation = false
    @State private var showingIntention = false

    var body: some View {
        ZStack {
            PauseBackground()
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let effectiveDate = model.sessionPausedAt ?? context.date
                let progress = progress(at: effectiveDate)

                VStack(alignment: .leading, spacing: 0) {
                    header(progress: progress)
                    Spacer()
                    countdown(at: effectiveDate)
                    Spacer()
                    controls
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
        }
        .foregroundStyle(PauseTheme.ink)
        .toolbar(.hidden, for: .navigationBar)
        .alert("End this focus session?", isPresented: $showingEndConfirmation) {
            Button("Keep focusing", role: .cancel) {}
            Button("Finish and reflect") { Task { await model.finishSession() } }
            Button("Discard", role: .destructive) { Task { await model.cancelSession() } }
        } message: {
            Text("You can still reflect even when a session ends earlier than planned.")
        }
    }

    private func header(progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(model.sessionPausedAt == nil ? "FOCUS SESSION" : "SESSION PAUSED", systemImage: model.sessionPausedAt == nil ? "circle.fill" : "pause.fill")
                    .font(.caption.bold()).tracking(1.3).foregroundStyle(PauseTheme.orange)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption.monospacedDigit().weight(.semibold)).foregroundStyle(PauseTheme.muted)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(PauseTheme.ink.opacity(0.09))
                    Capsule().fill(PauseTheme.orange).frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 6)
            .accessibilityLabel("Session progress")
            .accessibilityValue("\(Int(progress * 100)) percent")
        }
    }

    private func countdown(at date: Date) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(model.sessionPausedAt == nil ? "Stay with this\none thing." : "Take the moment\nyou need.")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .tracking(-0.8)

            Text(remaining(at: date))
                .font(.system(size: 82, weight: .medium, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .accessibilityLabel("Time remaining")

            Button { withAnimation(.easeOut(duration: 0.2)) { showingIntention.toggle() } } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "scope").foregroundStyle(PauseTheme.orange).padding(.top, 2)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("YOUR INTENTION").font(.caption.bold()).tracking(1.2).foregroundStyle(PauseTheme.muted)
                        Text(sessionTitle).font(.title3.weight(.semibold)).multilineTextAlignment(.leading)
                        if showingIntention, let statement = model.activeSession?.successStatement, !statement.isEmpty {
                            Text("Success means: \(statement)").font(.subheadline).foregroundStyle(PauseTheme.muted).padding(.top, 3)
                        }
                    }
                    Spacer()
                    Image(systemName: showingIntention ? "chevron.up" : "chevron.down").font(.caption.bold()).foregroundStyle(PauseTheme.muted)
                }
                .padding(18)
                .background(PauseTheme.sage, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows the success statement")
        }
    }

    private var controls: some View {
        VStack(spacing: 14) {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                Task { await model.togglePause() }
            } label: {
                Label(model.sessionPausedAt == nil ? "Pause" : "Resume", systemImage: model.sessionPausedAt == nil ? "pause.fill" : "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            HStack(spacing: 12) {
                Button { Task { await model.extendSession() } } label: { Label("Add 5 min", systemImage: "plus") }
                    .buttonStyle(SoftButtonStyle())
                Button {
                    showingEndConfirmation = true
                } label: {
                    Label("End session", systemImage: "stop.fill")
                }
                    .buttonStyle(SoftButtonStyle())
                    .accessibilityIdentifier("endSession")
            }
        }
    }

    private var sessionTitle: String {
        guard let session = model.activeSession else { return "Your intention" }
        return session.task.isEmpty ? session.intention.rawValue : session.task
    }

    private func remaining(at date: Date) -> String {
        guard let end = model.activeSession?.plannedEnd else { return "00:00" }
        let seconds = max(0, Int(end.timeIntervalSince(date)))
        if seconds == 0, model.sessionPausedAt == nil { Task { await model.finishSession() } }
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func progress(at date: Date) -> Double {
        guard let session = model.activeSession else { return 0 }
        let total = session.plannedEnd.timeIntervalSince(session.plannedStart)
        guard total > 0 else { return 0 }
        return min(1, max(0, date.timeIntervalSince(session.plannedStart) / total))
    }
}
