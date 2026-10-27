import ActivityKit
import Foundation

/// Everything the Live Activity needs travels in its content state, so no App Group is required.
struct StopwatchAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var isRunning: Bool
        /// Seconds banked before the current run.
        var accumulated: TimeInterval
        /// When the current run began; nil while paused.
        var runStart: Date?

        /// The moment the stopwatch would have started if it had never paused.
        /// Feeding this to `Text(timerInterval:)` lets iOS count up with no app work.
        var timerStart: Date {
            (runStart ?? .now).addingTimeInterval(-accumulated)
        }

        /// `M:SS` or `H:MM:SS`, matching the system timer text, for the frozen paused time.
        var frozenText: String {
            let total = Int(max(0, accumulated))
            let h = total / 3600, m = (total / 60) % 60, s = total % 60
            return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
        }
    }
}
