import SwiftUI

struct MainView: View {
    @Environment(StopwatchModel.self) private var model
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase

    @State private var showCustomize = false
    @State private var screenAwake = ScreenAwakeController()

    var body: some View {
        GeometryReader { geo in
            let layout = Layout(width: geo.size.width, height: geo.size.height)
            ZStack(alignment: .bottom) {
                if showCustomize {
                    CustomizeView(layout: layout)
                } else {
                    stopwatch(layout)
                }
                PillButton(title: showCustomize ? "Main Menu" : "Customize", layout: layout) {
                    showCustomize.toggle()
                }
                .padding(.bottom, Layout.bottomPad * layout.s)
                // Customize is only reachable from Idle. Keep its space so nothing shifts.
                .opacity(showCustomize || model.state.phase == .idle ? 1 : 0)
                .disabled(!(showCustomize || model.state.phase == .idle))
                .accessibilityHidden(!(showCustomize || model.state.phase == .idle))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(settings.color(.background).ignoresSafeArea())
        .background(TouchObserver { screenAwake.touched() })
        .preferredColorScheme(settings.backgroundIsDark ? .dark : .light)
        .onChange(of: holdInputs, initial: true) { _, inputs in
            screenAwake.update(eligible: inputs.eligible, minutes: inputs.minutes)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.refreshLiveActivity() }
        }
    }

    private func stopwatch(_ layout: Layout) -> some View {
        VStack(spacing: 0) {
            DialView(elapsed: { model.elapsed(at: $0) },
                     isRunning: model.state.phase == .running,
                     colors: DialColors(background: settings.color(.background),
                                        fontTicks: settings.color(.fontTicks),
                                        secondHand: settings.color(.secondHand)))
                .frame(width: 390 * layout.dialScale, height: 414 * layout.dialScale)
            ControlsView(layout: layout)
                .padding(.top, Layout.dialGap * layout.s)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private struct HoldInputs: Equatable {
        var eligible: Bool
        var minutes: Int
    }

    /// The hold applies only while Running or Paused, on the main screen, with the app in front.
    private var holdInputs: HoldInputs {
        HoldInputs(eligible: model.state.phase != .idle && !showCustomize && scenePhase == .active,
                   minutes: settings.dimMinutes)
    }
}
