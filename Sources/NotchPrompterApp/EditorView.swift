import AppKit
import NotchPrompterCore
import SwiftUI
import UniformTypeIdentifiers

struct EditorView: View {
    @ObservedObject var model: TeleprompterViewModel
    @ObservedObject var commands: AppCommands

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Divider().overlay(StudioTheme.separator)
            HSplitView {
                scriptWorkspace
                    .frame(minWidth: 480, idealWidth: 680)
                controlRail
                    .frame(minWidth: 286, idealWidth: 320, maxWidth: 360)
            }
        }
        .frame(minWidth: 820, minHeight: 570)
        .background(StudioTheme.canvas)
        .preferredColorScheme(.dark)
        .tint(StudioTheme.live)
        .alert(
            "Couldn’t Load Script",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var titleBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Notch Prompter")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(StudioTheme.text)
                Text("Broadcast cue console")
                    .font(.system(size: 11))
                    .foregroundStyle(StudioTheme.secondary)
            }

            Spacer()
            StatusChip(text: model.statusText, active: model.isPlaying || model.countdownValue != nil)

            Button(action: commands.openDocument) {
                Label("Open Script", systemImage: "doc.badge.plus")
            }
            .buttonStyle(StudioButtonStyle())
            .keyboardShortcut("o", modifiers: .command)
            .help("Open a UTF-8 text or Markdown file")

            Button {
                model.isPanelVisible.toggle()
                commands.togglePanelVisibility()
            } label: {
                Label(model.isPanelVisible ? "Hide Panel" : "Show Panel",
                      systemImage: model.isPanelVisible ? "eye.slash" : "eye")
            }
            .buttonStyle(StudioButtonStyle())
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
        .background(StudioTheme.raised)
    }

    private var scriptWorkspace: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Script")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(StudioTheme.text)
                Text("\(model.wordCount) words")
                    .font(.system(size: 11, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(StudioTheme.secondary)
                Spacer()
                if !model.scriptText.isEmpty {
                    Button("Clear") { model.scriptText = "" }
                        .buttonStyle(.plain)
                        .foregroundStyle(StudioTheme.secondary)
                        .help("Clear the script")
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 12)

            ZStack {
                TextEditor(text: $model.scriptText)
                    .font(.system(size: 17))
                    .lineSpacing(5)
                    .foregroundStyle(StudioTheme.text)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 12)
                    .accessibilityLabel("Teleprompter script")

                if model.scriptText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(StudioTheme.secondary)
                        Text("Paste, type, open, or drop a script")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(StudioTheme.text)
                        Button("Use Sample Script") {
                            model.scriptText = TeleprompterViewModel.sampleScript
                        }
                        .buttonStyle(StudioButtonStyle())
                    }
                    .allowsHitTesting(true)
                }
            }
            .background(StudioTheme.raised)
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(StudioTheme.separator, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
            .onDrop(of: [UTType.fileURL.identifier], isTargeted: nil, perform: handleDrop)
        }
        .background(StudioTheme.canvas)
    }

    private var controlRail: some View {
        VStack(spacing: 0) {
            preview
            Divider().overlay(StudioTheme.separator)
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    transport
                    setting(
                        title: "Reading pace",
                        value: "\(Int(model.wordsPerMinute.rounded()))",
                        unit: "WPM"
                    ) {
                        Slider(value: $model.wordsPerMinute, in: PlaybackMath.wordsPerMinuteRange, step: 5)
                            .accessibilityLabel("Words per minute")
                    }
                    setting(
                        title: "Speed trim",
                        value: String(format: "%.1f×", model.speedMultiplier),
                        unit: "RATE"
                    ) {
                        Slider(value: $model.speedMultiplier, in: PlaybackMath.speedMultiplierRange, step: 0.1)
                            .accessibilityLabel("Speed multiplier")
                    }
                    setting(
                        title: "Prompt size",
                        value: "\(Int(model.fontSize.rounded()))",
                        unit: "PT"
                    ) {
                        Slider(value: $model.fontSize, in: PlaybackMath.fontSizeRange, step: 2)
                            .accessibilityLabel("Prompter font size")
                    }

                    Toggle("3-second cue before play", isOn: $model.countdownEnabled)
                        .toggleStyle(.switch)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(StudioTheme.text)
                        .accessibilityHint("Shows 3, 2, 1 at the notch before scrolling")

                    Divider().overlay(StudioTheme.separator)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("NOTCH PANEL")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(1.1)
                            .foregroundStyle(StudioTheme.secondary)
                        Button {
                            model.isPanelExpanded.toggle()
                            commands.panelExpansionChanged()
                        } label: {
                            Label(model.isPanelExpanded ? "Collapse Panel" : "Expand Panel",
                                  systemImage: model.isPanelExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(StudioButtonStyle())
                    }
                }
                .padding(20)
            }
        }
        .background(StudioTheme.raised)
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LIVE PREVIEW")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(StudioTheme.secondary)
                Spacer()
                Text("\(Int((model.progress * 100).rounded()))%")
                    .font(.system(size: 10, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(StudioTheme.secondary)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black)
                Rectangle()
                    .fill(StudioTheme.live.opacity(0.55))
                    .frame(height: 1)
                Text(previewText)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(StudioTheme.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(20)
            }
            .frame(height: 126)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(StudioTheme.separator, lineWidth: 1)
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Teleprompter preview")
            .accessibilityValue(previewText)
        }
        .padding(20)
    }

    private var previewText: String {
        let cleaned = model.scriptText.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Your script preview appears here." : String(cleaned.prefix(180))
    }

    private var transport: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("TRANSPORT")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.1)
                    .foregroundStyle(StudioTheme.secondary)
                Spacer()
                if model.estimatedDuration > 0 {
                    Text(formattedDuration)
                        .font(.system(size: 11, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(StudioTheme.secondary)
                }
            }
            HStack(spacing: 8) {
                Button {
                    model.togglePlayback()
                } label: {
                    Label(model.isPlaying || model.countdownValue != nil ? "Pause" : "Play",
                          systemImage: model.isPlaying || model.countdownValue != nil ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(StudioButtonStyle(prominent: !(model.isPlaying || model.countdownValue != nil)))

                TransportButton(systemName: "backward.end.fill", label: "Reset") {
                    model.reset()
                }
            }
        }
    }

    private var formattedDuration: String {
        let total = Int(model.estimatedDuration.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    private func setting<Content: View>(
        title: String,
        value: String,
        unit: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(StudioTheme.text)
                Spacer()
                MeasurementLabel(value: value, unit: unit)
            }
            control()
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            model.errorMessage = "Drop a UTF-8 .txt or .md file."
            return false
        }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            DispatchQueue.main.async {
                if let error {
                    model.errorMessage = "The dropped file could not be opened: \(error.localizedDescription)"
                    return
                }
                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else {
                    url = item as? URL
                }
                guard let url else {
                    model.errorMessage = "The dropped item is not a readable file."
                    return
                }
                model.loadScript(from: url)
            }
        }
        return true
    }
}
