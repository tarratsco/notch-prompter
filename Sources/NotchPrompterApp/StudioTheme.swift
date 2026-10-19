import SwiftUI

enum StudioTheme {
    static let canvas = Color(red: 0.055, green: 0.055, blue: 0.06)
    static let raised = Color(red: 0.09, green: 0.09, blue: 0.10)
    static let control = Color(red: 0.14, green: 0.135, blue: 0.14)
    static let separator = Color.white.opacity(0.12)
    static let text = Color(red: 0.96, green: 0.93, blue: 0.87)
    static let secondary = Color(red: 0.65, green: 0.62, blue: 0.57)
    static let live = Color(red: 0.78, green: 0.08, blue: 0.06)
}

struct NotchShellShape: Shape {
    let attachedToScreenEdge: Bool
    let bottomRadius: CGFloat
    var shoulderDepth: CGFloat = 20

    func path(in rect: CGRect) -> Path {
        guard attachedToScreenEdge else {
            return RoundedRectangle(cornerRadius: bottomRadius, style: .continuous)
                .path(in: rect)
        }

        let shoulder = min(shoulderDepth, rect.width / 4, rect.height / 2)
        let bottom = min(bottomRadius, rect.width / 4, rect.height / 3)
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX - shoulder, y: rect.minY + shoulder),
            control1: CGPoint(x: rect.maxX - shoulder * 0.55, y: rect.minY),
            control2: CGPoint(x: rect.maxX - shoulder, y: rect.minY + shoulder * 0.45)
        )
        path.addLine(to: CGPoint(x: rect.maxX - shoulder, y: rect.maxY - bottom))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - shoulder - bottom, y: rect.maxY),
            control: CGPoint(x: rect.maxX - shoulder, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + shoulder + bottom, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + shoulder, y: rect.maxY - bottom),
            control: CGPoint(x: rect.minX + shoulder, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + shoulder, y: rect.minY + shoulder))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control1: CGPoint(x: rect.minX + shoulder, y: rect.minY + shoulder * 0.45),
            control2: CGPoint(x: rect.minX + shoulder * 0.55, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

struct StudioButtonStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        StudioButtonBody(
            configuration: configuration,
            prominent: prominent
        )
    }

    private struct StudioButtonBody: View {
        let configuration: ButtonStyle.Configuration
        let prominent: Bool
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(prominent ? Color.white : StudioTheme.text)
            .padding(.horizontal, 13)
            .frame(minHeight: 32)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(prominent ? StudioTheme.live : StudioTheme.control)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.22 : 0.1), lineWidth: 1)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.76 : 1) : 0.34)
        }
    }
}

struct TransportButton: View {
    let systemName: String
    let label: String
    var prominent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 34, height: 32)
        }
        .buttonStyle(StudioButtonStyle(prominent: prominent))
        .accessibilityLabel(label)
    }
}

struct MeasurementLabel: View {
    let value: String
    let unit: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(StudioTheme.text)
            Text(unit.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(StudioTheme.secondary)
        }
    }
}

struct StatusChip: View {
    let text: String
    let active: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(active ? StudioTheme.live : StudioTheme.secondary.opacity(0.65))
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(active ? StudioTheme.text : StudioTheme.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Prompter status: \(text)")
    }
}
