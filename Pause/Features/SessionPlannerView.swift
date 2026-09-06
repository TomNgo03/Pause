import SwiftUI

struct SessionPlannerView: View {
    @EnvironmentObject private var model: AppModel
    @State private var step = 0
    @State private var intention: IntentionCategory?
    @State private var duration = 10
    private let durations = [2, 5, 10, 15, 20, 30]

    var body: some View {
        ZStack {
            PauseBackground()
            VStack(spacing: 0) {
                progress
                ScrollView { Group { if step == 0 { intentionStep } else { timeStep } }.padding(20) }
                footer.padding(20).background(.ultraThinMaterial)
            }
        }
        .navigationTitle(step == 0 ? "What is your intention?" : "How long do you need?").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { model.route = .home } } }
    }

    private var progress: some View { HStack(spacing: 8) { Capsule().fill(PauseTheme.indigo).frame(height: 5); Capsule().fill(step == 1 ? PauseTheme.indigo : Color.secondary.opacity(0.15)).frame(height: 5) }.padding(.horizontal, 20).padding(.top, 8) }

    private var intentionStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Choose the closest answer. It does not need to be perfect.").foregroundStyle(.secondary).padding(.bottom, 4)
            ForEach(IntentionCategory.allCases) { item in
                Button { intention = item } label: { HStack(spacing: 13) { PauseIcon(systemName: icon(for: item), color: color(for: item), size: 42); Text(item.rawValue).font(.headline).foregroundStyle(.primary); Spacer(); Image(systemName: intention == item ? "checkmark.circle.fill" : "circle").foregroundStyle(intention == item ? PauseTheme.indigo : .secondary) }.padding(14).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 19)).overlay(RoundedRectangle(cornerRadius: 19).stroke(intention == item ? PauseTheme.indigo : .clear, lineWidth: 2)) }.buttonStyle(.plain)
            }
        }
    }

    private var timeStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Start smaller than you think. You can add time later without it counting as a failure.").foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(durations, id: \.self) { value in Button { duration = value } label: { VStack(spacing: 4) { Text("\(value)").font(.title.bold()); Text("minutes").font(.caption) }.frame(maxWidth: .infinity).padding(.vertical, 18).foregroundStyle(duration == value ? .white : .primary).background(duration == value ? AnyShapeStyle(PauseTheme.heroGradient) : AnyShapeStyle(Material.regular), in: RoundedRectangle(cornerRadius: 18)) }.buttonStyle(.plain) }
            }
            if let intention { PauseCard { Label("\(intention.rawValue) for \(duration) minutes", systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(PauseTheme.indigo) } }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if step == 1 { Button("Back") { withAnimation { step = 0 } }.buttonStyle(SoftButtonStyle()).frame(maxWidth: 110) }
            Button(step == 0 ? "Choose time" : "Begin session") {
                if step == 0 { withAnimation(.snappy) { step = 1 } }
                else if let intention { let now = Date.now; Task { await model.start(SessionDraft(intention: intention, plannedStart: now, plannedEnd: now.addingTimeInterval(Double(duration * 60)))) } }
            }.buttonStyle(PrimaryButtonStyle()).disabled(intention == nil).accessibilityIdentifier(step == 0 ? "chooseTime" : "beginSession")
        }
    }

    private func icon(for item: IntentionCategory) -> String { switch item { case .message: "message.fill"; case .information: "magnifyingglass"; case .learning: "book.fill"; case .plannedContent: "play.rectangle.fill"; case .connection: "person.2.fill"; case .breakTime: "cup.and.saucer.fill"; case .other: "ellipsis" } }
    private func color(for item: IntentionCategory) -> Color { switch item { case .message: PauseTheme.sky; case .information: PauseTheme.violet; case .learning: PauseTheme.indigo; case .plannedContent: PauseTheme.coral; case .connection: PauseTheme.mint; case .breakTime: .orange; case .other: .secondary } }
}
