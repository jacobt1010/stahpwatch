import Foundation
import Observation
import UIKit

/// Keeps the screen awake for the Dim Timer length while the stopwatch is in use,
/// then hands control back to iOS Auto-Lock. Any touch restarts the countdown.
@MainActor
final class ScreenAwakeController {
    /// Applies the hold. Injected so tests don't touch UIApplication.
    private let setIdleTimerDisabled: @MainActor (Bool) -> Void
    private var countdown: Task<Void, Never>?
    private var eligible = false
    private var duration: TimeInterval = 0

    private(set) var isHolding = false {
        didSet { if isHolding != oldValue { setIdleTimerDisabled(isHolding) } }
    }

    init(setIdleTimerDisabled: @escaping @MainActor (Bool) -> Void = { UIApplication.shared.isIdleTimerDisabled = $0 }) {
        self.setIdleTimerDisabled = setIdleTimerDisabled
    }

    /// - Parameters:
    ///   - eligible: the stopwatch is running or paused, on the main screen, and the app is active.
    ///   - minutes: the Dim Timer length; 0 means Off.
    /// A change to either starts a fresh hold (or releases it).
    func update(eligible: Bool, minutes: Int) {
        self.eligible = eligible && minutes > 0
        duration = TimeInterval(minutes) * 60
        restart()
    }

    /// Called for every touch anywhere in the app.
    func touched() {
        restart()
    }

    private func restart() {
        countdown?.cancel()
        guard eligible else {
            isHolding = false
            return
        }
        isHolding = true
        let duration = duration
        countdown = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.isHolding = false
        }
    }
}
