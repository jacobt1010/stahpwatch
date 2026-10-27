/// Called by the Live Activity intents, which iOS runs in this process.
@MainActor
enum StopwatchIntentActions {
    static func pause() async {
        StopwatchModel.shared.pause()
        await StopwatchModel.shared.waitForLiveActivity()
    }

    static func resume() async {
        StopwatchModel.shared.resume()
        await StopwatchModel.shared.waitForLiveActivity()
    }

    static func reset() async {
        StopwatchModel.shared.reset()
        await StopwatchModel.shared.waitForLiveActivity()
    }
}
