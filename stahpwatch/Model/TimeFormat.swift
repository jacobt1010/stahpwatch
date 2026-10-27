import Foundation

enum TimeFormat {
    /// `MM:SS.hh` under an hour, `H:MM:SS.hh` from an hour on. Hundredths are truncated, not rounded,
    /// so the readout never shows a time that hasn't happened yet.
    static func readout(_ seconds: TimeInterval) -> String {
        let hundredthsTotal = Int((max(0, seconds) * 100).rounded(.down))
        let hundredths = hundredthsTotal % 100
        let totalSeconds = hundredthsTotal / 100
        let s = totalSeconds % 60
        let m = (totalSeconds / 60) % 60
        let h = totalSeconds / 3600
        if h > 0 {
            return String(format: "%d:%02d:%02d.%02d", h, m, s, hundredths)
        }
        return String(format: "%02d:%02d.%02d", m, s, hundredths)
    }

    /// Spoken form for VoiceOver, e.g. "1 hour, 2 minutes, 15 seconds".
    static func spoken(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        formatter.zeroFormattingBehavior = .dropAll
        let whole = max(0, seconds).rounded(.down)
        return whole < 1 ? "0 seconds" : (formatter.string(from: whole) ?? "")
    }
}
