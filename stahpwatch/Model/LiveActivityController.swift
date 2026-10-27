import ActivityKit
import Foundation

/// Starts, updates and ends the stopwatch's Live Activity.
@MainActor
final class LiveActivityController {
    func sync(to state: StopwatchState) async {
        let live = Activity<StopwatchAttributes>.activities.filter {
            $0.activityState == .active || $0.activityState == .stale
        }

        guard state.phase != .idle else {
            for activity in Activity<StopwatchAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            return
        }

        let content = ActivityContent(
            state: StopwatchAttributes.ContentState(
                isRunning: state.phase == .running,
                accumulated: state.accumulated,
                runStart: state.runStart
            ),
            staleDate: nil
        )

        if let current = live.first {
            await current.update(content)
            // Only one stopwatch exists, so end any extras.
            for extra in live.dropFirst() {
                await extra.end(nil, dismissalPolicy: .immediate)
            }
        } else if ActivityAuthorizationInfo().areActivitiesEnabled {
            // Fails quietly when iOS won't allow it (for example from the background);
            // the next time the app becomes active it tries again.
            _ = try? Activity.request(attributes: StopwatchAttributes(), content: content, pushType: nil)
        }
    }
}
