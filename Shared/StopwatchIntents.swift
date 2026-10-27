import AppIntents
import Foundation

// Compiled into both targets. iOS runs LiveActivityIntents in the app's process, where
// `StopwatchIntentActions` changes the same stored state as the in-app buttons. The widget
// extension has a stub with the same name that is never called.

struct PauseStopwatchIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause"
    static var description = IntentDescription("Pauses the stopwatch.")

    init() {}

    func perform() async throws -> some IntentResult {
        await StopwatchIntentActions.pause()
        return .result()
    }
}

struct ResumeStopwatchIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume"
    static var description = IntentDescription("Resumes the paused stopwatch.")

    init() {}

    func perform() async throws -> some IntentResult {
        await StopwatchIntentActions.resume()
        return .result()
    }
}

struct ResetStopwatchIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reset"
    static var description = IntentDescription("Stops and resets the paused stopwatch.")

    init() {}

    func perform() async throws -> some IntentResult {
        await StopwatchIntentActions.reset()
        return .result()
    }
}
