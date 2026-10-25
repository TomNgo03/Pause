import SwiftUI
import Charts

struct DemoStoryView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scene = 0
    @State private var playing = true
    private let sceneCount = 17

    var body: some View {
        ZStack {
            PauseTheme.cream.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                Group {
                    switch scene {
                    case 0: opening
                    case 1: designFailure
                    case 2: choice
                    case 3: returnMoment
                    case 4: independence
                    case 5: insight
                    case 6: closing
                    case 7: liveTourIntro
                    case 8: todayTour
                    case 9: reminderTour
                    case 10: reflectionTour
                    case 11: routineBuilderTour
                    case 12: checklistTour
                    case 13: guideTour
                    case 14: independentTour
                    case 15: insightsTour
                    default: finalClose
                    }
                }
                .id(scene)
                .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .frame(maxWidth: 720, maxHeight: .infinity)
                controls
            }
        }
        .foregroundStyle(PauseTheme.ink)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: playing) {
            guard playing else { return }
            while !Task.isCancelled && playing && scene < sceneCount - 1 {
                let delay = scene == 0 ? 6 : (scene == 6 ? 12 : 7)
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled && playing else { return }
                await MainActor.run { withAnimation(.easeInOut(duration: reduceMotion ? 0.15 : 0.65)) { scene += 1 } }
            }
            if scene == sceneCount - 1 { playing = false }
        }
    }

    private var topBar: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) { Image(systemName: "pause.fill"); Text("PAUSE").font(.caption.bold()).tracking(1.8) }.foregroundStyle(PauseTheme.forest)
                Spacer()
                Text("Illustrative walkthrough").font(.caption).foregroundStyle(PauseTheme.muted)
                Button { model.route = .home } label: { Image(systemName: "xmark").frame(width: 40, height: 40).background(PauseTheme.sage, in: Circle()) }.accessibilityLabel("Close product story").accessibilityIdentifier("demo.close")
            }
            GeometryReader { proxy in ZStack(alignment: .leading) { Capsule().fill(PauseTheme.ink.opacity(0.08)); Capsule().fill(PauseTheme.orange).frame(width: proxy.size.width * CGFloat(scene + 1) / CGFloat(sceneCount)) } }.frame(height: 5)
        }.padding(.horizontal, 22).padding(.top, 12)
    }

    private var opening: some View {
        storyPage(kicker: "01 · THE QUESTION", title: "Why was my phone better at selling me something than helping me care for myself?", detail: "Pause began with one routine: check an inhaler before leaving.", symbol: "bell.and.waves.left.and.right.fill")
    }

    private var designFailure: some View {
        VStack(alignment: .leading, spacing: 28) {
            sceneHeader("02 · THE DESIGN FAILED", "The code worked.\nThe reminder did not.")
            EditorialCard {
                VStack(alignment: .leading, spacing: 18) {
                    HStack { PauseIcon(systemName: "exclamationmark", color: .red); VStack(alignment: .leading) { Text("DON’T FORGET!").font(.headline).strikethrough(); Text("Check inhaler before leaving").foregroundStyle(PauseTheme.muted) } }
                    Divider()
                    Text("The notification arrived at the right time—and disappeared with every other message.").font(.title3.bold())
                }
            }
            Label("A technically correct alert can still ignore how people live.", systemImage: "lightbulb.fill").font(.headline).foregroundStyle(PauseTheme.orange)
        }.padding(28)
    }

    private var choice: some View {
        VStack(alignment: .leading, spacing: 24) {
            sceneHeader("03 · REDESIGNED FOR AGENCY", "A prompt should invite,\nnot scold.")
            EditorialCard(color: PauseTheme.forest) {
                VStack(alignment: .leading, spacing: 17) {
                    Text("READY FOR A QUICK CHECK?").font(.caption.bold()).tracking(1.4).foregroundStyle(PauseTheme.sage)
                    Text("Check inhaler before leaving").font(.title.bold()).foregroundStyle(.white)
                    Text("A quick bag or pocket check—without pressure.").foregroundStyle(.white.opacity(0.72))
                    Label("I checked", systemImage: "checkmark.circle.fill").demoButton(color: PauseTheme.sage, foreground: PauseTheme.ink)
                    Label("Choose a better moment", systemImage: "clock.arrow.circlepath").demoButton(color: .white.opacity(0.12), foreground: .white)
                    Text("Not needed today").font(.subheadline.bold()).foregroundStyle(.white.opacity(0.65)).frame(maxWidth: .infinity)
                }
            }
        }.padding(28)
    }

    private var returnMoment: some View {
        VStack(alignment: .leading, spacing: 26) {
            sceneHeader("04 · LATER IS A PLAN", "Pause returns at a moment\nthe user chooses.")
            HStack(spacing: 0) {
                timelinePoint("4:10", "Prompt", true); timelineLine; timelinePoint("4:20", "Homework finished", true); timelineLine; timelinePoint("4:21", "Checked", true)
            }
            EditorialCard(color: PauseTheme.sage) { VStack(alignment: .leading, spacing: 10) { Text("Why this matters").font(.headline); Text("The app did not become more insistent. It gave the person control over when to act.").font(.title3).foregroundStyle(PauseTheme.forest) } }
        }.padding(28)
    }

    private var independence: some View {
        VStack(alignment: .leading, spacing: 22) {
            sceneHeader("05 · GUIDANCE THAT FADES", "Success means needing\nthe app less.")
            HStack(spacing: 12) {
                modeCard("1", "Steps", "Choose the paperclip icon", "list.number")
                Image(systemName: "arrow.right").foregroundStyle(PauseTheme.orange)
                modeCard("2", "Hint", "What symbol adds a file?", "lightbulb")
                Image(systemName: "arrow.right").foregroundStyle(PauseTheme.orange)
                modeCard("3", "Try", "Do it in your own way", "hand.raised")
            }
            Text("“Try it once without me.”").font(.system(size: 30, weight: .bold, design: .serif)).frame(maxWidth: .infinity).padding(.top, 16)
        }.padding(28)
    }

    private var insight: some View {
        VStack(alignment: .leading, spacing: 20) {
            sceneHeader("06 · MEASURE WHAT MATTERS", "A closed reminder is not\nthe same as capability.")
            HStack(spacing: 12) { demoMetric("11", "actions"); demoMetric("4", "independent tries"); demoMetric("75%", "felt prepared") }
            EditorialCard(color: PauseTheme.forest) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("PREPAREDNESS REFLECTIONS").font(.caption.bold()).tracking(1.2).foregroundStyle(PauseTheme.sage)
                    Chart([1, 2, 2, 3, 3, 3], id: \.self) { value in LineMark(x: .value("Moment", value == 1 ? 1 : value == 2 ? 3 : 5), y: .value("Prepared", value)).foregroundStyle(PauseTheme.sage); PointMark(x: .value("Moment", value == 1 ? 1 : value == 2 ? 3 : 5), y: .value("Prepared", value)).foregroundStyle(PauseTheme.orange) }.frame(height: 120).chartXAxis(.hidden).chartYAxis(.hidden)
                    Text("Descriptive reflection—not a medical outcome claim.").font(.caption).foregroundStyle(.white.opacity(0.65))
                }
            }
        }.padding(28)
    }

    private var closing: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack { Circle().fill(PauseTheme.sage).frame(width: 120, height: 120); Image(systemName: "pause.fill").font(.system(size: 44, weight: .bold)).foregroundStyle(PauseTheme.forest) }
            Text("Build for the pause in which\nsomeone decides what to do next.").font(.system(size: 36, weight: .bold, design: .serif)).multilineTextAlignment(.center).tracking(-0.8)
            Text("Private by design · No shame · No diagnosis · No fabricated impact").font(.subheadline).foregroundStyle(PauseTheme.muted).multilineTextAlignment(.center)
            Text("Next: a hands-on product tour").font(.headline).foregroundStyle(PauseTheme.orange)
            Spacer()
        }.padding(28)
    }

    private var liveTourIntro: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("NOW, LET’S USE IT").font(.caption.bold()).tracking(1.6).foregroundStyle(PauseTheme.orange)
            Text("From a reminder\nto independent action.").font(.system(size: 42, weight: .bold, design: .serif)).tracking(-1)
            Text("The next screens demonstrate the working local prototype—not a conceptual mockup.").font(.title3).foregroundStyle(PauseTheme.muted)
            HStack(spacing: 12) { featureChip("Offline", "wifi.slash"); featureChip("Private", "lock.fill"); featureChip("Explainable", "text.magnifyingglass") }
            Spacer()
        }.padding(30)
    }

    private var todayTour: some View {
        VStack(alignment: .leading, spacing: 18) {
            sceneHeader("07 · TODAY", "One calm decision,\nnot a crowded dashboard.")
            HStack { VStack(alignment: .leading) { Text("Good morning,").font(.caption).foregroundStyle(PauseTheme.muted); Text("Huy.").font(.title.bold()) }; Spacer(); Circle().fill(PauseTheme.forest).frame(width: 42, height: 42).overlay(Text("H").foregroundStyle(.white).bold()) }
            EditorialCard(color: PauseTheme.forest) {
                VStack(alignment: .leading, spacing: 13) {
                    Text("READY FOR A QUICK CHECK?").font(.caption.bold()).tracking(1.2).foregroundStyle(PauseTheme.sage)
                    Text("Check inhaler before leaving").font(.title2.bold()).foregroundStyle(.white)
                    Text("Choose what to do").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 13).foregroundStyle(PauseTheme.ink).background(PauseTheme.sage, in: Capsule()).overlay(alignment: .bottomTrailing) { tapPulse }
                }
            }
            Text("A single clear next step reduces cognitive load.").font(.subheadline).foregroundStyle(PauseTheme.muted)
        }.padding(28)
    }

    private var reminderTour: some View {
        VStack(alignment: .leading, spacing: 18) {
            sceneHeader("08 · RESPOND", "The user keeps control.")
            EditorialCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Check inhaler before leaving").font(.title2.bold())
                    Text("Choose what fits this moment. Later is not failure—it is a plan to return.").foregroundStyle(PauseTheme.muted)
                    Label("I checked", systemImage: "checkmark.circle.fill").demoButton(color: PauseTheme.orange, foreground: .white)
                    ZStack(alignment: .bottomTrailing) { Label("Choose a better moment", systemImage: "clock.arrow.circlepath").demoButton(color: PauseTheme.sage, foreground: PauseTheme.ink); tapPulse }
                    HStack { ForEach([5, 10, 30], id: \.self) { Text("\($0)m").font(.caption.bold()).padding(.horizontal, 13).padding(.vertical, 8).background(PauseTheme.paper, in: Capsule()) } }
                }
            }
        }.padding(28)
    }

    private var reflectionTour: some View {
        VStack(alignment: .leading, spacing: 20) {
            sceneHeader("09 · REFLECT", "Completion is not\nthe final question.")
            EditorialCard(color: PauseTheme.sage) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Did this check help you feel prepared?").font(.title2.bold())
                    Text("This separates a dismissed notification from a genuinely useful interaction.").foregroundStyle(PauseTheme.muted)
                    ZStack(alignment: .bottomTrailing) { Text("More prepared").demoButton(color: PauseTheme.orange, foreground: .white); tapPulse }
                    Text("About the same").demoButton(color: PauseTheme.paper, foreground: PauseTheme.ink)
                    Text("Still unsure").demoButton(color: PauseTheme.paper, foreground: PauseTheme.ink)
                }
            }
        }.padding(28)
    }

    private var routineBuilderTour: some View {
        VStack(alignment: .leading, spacing: 18) {
            sceneHeader("10 · BUILD A ROUTINE", "Flexible enough for\nreal life.")
            EditorialCard {
                VStack(alignment: .leading, spacing: 14) {
                    field("Routine", "Get ready to leave", "text.cursor")
                    field("Supportive note", "A quick check—without pressure.", "heart.text.square")
                    field("Reminder", "7:30 AM", "clock")
                    Text("REPEAT").font(.caption.bold()).foregroundStyle(PauseTheme.muted)
                    HStack { ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in Text(day).font(.caption.bold()).foregroundStyle(.white).frame(width: 30, height: 30).background(PauseTheme.forest, in: Circle()) } }
                    Text("Add routine").demoButton(color: PauseTheme.orange, foreground: .white).overlay(alignment: .bottomTrailing) { tapPulse }
                }
            }
        }.padding(28)
    }

    private var checklistTour: some View {
        VStack(alignment: .leading, spacing: 19) {
            sceneHeader("11 · PREPARE", "Move details out of memory\nand into a reusable check.")
            EditorialCard(color: PauseTheme.forest) {
                VStack(alignment: .leading, spacing: 17) {
                    Text("BEFORE LEAVING").font(.caption.bold()).tracking(1.3).foregroundStyle(PauseTheme.sage)
                    checklistRow("Keys", true)
                    checklistRow("Phone", true)
                    checklistRow("Inhaler", false)
                    Text("Preparation creates room to think about something else.").font(.subheadline).foregroundStyle(.white.opacity(0.7)).padding(.top, 8)
                }
            }
        }.padding(28)
    }

    private var guideTour: some View {
        VStack(alignment: .leading, spacing: 20) {
            sceneHeader("12 · PERSONAL GUIDE", "Start with what the person\nwants to accomplish.")
            EditorialCard {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Attach a document to an email").font(.title2.bold())
                    Text("STEP 2 OF 4").font(.caption.bold()).tracking(1.2).foregroundStyle(PauseTheme.orange)
                    PauseIcon(systemName: "paperclip", color: PauseTheme.orange, size: 64).frame(maxWidth: .infinity)
                    Text("Choose the paperclip icon").font(.title3.bold()).frame(maxWidth: .infinity)
                    Text("Next step").demoButton(color: PauseTheme.orange, foreground: .white).overlay(alignment: .bottomTrailing) { tapPulse }
                }
            }
        }.padding(28)
    }

    private var independentTour: some View {
        VStack(alignment: .leading, spacing: 20) {
            sceneHeader("13 · FADE THE SUPPORT", "The interface changes\nas confidence grows.")
            EditorialCard(color: PauseTheme.sage) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("INDEPENDENT MODE").font(.caption.bold()).tracking(1.3).foregroundStyle(PauseTheme.forest)
                    Text("Try the task in your own way.").font(.title2.bold())
                    Text("The guide is still available—but it no longer assumes help is required.").foregroundStyle(PauseTheme.muted)
                    ZStack(alignment: .bottomTrailing) { Label("I did it without help", systemImage: "hand.raised.fill").demoButton(color: PauseTheme.forest, foreground: .white); tapPulse }
                    Text("Show me one hint").demoButton(color: PauseTheme.paper, foreground: PauseTheme.ink)
                }
            }
        }.padding(28)
    }

    private var insightsTour: some View {
        VStack(alignment: .leading, spacing: 17) {
            sceneHeader("14 · EXPLAINABLE INSIGHTS", "Every conclusion can be\ntraced to an action.")
            HStack(spacing: 10) { demoMetric("8", "checked"); demoMetric("4", "postponed"); demoMetric("2", "independent") }
            EditorialCard(color: PauseTheme.forest) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("A TRANSPARENT SUGGESTION").font(.caption.bold()).tracking(1.2).foregroundStyle(PauseTheme.sage)
                    Text("Try moving the evening prompt 10 minutes later.").font(.title3.bold()).foregroundStyle(.white)
                    Text("Several prompts were postponed by about 10 minutes. Pause never changes the time without permission.").font(.caption).foregroundStyle(.white.opacity(0.68))
                }
            }
            Label("No black-box diagnosis. No invented impact.", systemImage: "checkmark.shield.fill").font(.subheadline.bold()).foregroundStyle(PauseTheme.forest)
        }.padding(28)
    }

    private var finalClose: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("PAUSE").font(.caption.bold()).tracking(2).foregroundStyle(PauseTheme.orange)
            Text("Technology that makes\nroom for human agency.").font(.system(size: 40, weight: .bold, design: .serif)).multilineTextAlignment(.center).tracking(-1)
            EditorialCard(color: PauseTheme.sage) { VStack(alignment: .leading, spacing: 10) { Label("Built from lived experience", systemImage: "heart.fill"); Label("Designed through iteration", systemImage: "arrow.triangle.2.circlepath"); Label("Measured with intellectual honesty", systemImage: "chart.line.uptrend.xyaxis"); Label("Private and functional offline", systemImage: "lock.iphone") }.font(.headline).foregroundStyle(PauseTheme.forest) }
            Text("The goal is not to make people obey technology.\nIt is to help them act without it.").font(.title3.bold()).multilineTextAlignment(.center)
            Button("Explore Pause") { model.route = .home }.buttonStyle(PrimaryButtonStyle()).frame(maxWidth: 380)
            Spacer()
        }.padding(28)
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button { if scene > 0 { withAnimation { scene -= 1 } } } label: { Image(systemName: "backward.fill") }.disabled(scene == 0)
            Button { playing.toggle() } label: { Image(systemName: playing ? "pause.fill" : "play.fill").frame(width: 50, height: 50).background(PauseTheme.forest, in: Circle()).foregroundStyle(.white) }
            Button { if scene < sceneCount - 1 { withAnimation { scene += 1 } } else { scene = 0 }; playing = true } label: { Image(systemName: scene == sceneCount - 1 ? "arrow.counterclockwise" : "forward.fill") }
        }.font(.headline).padding(.bottom, 18)
    }

    private func storyPage(kicker: String, title: String, detail: String, symbol: String) -> some View { VStack(alignment: .leading, spacing: 28) { Spacer(); PauseIcon(systemName: symbol, color: PauseTheme.orange, size: 74); Text(kicker).font(.caption.bold()).tracking(1.5).foregroundStyle(PauseTheme.orange); Text(title).font(.system(size: 38, weight: .bold, design: .serif)).tracking(-0.8); Text(detail).font(.title3).foregroundStyle(PauseTheme.muted); Spacer() }.padding(30) }
    private func sceneHeader(_ kicker: String, _ title: String) -> some View { VStack(alignment: .leading, spacing: 8) { Text(kicker).font(.caption.bold()).tracking(1.4).foregroundStyle(PauseTheme.orange); Text(title).font(.system(size: 34, weight: .bold, design: .serif)).tracking(-0.7) } }
    private func timelinePoint(_ time: String, _ label: String, _ filled: Bool) -> some View { VStack(spacing: 8) { Circle().fill(filled ? PauseTheme.orange : PauseTheme.paper).frame(width: 28, height: 28).overlay(Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white)); Text(time).font(.caption.bold()); Text(label).font(.caption2).foregroundStyle(PauseTheme.muted).multilineTextAlignment(.center) }.frame(width: 100) }
    private var timelineLine: some View { Rectangle().fill(PauseTheme.orange.opacity(0.35)).frame(height: 3).frame(maxWidth: .infinity).offset(y: -24) }
    private func modeCard(_ number: String, _ title: String, _ detail: String, _ symbol: String) -> some View { EditorialCard(padding: 14) { VStack(alignment: .leading, spacing: 10) { Text(number).font(.caption.bold()).foregroundStyle(PauseTheme.orange); Image(systemName: symbol).font(.title2); Text(title).font(.headline); Text(detail).font(.caption).foregroundStyle(PauseTheme.muted).lineLimit(3) } }.frame(maxWidth: .infinity) }
    private func demoMetric(_ value: String, _ label: String) -> some View {
        EditorialCard(padding: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(value).font(.title.bold()).monospacedDigit()
                Text(label).font(.caption).foregroundStyle(PauseTheme.muted).lineLimit(1).minimumScaleFactor(0.62)
            }
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
    private var tapPulse: some View { ZStack { Circle().fill(PauseTheme.orange.opacity(0.18)).frame(width: 54, height: 54); Circle().fill(PauseTheme.orange).frame(width: 18, height: 18).overlay(Circle().stroke(.white, lineWidth: 3)) }.offset(x: 10, y: 16).accessibilityHidden(true) }
    private func featureChip(_ title: String, _ symbol: String) -> some View { Label(title, systemImage: symbol).font(.caption.bold()).padding(.horizontal, 12).padding(.vertical, 9).background(PauseTheme.sage, in: Capsule()) }
    private func field(_ label: String, _ value: String, _ symbol: String) -> some View { VStack(alignment: .leading, spacing: 5) { Text(label.uppercased()).font(.caption2.bold()).foregroundStyle(PauseTheme.muted); Label(value, systemImage: symbol).font(.subheadline.weight(.semibold)).padding(12).frame(maxWidth: .infinity, alignment: .leading).background(PauseTheme.cream, in: RoundedRectangle(cornerRadius: 12)) } }
    private func checklistRow(_ title: String, _ checked: Bool) -> some View { HStack { Image(systemName: checked ? "checkmark.circle.fill" : "circle").foregroundStyle(checked ? PauseTheme.sage : .white.opacity(0.5)); Text(title).font(.headline).foregroundStyle(.white); Spacer(); if !checked { tapPulse.scaleEffect(0.7) } }.padding(.vertical, 5) }
}

private extension View {
    func demoButton(color: Color, foreground: Color) -> some View { self.font(.headline).foregroundStyle(foreground).frame(maxWidth: .infinity).padding(.vertical, 13).background(color, in: Capsule()) }
}
