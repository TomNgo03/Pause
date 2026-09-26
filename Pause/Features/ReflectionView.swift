import SwiftUI
import SwiftData

struct ReflectionView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.modelContext) private var context
    @State private var outcome: IntentionOutcome = .partly
    @State private var rating = 3
    @State private var distraction: SessionDistraction = .none
    @State private var note = ""
    @State private var nextStep = ""

    var body: some View {
        ZStack { PauseBackground(); ScrollView { VStack(alignment: .leading, spacing: 24) {
            Text("Notice, don’t\njudge.").font(.system(size: 40, weight: .bold, design: .serif))
            Text("A short reflection helps the next session fit you better.").foregroundStyle(PauseTheme.muted)
            block("Did you complete what you planned?") { Picker("Outcome", selection: $outcome) { ForEach([IntentionOutcome.yes, .partly, .no]) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented) }
            block("How focused did you feel?") { HStack { ForEach(1...5, id: \.self) { value in Button { rating = value } label: { Image(systemName: value <= rating ? "circle.fill" : "circle").font(.title3).foregroundStyle(value <= rating ? PauseTheme.orange : PauseTheme.muted) }.accessibilityLabel("Focus rating \(value)") } } }
            block("What pulled your attention most?") { Picker("Distraction", selection: $distraction) { ForEach(SessionDistraction.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.menu) }
            block("Anything worth remembering? (optional)") { TextField("A short, private note", text: $note, axis: .vertical).lineLimit(2...4) }
            block("What is the next small step?") { TextField("Make tomorrow easier", text: $nextStep, axis: .vertical) }
            Button("Save reflection") { save() }.buttonStyle(PrimaryButtonStyle())
            Button("Skip for now") { save(skipped: true) }.font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).foregroundStyle(PauseTheme.muted)
        }.padding(22).frame(maxWidth: 650) } }.foregroundStyle(PauseTheme.ink).toolbar(.hidden, for: .navigationBar)
    }

    private func block<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View { EditorialCard { VStack(alignment: .leading, spacing: 13) { Text(title).font(.headline); content() } } }
    private func save(skipped: Bool = false) {
        guard let draft = model.activeSession else { model.completeReflection(); return }
        let item = IntentionalSession(draft: draft, outcome: skipped ? .skipped : outcome, control: rating >= 4 ? .inControl : rating >= 2 ? .neutral : .distracted)
        item.focusRating = skipped ? 0 : rating; item.mainDistraction = skipped ? "" : distraction.rawValue; item.reflectionNote = skipped ? "" : note; item.nextStep = skipped ? "" : nextStep
        context.insert(item); try? context.save(); model.completeReflection()
    }
}
