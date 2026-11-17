import SwiftUI

/// Start (Idle), Pause (Running), or Play + Stop with the "Paused" label (Paused).
struct ControlsView: View {
    @Environment(StopwatchModel.self) private var model
    @Environment(AppSettings.self) private var settings
    let layout: Layout

    var body: some View {
        let s = layout.s
        VStack(spacing: 0) {
            Group {
                switch model.state.phase {
                case .idle:
                    wideButton("Start", fill: .start, text: .startText) { model.start() }
                case .running:
                    wideButton("Pause", fill: .pause, text: .pauseText) { model.pause() }
                case .paused:
                    HStack(spacing: 15 * s) {
                        Button { model.resume() } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 40 * s, weight: .bold))
                                .foregroundStyle(settings.color(.playIcon))
                                .frame(width: 133 * s, height: Layout.buttonHeight * s)
                                .background(settings.color(.play), in: RoundedRectangle(cornerRadius: settings.style.buttonRadius * s))
                        }
                        .accessibilityLabel("Resume")

                        Button { model.reset() } label: {
                            Rectangle()
                                .fill(settings.color(.stopIcon))
                                .frame(width: 32 * s, height: 32 * s)
                                .frame(width: 134 * s, height: Layout.buttonHeight * s)
                                .background(settings.color(.stop), in: RoundedRectangle(cornerRadius: settings.style.buttonRadius * s))
                        }
                        .accessibilityLabel("Reset")
                    }
                }
            }
            .buttonStyle(PressDimStyle())
            .frame(height: Layout.buttonHeight * s)

            Text("Paused")
                .font(.system(size: 48 * s, weight: .bold))
                .foregroundStyle(settings.color(.pause))
                .frame(height: Layout.pausedHeight * s)
                .padding(.top, Layout.pausedGap * s)
                .opacity(model.state.phase == .paused ? 1 : 0)
                .accessibilityHidden(model.state.phase != .paused)
        }
    }

    private func wideButton(_ title: String, fill: ColorSetting, text: ColorSetting, action: @escaping () -> Void) -> some View {
        let s = layout.s
        return Button(action: action) {
            Text(title)
                .font(.system(size: 40 * s, weight: .bold))
                .foregroundStyle(settings.color(text))
                .frame(width: 282 * s, height: Layout.buttonHeight * s)
                .background(settings.color(fill), in: RoundedRectangle(cornerRadius: settings.style.buttonRadius * s))
        }
        .accessibilityLabel(title)
    }
}

/// The Customize and Done icon buttons at the bottom center, shaped like the dial style's buttons.
struct IconButton: View {
    @Environment(AppSettings.self) private var settings
    let systemImage: String
    let label: String
    let layout: Layout
    let action: () -> Void

    static let referenceWidth: CGFloat = 80
    static let minimumTarget: CGFloat = 44

    var body: some View {
        let s = layout.s
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22 * s, weight: .semibold))
                .foregroundStyle(settings.color(.customizeText))
                .frame(width: max(Self.minimumTarget, Self.referenceWidth * s),
                       height: max(Self.minimumTarget, Layout.pillHeight * s))
                .background(settings.color(.customize),
                            in: RoundedRectangle(cornerRadius: settings.style.buttonRadius * s))
                .contentShape(Rectangle())
        }
        .buttonStyle(PressDimStyle())
        .accessibilityLabel(label)
    }
}

/// Visual press feedback only: no sounds, no haptics.
struct PressDimStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
