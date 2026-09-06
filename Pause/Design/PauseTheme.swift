import SwiftUI

enum PauseTheme {
    static let ink = Color(red: 0.09, green: 0.10, blue: 0.18)
    static let indigo = Color(red: 0.29, green: 0.25, blue: 0.78)
    static let violet = Color(red: 0.55, green: 0.32, blue: 0.90)
    static let mint = Color(red: 0.31, green: 0.78, blue: 0.65)
    static let coral = Color(red: 0.98, green: 0.50, blue: 0.46)
    static let sky = Color(red: 0.39, green: 0.67, blue: 0.98)
    static let background = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let heroGradient = LinearGradient(colors: [indigo, violet], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct PauseBackground: View {
    var body: some View {
        ZStack {
            PauseTheme.background.ignoresSafeArea()
            Circle().fill(PauseTheme.violet.opacity(0.10)).frame(width: 320).blur(radius: 18).offset(x: 150, y: -320)
            Circle().fill(PauseTheme.mint.opacity(0.08)).frame(width: 260).blur(radius: 24).offset(x: -170, y: 350)
        }.accessibilityHidden(true)
    }
}

struct PauseCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content
    var body: some View {
        content.frame(maxWidth: .infinity, alignment: .leading).padding(padding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.45), lineWidth: 0.7))
            .shadow(color: PauseTheme.ink.opacity(0.06), radius: 18, y: 8)
    }
}

struct PauseIcon: View {
    let systemName: String
    var color: Color = PauseTheme.indigo
    var size: CGFloat = 46
    var body: some View {
        Image(systemName: systemName).font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(color).frame(width: size, height: size)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
    }
}

struct PauseSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title3.weight(.bold))
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer()
            if let action { Button(action: action) { Image(systemName: "plus").font(.subheadline.bold()).frame(width: 32, height: 32).background(PauseTheme.indigo.opacity(0.12), in: Circle()) }.accessibilityLabel("Add \(title)") }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16)
            .foregroundStyle(.white).background(PauseTheme.heroGradient, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .opacity(configuration.isPressed ? 0.78 : 1)
            .shadow(color: PauseTheme.indigo.opacity(configuration.isPressed ? 0.12 : 0.25), radius: 14, y: 7)
            .scaleEffect(configuration.isPressed ? 0.98 : 1).animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 13)
            .foregroundStyle(PauseTheme.indigo).background(PauseTheme.indigo.opacity(configuration.isPressed ? 0.16 : 0.09), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}
