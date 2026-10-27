import Foundation

enum Phase: String, Codable {
    case idle, running, paused
}

/// The stopwatch never counts. It stores timestamps and computes elapsed time on demand,
/// so it stays correct through backgrounding, force-quit and restarts at no battery cost.
struct StopwatchState: Equatable {
    var phase: Phase = .idle
    /// Seconds banked before the current run.
    var accumulated: TimeInterval = 0
    /// When the current run began. Only set while running.
    var runStart: Date?

    func elapsed(at now: Date) -> TimeInterval {
        switch phase {
        case .idle:
            return 0
        case .paused:
            return max(0, accumulated)
        case .running:
            // A device clock change can make this negative; clamp it.
            return max(0, accumulated + now.timeIntervalSince(runStart ?? now))
        }
    }

    /// Idle → Running.
    @discardableResult
    mutating func start(at now: Date) -> Bool {
        guard phase == .idle else { return false }
        self = StopwatchState(phase: .running, accumulated: 0, runStart: now)
        return true
    }

    /// Running → Paused.
    @discardableResult
    mutating func pause(at now: Date) -> Bool {
        guard phase == .running else { return false }
        self = StopwatchState(phase: .paused, accumulated: elapsed(at: now), runStart: nil)
        return true
    }

    /// Paused → Running.
    @discardableResult
    mutating func resume(at now: Date) -> Bool {
        guard phase == .paused else { return false }
        phase = .running
        runStart = now
        return true
    }

    /// Paused → Idle, straight back to 00:00.00.
    @discardableResult
    mutating func reset() -> Bool {
        guard phase == .paused else { return false }
        self = StopwatchState()
        return true
    }
}

/// Saves and restores `StopwatchState` in UserDefaults.
struct StopwatchStore {
    private enum Key {
        static let phase = "stopwatch.state"
        static let accumulated = "stopwatch.accumulated"
        static let runStart = "stopwatch.runStart"
    }

    let defaults: UserDefaults

    func load() -> StopwatchState {
        let phase = defaults.string(forKey: Key.phase).flatMap(Phase.init(rawValue:)) ?? .idle
        let accumulated = defaults.double(forKey: Key.accumulated)
        let runStart = defaults.object(forKey: Key.runStart) as? Date
        switch phase {
        case .idle:
            return StopwatchState()
        case .paused:
            return StopwatchState(phase: .paused, accumulated: accumulated, runStart: nil)
        case .running:
            // A running state without a start date can't be trusted; fall back to paused.
            guard let runStart else { return StopwatchState(phase: .paused, accumulated: accumulated, runStart: nil) }
            return StopwatchState(phase: .running, accumulated: accumulated, runStart: runStart)
        }
    }

    func save(_ state: StopwatchState) {
        defaults.set(state.phase.rawValue, forKey: Key.phase)
        defaults.set(state.accumulated, forKey: Key.accumulated)
        if let runStart = state.runStart {
            defaults.set(runStart, forKey: Key.runStart)
        } else {
            defaults.removeObject(forKey: Key.runStart)
        }
    }
}
