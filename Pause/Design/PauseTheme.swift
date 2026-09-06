import SwiftUI

enum PauseTheme {
    static let ink = Color(red: 0.035, green: 0.045, blue: 0.09)
    static let indigo = Color(red: 0.43, green: 0.38, blue: 1.0)
    static let violet = Color(red: 0.72, green: 0.31, blue: 0.96)
    static let mint = Color(red: 0.25, green: 0.87, blue: 0.70)
    static let coral = Color(red: 1.0, green: 0.42, blue: 0.49)
    static let sky = Color(red: 0.29, green: 0.70, blue: 1.0)
    static let background = Color(red: 0.035, green: 0.045, blue: 0.09)
    static let card = Color(red: 0.075, green: 0.09, blue: 0.16)
    static let elevated = Color(red: 0.105, green: 0.12, blue: 0.20)
    static let heroGradient = LinearGradient(colors: [indigo, violet], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let socialGradient = LinearGradient(colors: [mint, sky], startPoint: .topLeading, endPoint: .bottomTrailing)
}

struct PauseBackground: View {
    var body: some View {
        ZStack {
            PauseTheme.background.ignoresSafeArea()
            Circle().fill(PauseTheme.violet.opacity(0.19)).frame(width: 360).blur(radius: 70).offset(x: 190, y: -360)
            Circle().fill(PauseTheme.indigo.opacity(0.14)).frame(width: 320).blur(radius: 80).offset(x: -190, y: 220)
            Circle().fill(PauseTheme.mint.opacity(0.06)).frame(width: 260).blur(radius: 75).offset(x: 170, y: 430)
        }.accessibilityHidden(true)
    }
}

struct PauseCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content
    var body: some View {
        content.frame(maxWidth: .infinity, alignment: .leading).padding(padding)
            .background(PauseTheme.card.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(.white.opacity(0.08), lineWidth: 0.8))
            .shadow(color: .black.opacity(0.22), radius: 20, y: 10)
    }
}

struct PauseIcon: View {
    let systemName: String
    var color: Color = PauseTheme.indigo
    var size: CGFloat = 46
    var body: some View {
        Image(systemName: systemName).font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(color).frame(width: size, height: size)
            .background(color.opacity(0.16), in: RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
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
            .shadow(color: PauseTheme.indigo.opacity(configuration.isPressed ? 0.16 : 0.38), radius: 18, y: 9)
            .scaleEffect(configuration.isPressed ? 0.98 : 1).animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 13)
            .foregroundStyle(.white).background(PauseTheme.elevated.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white.opacity(0.10)))
    }
}
