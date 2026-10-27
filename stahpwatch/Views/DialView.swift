import SwiftUI

struct DialColors {
    var background: Color
    var fontTicks: Color
    var secondHand: Color
}

/// The stopwatch face, drawn in code on a 390 × 414 reference canvas and scaled uniformly.
struct DialView: View {
    static let referenceSize = CGSize(width: 390, height: 414)

    /// Elapsed seconds at a given moment. Called on every frame while `isRunning`.
    var elapsed: (Date) -> TimeInterval
    var isRunning: Bool
    var colors: DialColors

    var body: some View {
        TimelineView(.animation(paused: !isRunning)) { timeline in
            let seconds = elapsed(timeline.date)
            Canvas { context, size in
                DialView.draw(in: &context, size: size, elapsed: seconds, colors: colors)
            }
            .accessibilityElement()
            .accessibilityLabel("Elapsed time")
            .accessibilityValue(TimeFormat.spoken(seconds))
            .accessibilityAddTraits(.updatesFrequently)
        }
        .aspectRatio(DialView.referenceSize, contentMode: .fit)
    }

    // MARK: Geometry (reference canvas units)

    private static let mainCenter = CGPoint(x: 195, y: 209)
    private static let tickOuter: CGFloat = 180
    private static let numberRadius: CGFloat = 137
    private static let subCenter = CGPoint(x: 195, y: 145)
    private static let subOuter: CGFloat = 50
    private static let subNumberRadius: CGFloat = 27
    private static let readoutY: CGFloat = 280
    private static let minorOpacity = 0.38

    static func draw(in context: inout GraphicsContext, size: CGSize, elapsed: TimeInterval, colors: DialColors) {
        let scale = min(size.width / referenceSize.width, size.height / referenceSize.height)
        context.translateBy(x: (size.width - referenceSize.width * scale) / 2,
                            y: (size.height - referenceSize.height * scale) / 2)
        context.scaleBy(x: scale, y: scale)

        let minor = colors.fontTicks.opacity(minorOpacity)

        // Main dial: 240 quarter-second ticks; whole seconds slightly longer; majors every 5 s.
        for i in 0..<240 {
            let angle = Double(i) / 240
            if i % 20 == 0 {
                tick(&context, center: mainCenter, angle: angle, outer: tickOuter, length: 14, width: 2.5, color: colors.fontTicks)
            } else if i % 4 == 0 {
                tick(&context, center: mainCenter, angle: angle, outer: tickOuter, length: 12, width: 2, color: minor)
            } else {
                tick(&context, center: mainCenter, angle: angle, outer: tickOuter, length: 7, width: 2, color: minor)
            }
        }
        for n in 1...12 {
            let label = n == 12 ? "60" : "\(n * 5)"
            number(&context, label, center: mainCenter, angle: Double(n) / 12, radius: numberRadius, fontSize: 28, color: colors.fontTicks)
        }

        // Sub-dial: 60 ticks (30 s each), majors every 5 minutes.
        for i in 0..<60 {
            let angle = Double(i) / 60
            if i % 10 == 0 {
                tick(&context, center: subCenter, angle: angle, outer: subOuter, length: 10, width: 2, color: colors.fontTicks)
            } else {
                tick(&context, center: subCenter, angle: angle, outer: subOuter, length: 7, width: 1.5, color: minor)
            }
        }
        for n in 0..<6 {
            let label = n == 0 ? "30" : "\(n * 5)"
            number(&context, label, center: subCenter, angle: Double(n) / 6, radius: subNumberRadius, fontSize: 15, color: colors.fontTicks)
        }

        // Digital readout.
        let readout = Text(TimeFormat.readout(elapsed))
            .font(.system(size: 22, weight: .regular).monospacedDigit())
            .foregroundColor(colors.fontTicks)
        context.draw(context.resolve(readout), at: CGPoint(x: mainCenter.x, y: readoutY), anchor: .center)

        // Hands sweep continuously from 12 o'clock.
        let mainAngle = elapsed.truncatingRemainder(dividingBy: 60) / 60
        let subAngle = elapsed.truncatingRemainder(dividingBy: 1800) / 1800

        var sub = Path()
        sub.move(to: subCenter)
        sub.addLine(to: point(subCenter, angle: subAngle, radius: 45))
        context.stroke(sub, with: .color(colors.secondHand), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        context.fill(Path(ellipseIn: CGRect(x: subCenter.x - 3, y: subCenter.y - 3, width: 6, height: 6)),
                     with: .color(colors.secondHand))

        var main = Path()
        main.move(to: point(mainCenter, angle: mainAngle + 0.5, radius: 35))
        main.addLine(to: point(mainCenter, angle: mainAngle, radius: tickOuter))
        context.stroke(main, with: .color(colors.secondHand), style: StrokeStyle(lineWidth: 2))
        let ring = Path(ellipseIn: CGRect(x: mainCenter.x - 4, y: mainCenter.y - 4, width: 8, height: 8))
        context.fill(ring, with: .color(colors.background))
        context.stroke(ring, with: .color(colors.secondHand), lineWidth: 1.5)
    }

    /// `angle` is in turns, 0 = 12 o'clock, clockwise.
    private static func point(_ center: CGPoint, angle: Double, radius: CGFloat) -> CGPoint {
        let a = angle * 2 * .pi
        return CGPoint(x: center.x + CGFloat(sin(a)) * radius, y: center.y - CGFloat(cos(a)) * radius)
    }

    private static func tick(_ context: inout GraphicsContext, center: CGPoint, angle: Double, outer: CGFloat,
                             length: CGFloat, width: CGFloat, color: Color) {
        var path = Path()
        path.move(to: point(center, angle: angle, radius: outer - length))
        path.addLine(to: point(center, angle: angle, radius: outer))
        context.stroke(path, with: .color(color), lineWidth: width)
    }

    private static func number(_ context: inout GraphicsContext, _ label: String, center: CGPoint, angle: Double,
                               radius: CGFloat, fontSize: CGFloat, color: Color) {
        let text = Text(label).font(.system(size: fontSize, weight: .regular)).foregroundColor(color)
        context.draw(context.resolve(text), at: point(center, angle: angle, radius: radius), anchor: .center)
    }
}

#Preview {
    DialView(elapsed: { _ in 0 }, isRunning: false,
             colors: DialColors(background: .black, fontTicks: .white, secondHand: Color(red: 1, green: 0x8B / 255, blue: 0)))
        .background(.black)
}
