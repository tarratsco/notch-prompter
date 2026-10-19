import NotchPrompterCore
import SwiftUI

struct PrompterPanelView: View {
    @ObservedObject var model: TeleprompterViewModel
    let expansionChanged: () -> Void
    let openEditor: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shell: NotchShellShape {
        NotchShellShape(
            attachedToScreenEdge: model.panelTopInset > 0,
            bottomRadius: model.isPanelExpanded ? 16 : 12
        )
    }

    private var chromeHorizontalPadding: CGFloat {
        model.panelTopInset > 0 ? 32 : 12
    }

    var body: some View {
        Group {
            if model.isPanelExpanded {
                expandedPanel
            } else {
                collapsedPanel
            }
        }
        .background(Color.black)
        .clipShape(shell)
        .contentShape(shell)
        .overlay(
            shell
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .preferredColorScheme(.dark)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: model.isPanelExpanded)
    }

    private var collapsedPanel: some View {
        HStack(spacing: 10) {
            TransportButton(systemName: "house.fill", label: "Open editor") {
                openEditor()
            }
            StatusChip(text: collapsedStatus, active: model.isPlaying || model.countdownValue != nil)
            Spacer(minLength: 2)
            TransportButton(
                systemName: model.isPlaying || model.countdownValue != nil ? "pause.fill" : "play.fill",
                label: model.isPlaying || model.countdownValue != nil ? "Pause" : "Play",
                prominent: !(model.isPlaying || model.countdownValue != nil)
            ) {
                model.togglePlayback()
            }
            TransportButton(systemName: "chevron.down", label: "Expand panel") {
                model.isPanelExpanded = true
                expansionChanged()
            }
        }
        .padding(.horizontal, chromeHorizontalPadding)
        .frame(height: 50)
    }

    private var collapsedStatus: String {
        if let value = model.countdownValue { return "\(value)" }
        return model.statusText
    }

    private var expandedPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                TransportButton(systemName: "house.fill", label: "Open editor") {
                    openEditor()
                }
                StatusChip(text: model.statusText, active: model.isPlaying || model.countdownValue != nil)
                Spacer()
                TransportButton(
                    systemName: model.isPlaying || model.countdownValue != nil ? "pause.fill" : "play.fill",
                    label: model.isPlaying || model.countdownValue != nil ? "Pause" : "Play",
                    prominent: !(model.isPlaying || model.countdownValue != nil)
                ) {
                    model.togglePlayback()
                }
                TransportButton(systemName: "chevron.up", label: "Collapse panel") {
                    model.isPanelExpanded = false
                    expansionChanged()
                }
            }
            .padding(.horizontal, chromeHorizontalPadding)
            .frame(height: 52)

            Rectangle()
                .fill(StudioTheme.separator)
                .frame(height: 1)

            GeometryReader { geometry in
                ZStack {
                    VisualLinePromptView(
                        text: model.scriptText,
                        fontSize: model.fontSize,
                        scrollOffset: model.scrollOffset,
                        manualNavigationRevision: model.manualNavigationRevision,
                        onLayout: { metrics in
                            model.updateLayout(metrics)
                        },
                        onManualScroll: { points in
                            model.seek(byPoints: Double(points))
                        }
                    )

                    if model.scriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "text.alignleft")
                                .foregroundStyle(StudioTheme.secondary)
                            Text("Add a script in the editor")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(StudioTheme.secondary)
                        }
                    }

                    HStack(spacing: 0) {
                        Rectangle().fill(StudioTheme.live).frame(width: 13, height: 2)
                        Rectangle().fill(StudioTheme.live.opacity(0.28)).frame(height: 1)
                        Rectangle().fill(StudioTheme.live).frame(width: 13, height: 2)
                    }
                    .frame(width: geometry.size.width)
                    .position(
                        x: geometry.size.width / 2,
                        y: ReadingGuide.position(in: geometry.size.height)
                    )
                    .accessibilityHidden(true)
                }
                .clipped()
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.black.opacity(0.74))
                        .frame(height: 22)
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.black.opacity(0.74))
                        .frame(height: 22)
                        .allowsHitTesting(false)
                }
            }

            Rectangle()
                .fill(StudioTheme.separator)
                .frame(height: 1)

            HStack(spacing: 8) {
                TransportButton(systemName: "backward.end.fill", label: "Reset") {
                    model.reset()
                }
                Rectangle()
                    .fill(StudioTheme.separator)
                    .frame(width: 1, height: 22)
                    .padding(.horizontal, 2)
                    .accessibilityHidden(true)
                TransportButton(systemName: "arrow.up", label: "Previous line") {
                    model.stepVisualLine(-1)
                }
                .disabled(!model.canSeekBackward)
                TransportButton(systemName: "arrow.down", label: "Next line") {
                    model.stepVisualLine(1)
                }
                .disabled(!model.canSeekForward)
                Spacer()
                Text("\(Int(model.wordsPerMinute.rounded())) WPM  ·  \(String(format: "%.1f×", model.speedMultiplier))")
                    .font(.system(size: 10, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(StudioTheme.secondary)
                Slider(
                    value: Binding(
                        get: { model.progress },
                        set: { model.seek(toProgress: $0) }
                    ),
                    in: 0...1
                )
                    .tint(StudioTheme.live)
                    .frame(width: 150)
                    .disabled(model.maximumScrollOffset <= 0)
                    .accessibilityLabel("Script progress")
                    .accessibilityValue("\(Int(model.progress * 100)) percent")
            }
            .padding(.horizontal, chromeHorizontalPadding)
            .frame(height: 56)
        }
        .overlay {
            if let value = model.countdownValue {
                ZStack {
                    Color.black.opacity(0.94)
                    Text("\(value)")
                        .font(.system(size: 118, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(StudioTheme.live)
                        .contentTransition(reduceMotion ? .identity : .numericText())
                        .accessibilityLabel("Starting in \(value)")
                }
                .allowsHitTesting(false)
            }
        }
    }
}
