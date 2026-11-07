import SwiftUI

struct DialColors {
    var background: Color
    var fontTicks: Color
    var secondHand: Color
}

/// The stopwatch face, drawn in code on a 390 × 414 reference canvas and scaled uniformly.
/// The face only redraws when its style or colors change; each frame redraws just the moving parts.
struct DialView: View {
    static let referenceSize = CGSize(width: 390, height: 414)

    var style: DialStyle
    /// Elapsed seconds at a given moment. Called on every frame while `isRunning`.
    var elapsed: (Date) -> TimeInterval
    var isRunning: Bool
    var colors: DialColors

    var body: some View {
        ZStack {
            Canvas { context, size in
                DialRenderer.fit(&context, to: size)
                DialRenderer.drawFace(style, in: &context, colors: colors)
            }
            .accessibilityHidden(true)

            TimelineView(.animation(paused: !isRunning)) { timeline in
                let seconds = elapsed(timeline.date)
                Canvas { context, size in
                    DialRenderer.fit(&context, to: size)
                    DialRenderer.drawLive(style, in: &context, elapsed: seconds, colors: colors)
                }
                .accessibilityElement()
                .accessibilityLabel("Elapsed time")
                .accessibilityValue(TimeFormat.spoken(seconds))
                .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .aspectRatio(DialView.referenceSize, contentMode: .fit)
    }
}

#Preview {
    DialView(style: .paper, elapsed: { _ in 462.18 }, isRunning: false, colors: AppSettings().dialColors())
        .background(AppSettings().color(.background))
}
