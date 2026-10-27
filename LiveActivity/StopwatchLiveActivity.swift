import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Lock Screen and Dynamic Island, in the standard system look.
struct StopwatchLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StopwatchAttributes.self) { context in
            LockScreenView(state: context.state)
                .padding(16)
                .activityBackgroundTint(nil)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "stopwatch")
                        .font(.title2)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        TimeText(state: context.state)
                            .font(.system(size: 40, weight: .semibold).monospacedDigit())
                        if !context.state.isRunning {
                            Text("Paused").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ControlButtons(state: context.state)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: "stopwatch")
            } compactTrailing: {
                TimeText(state: context.state)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 56, alignment: .trailing)
            } minimal: {
                Image(systemName: "stopwatch")
            }
        }
    }
}

/// Live system timer text while running (iOS updates it on its own); frozen text while paused.
struct TimeText: View {
    let state: StopwatchAttributes.ContentState

    var body: some View {
        if state.isRunning {
            let start = state.timerStart
            Text(timerInterval: start...start.addingTimeInterval(60 * 60 * 24 * 365), countsDown: false)
        } else {
            Text(state.frozenText)
        }
    }
}

struct LockScreenView: View {
    let state: StopwatchAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "stopwatch")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 0) {
                TimeText(state: state)
                    .font(.system(size: 44, weight: .semibold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if !state.isRunning {
                    Text("Paused").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            ControlButtons(state: state)
        }
    }
}

struct ControlButtons: View {
    let state: StopwatchAttributes.ContentState

    var body: some View {
        HStack(spacing: 10) {
            if state.isRunning {
                Button(intent: PauseStopwatchIntent()) {
                    Image(systemName: "pause.fill").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Pause")
            } else {
                Button(intent: ResumeStopwatchIntent()) {
                    Image(systemName: "play.fill").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Resume")
                Button(intent: ResetStopwatchIntent()) {
                    Image(systemName: "stop.fill").frame(width: 44, height: 44)
                }
                .accessibilityLabel("Reset")
            }
        }
        .font(.title3)
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .tint(.primary)
    }
}

#Preview("Lock Screen", as: .content, using: StopwatchAttributes()) {
    StopwatchLiveActivity()
} contentStates: {
    StopwatchAttributes.ContentState(isRunning: true, accumulated: 42, runStart: .now)
    StopwatchAttributes.ContentState(isRunning: false, accumulated: 462, runStart: nil)
}
