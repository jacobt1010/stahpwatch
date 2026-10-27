import XCTest
@testable import stahpwatch

final class StopwatchStateTests: XCTestCase {
    let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)

    func testIdleIsZero() {
        XCTAssertEqual(StopwatchState().elapsed(at: t0), 0)
    }

    func testFullCycle() {
        var s = StopwatchState()
        XCTAssertTrue(s.start(at: t0))
        XCTAssertEqual(s.phase, .running)
        XCTAssertEqual(s.elapsed(at: t0 + 10), 10, accuracy: 1e-9)

        XCTAssertTrue(s.pause(at: t0 + 10))
        XCTAssertEqual(s.phase, .paused)
        XCTAssertNil(s.runStart)
        XCTAssertEqual(s.elapsed(at: t0 + 500), 10, accuracy: 1e-9, "paused time is frozen")

        XCTAssertTrue(s.resume(at: t0 + 100))
        XCTAssertEqual(s.elapsed(at: t0 + 105), 15, accuracy: 1e-9)

        XCTAssertTrue(s.pause(at: t0 + 110))
        XCTAssertEqual(s.accumulated, 20, accuracy: 1e-9)

        XCTAssertTrue(s.reset())
        XCTAssertEqual(s, StopwatchState())
        XCTAssertEqual(s.elapsed(at: t0 + 200), 0)
    }

    func testInvalidTransitionsAreIgnored() {
        var s = StopwatchState()
        XCTAssertFalse(s.pause(at: t0))
        XCTAssertFalse(s.resume(at: t0))
        XCTAssertFalse(s.reset(), "Stop is only reachable from Paused")
        s.start(at: t0)
        XCTAssertFalse(s.start(at: t0 + 1))
        XCTAssertFalse(s.resume(at: t0 + 1))
        XCTAssertFalse(s.reset())
        XCTAssertEqual(s.runStart, t0)
    }

    func testClockMovedBackwardsClampsToZero() {
        var s = StopwatchState()
        s.start(at: t0)
        XCTAssertEqual(s.elapsed(at: t0 - 3600), 0)
    }
}

final class StopwatchStoreTests: XCTestCase {
    var defaults: UserDefaults!
    let suite = "stahpwatch.tests.store"

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    func testEmptyLoadsIdle() {
        XCTAssertEqual(StopwatchStore(defaults: defaults).load(), StopwatchState())
    }

    func testRoundTripRunning() {
        let store = StopwatchStore(defaults: defaults)
        let state = StopwatchState(phase: .running, accumulated: 12.5, runStart: Date(timeIntervalSinceReferenceDate: 42))
        store.save(state)
        XCTAssertEqual(StopwatchStore(defaults: defaults).load(), state)
    }

    func testRoundTripPausedDropsRunStart() {
        let store = StopwatchStore(defaults: defaults)
        store.save(StopwatchState(phase: .running, accumulated: 0, runStart: .now))
        store.save(StopwatchState(phase: .paused, accumulated: 99, runStart: nil))
        XCTAssertEqual(store.load(), StopwatchState(phase: .paused, accumulated: 99, runStart: nil))
        XCTAssertNil(defaults.object(forKey: "stopwatch.runStart"))
    }

    func testRunningWithoutStartFallsBackToPaused() {
        defaults.set("running", forKey: "stopwatch.state")
        defaults.set(5.0, forKey: "stopwatch.accumulated")
        XCTAssertEqual(StopwatchStore(defaults: defaults).load(), StopwatchState(phase: .paused, accumulated: 5, runStart: nil))
    }

    /// Simulates force-quit: a fresh model built from the same defaults sees the same stopwatch.
    @MainActor
    func testModelSurvivesRelaunch() {
        let start = Date(timeIntervalSinceReferenceDate: 1000)
        let model = StopwatchModel(store: StopwatchStore(defaults: defaults), liveActivity: nil)
        model.start(at: start)

        let relaunched = StopwatchModel(store: StopwatchStore(defaults: defaults), liveActivity: nil)
        XCTAssertEqual(relaunched.state.phase, .running)
        XCTAssertEqual(relaunched.elapsed(at: start + 90), 90, accuracy: 1e-6)

        relaunched.pause(at: start + 90)
        let again = StopwatchModel(store: StopwatchStore(defaults: defaults), liveActivity: nil)
        XCTAssertEqual(again.state.phase, .paused)
        XCTAssertEqual(again.elapsed(at: start + 10_000), 90, accuracy: 1e-6)

        again.reset()
        XCTAssertEqual(StopwatchModel(store: StopwatchStore(defaults: defaults), liveActivity: nil).state, StopwatchState())
    }
}
