import SwiftUI

enum PauseTheme {
    static let cream = Color(red: 0.973, green: 0.965, blue: 0.925)
    static let paper = Color(red: 0.995, green: 0.99, blue: 0.965)
    static let ink = Color(red: 0.035, green: 0.067, blue: 0.047)
    static let forest = Color(red: 0.12, green: 0.23, blue: 0.16)
    static let sage = Color(red: 0.78, green: 0.82, blue: 0.72)
    static let muted = Color(red: 0.32, green: 0.37, blue: 0.33)
    static let orange = Color(red: 0.75, green: 0.29, blue: 0.12)
    static let coral = Color(red: 0.88, green: 0.42, blue: 0.23)
    static let indigo = Color(red: 0.18, green: 0.14, blue: 0.48)
    static let violet = Color(red: 0.42, green: 0.30, blue: 0.72)
    static let mint = Color(red: 0.55, green: 0.84, blue: 0.66)
    static let sky = Color(red: 0.32, green: 0.62, blue: 0.78)
    static let background = cream
    static let card = paper
    static let elevated = Color.white.opacity(0.72)
    static let heroGradient = LinearGradient(colors: [orange, coral], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let socialGradient = LinearGradient(colors: [forest, sage], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct PauseBackground: View {
    var body: some View { PauseTheme.cream.ignoresSafeArea().accessibilityHidden(true) }
}

struct EditorialCard<Content: View>: View {
    var color: Color = PauseTheme.paper
    var padding: CGFloat = 20
    @ViewBuilder var content: Content
    var body: some View {
        content.frame(maxWidth: .infinity, alignment: .leading).padding(padding)
            .background(color, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(PauseTheme.ink.opacity(0.08)))
    }
}

typealias PauseCard = EditorialCard

struct PauseIcon: View {
    let systemName: String
    var color: Color = PauseTheme.orange
    var size: CGFloat = 46
    var body: some View {
        Image(systemName: systemName).font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(color).frame(width: size, height: size)
            .background(color.opacity(0.13), in: Circle())
    }
}

struct PauseSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.title2.weight(.bold)).foregroundStyle(PauseTheme.ink)
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(PauseTheme.muted) }
            }
            Spacer()
            if let action { Button(action: action) { Image(systemName: "plus").frame(width: 36, height: 36).background(PauseTheme.sage, in: Circle()) } }
        }
    }
}

struct MetricPill: View {
    let value: String
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.title3.bold()).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(PauseTheme.muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16)
            .foregroundStyle(.white).background(PauseTheme.orange, in: Capsule())
            .opacity(configuration.isPressed ? 0.78 : 1).scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 13)
            .foregroundStyle(PauseTheme.ink).background(PauseTheme.sage.opacity(configuration.isPressed ? 0.6 : 1), in: Capsule())
    }
}
