import Foundation
import Observation

/// The single source of truth for the stopwatch. In-app buttons and the Live Activity
/// intents (which run in the app's process) both call these methods.
@MainActor
@Observable
final class StopwatchModel {
    static let shared = StopwatchModel(store: StopwatchStore(defaults: .standard),
                                       liveActivity: LiveActivityController())

    private(set) var state: StopwatchState {
        didSet { store.save(state) }
    }

    @ObservationIgnored private let store: StopwatchStore
    @ObservationIgnored private let liveActivity: LiveActivityController?
    @ObservationIgnored private var liveActivitySync: Task<Void, Never>?

    init(store: StopwatchStore, liveActivity: LiveActivityController?) {
        self.store = store
        self.liveActivity = liveActivity
        self.state = store.load()
    }

    func elapsed(at now: Date = .now) -> TimeInterval {
        state.elapsed(at: now)
    }

    func start(at now: Date = .now) { apply { $0.start(at: now) } }
    func pause(at now: Date = .now) { apply { $0.pause(at: now) } }
    func resume(at now: Date = .now) { apply { $0.resume(at: now) } }
    func reset() { apply { $0.reset() } }

    /// Brings the Live Activity in line with the current state: starts one if the stopwatch is
    /// running or paused and none exists (after a relaunch, or after iOS ended it at ~8 h).
    func refreshLiveActivity() {
        syncLiveActivity()
    }

    /// Waits for the most recent Live Activity update. Used by intents so iOS doesn't suspend
    /// the app before the Lock Screen catches up.
    func waitForLiveActivity() async {
        await liveActivitySync?.value
    }

    private func apply(_ transition: (inout StopwatchState) -> Bool) {
        var next = state
        guard transition(&next) else { return }
        state = next
        syncLiveActivity()
    }

    private func syncLiveActivity() {
        guard let liveActivity else { return }
        let state = state
        let previous = liveActivitySync
        liveActivitySync = Task {
            await previous?.value
            await liveActivity.sync(to: state)
        }
    }
}
