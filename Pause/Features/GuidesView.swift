import SwiftUI

struct GuidesView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selected: PersonalGuide?

    var body: some View {
        ZStack { PauseBackground(); ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                PauseSectionHeader(title: "Try it yourself", subtitle: "Short guides designed to become less necessary over time.")
                EditorialCard(color: PauseTheme.forest) { VStack(alignment: .leading, spacing: 10) { Text("GUIDANCE, NOT CONTROL").font(.caption.bold()).tracking(1.4).foregroundStyle(PauseTheme.sage); Text("The goal is not to follow instructions forever. It is to feel able to act without them.").font(.title3.bold()).foregroundStyle(.white) } }
                ForEach(model.care.guides) { guide in
                    Button { selected = guide } label: {
                        EditorialCard { HStack { VStack(alignment: .leading, spacing: 6) { Text(guide.title).font(.headline); Text(guide.purpose).font(.caption).foregroundStyle(PauseTheme.muted); if guide.practiceCount > 0 { Text("Tried independently \(guide.practiceCount) time\(guide.practiceCount == 1 ? "" : "s")").font(.caption.bold()).foregroundStyle(PauseTheme.forest) } }; Spacer(); Image(systemName: "arrow.up.right").foregroundStyle(PauseTheme.orange) } }
                    }.buttonStyle(.plain)
                }
            }.padding(20).padding(.bottom, 30)
        }}.toolbar(.hidden, for: .navigationBar).sheet(item: $selected) { GuidePracticeView(guide: $0) }
    }
}

private struct GuidePracticeView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let guide: PersonalGuide
    @State private var step = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("STEP \(min(step + 1, guide.steps.count)) OF \(guide.steps.count)").font(.caption.bold()).tracking(1.4).foregroundStyle(PauseTheme.orange)
            Text(guide.title).font(.system(size: 32, weight: .bold, design: .serif))
            if step < guide.steps.count {
                Text(guide.steps[step]).font(.title2.weight(.semibold)).frame(maxHeight: .infinity, alignment: .center)
                Button(step == guide.steps.count - 1 ? "I did it" : "Next step") { if step < guide.steps.count - 1 { withAnimation { step += 1 } } else { model.care.practiced(guide); dismiss() } }.buttonStyle(PrimaryButtonStyle())
            }
            Button("Try once without the guide") { model.care.practiced(guide); dismiss() }.buttonStyle(SoftButtonStyle())
        }.padding(26).presentationDetents([.large]).background(PauseTheme.cream)
    }
}
