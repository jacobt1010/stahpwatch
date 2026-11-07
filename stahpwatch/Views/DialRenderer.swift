import SwiftUI

/// Draws each dial style on the 390 × 414 reference canvas: `drawFace` for what never moves
/// and `drawLive` for what changes every frame.
enum DialRenderer {
    private static let center = CGPoint(x: 195, y: 209)

    static func fit(_ context: inout GraphicsContext, to size: CGSize) {
        let reference = DialView.referenceSize
        let scale = min(size.width / reference.width, size.height / reference.height)
        context.translateBy(x: (size.width - reference.width * scale) / 2,
                            y: (size.height - reference.height * scale) / 2)
        context.scaleBy(x: scale, y: scale)
    }

    static func drawFace(_ style: DialStyle, in context: inout GraphicsContext, colors: DialColors) {
        switch style {
        case .paper: paperFace(&context, colors)
        case .original: originalFace(&context, colors)
        case .pulse: break // Every tick can swell, so Pulse draws them all in drawLive.
        case .orbit: orbitFace(&context, colors)
        case .block: blockFace(&context, colors)
        }
    }

    static func drawLive(_ style: DialStyle, in context: inout GraphicsContext, elapsed: TimeInterval, colors: DialColors) {
        switch style {
        case .paper: paperLive(&context, elapsed, colors)
        case .original: originalLive(&context, elapsed, colors)
        case .pulse: pulseLive(&context, elapsed, colors)
        case .orbit: orbitLive(&context, elapsed, colors)
        case .block: blockLive(&context, elapsed, colors)
        }
    }

    // MARK: Paper

    private static let paperSub = CGPoint(x: 195, y: 284)

    private static func paperFace(_ c: inout GraphicsContext, _ colors: DialColors) {
        let ink = colors.fontTicks
        c.stroke(circle(center, 174), with: .color(ink), lineWidth: 1)
        for i in 0..<60 {
            let major = i % 5 == 0
            tick(&c, center, turn: Double(i) / 60, outer: 169, length: major ? 18 : 8, width: major ? 2 : 0.8, color: ink)
        }
        for n in 1...12 {
            number(&c, "\(n * 5)", center, turn: Double(n) / 12, radius: 130, size: 23, design: .serif, color: ink)
        }
        c.stroke(circle(paperSub, 34), with: .color(ink), lineWidth: 1)
        for i in 0..<6 {
            tick(&c, paperSub, turn: Double(i) / 6, outer: 34, length: 6, width: 1.2, color: ink)
        }
    }

    private static func paperLive(_ c: inout GraphicsContext, _ t: TimeInterval, _ colors: DialColors) {
        let hand = colors.secondHand
        readout(&c, t, y: 149, size: 22, design: .serif, color: colors.fontTicks)
        line(&c, paperSub, point(paperSub, subTurn(t), 26), width: 1.5, color: hand, cap: .round)
        let turn = mainTurn(t)
        line(&c, point(center, turn + 0.5, 44), point(center, turn, 164), width: 1.6, color: hand)
        c.fill(circle(point(center, turn + 0.5, 44), 6.5), with: .color(hand))
        c.fill(circle(center, 4), with: .color(hand))
    }

    // MARK: Original (the geometry in SPEC.md)

    private static let originalSub = CGPoint(x: 195, y: 145)

    private static func originalFace(_ c: inout GraphicsContext, _ colors: DialColors) {
        let minor = colors.fontTicks.opacity(0.38)
        // 240 quarter-second ticks; whole seconds slightly longer; majors every 5 s.
        for i in 0..<240 {
            let turn = Double(i) / 240
            if i % 20 == 0 {
                tick(&c, center, turn: turn, outer: 180, length: 14, width: 2.5, color: colors.fontTicks)
            } else {
                tick(&c, center, turn: turn, outer: 180, length: i % 4 == 0 ? 12 : 7, width: 2, color: minor)
            }
        }
        for n in 1...12 {
            number(&c, n == 12 ? "60" : "\(n * 5)", center, turn: Double(n) / 12, radius: 137, size: 28, color: colors.fontTicks)
        }
        // Sub-dial: 60 ticks (30 s each), majors every 5 minutes.
        for i in 0..<60 {
            let turn = Double(i) / 60
            if i % 10 == 0 {
                tick(&c, originalSub, turn: turn, outer: 50, length: 10, width: 2, color: colors.fontTicks)
            } else {
                tick(&c, originalSub, turn: turn, outer: 50, length: 7, width: 1.5, color: minor)
            }
        }
        for n in 0..<6 {
            number(&c, n == 0 ? "30" : "\(n * 5)", originalSub, turn: Double(n) / 6, radius: 27, size: 15, color: colors.fontTicks)
        }
    }

    private static func originalLive(_ c: inout GraphicsContext, _ t: TimeInterval, _ colors: DialColors) {
        let hand = colors.secondHand
        readout(&c, t, y: 280, size: 22, color: colors.fontTicks)
        line(&c, originalSub, point(originalSub, subTurn(t), 45), width: 2, color: hand, cap: .round)
        c.fill(circle(originalSub, 3), with: .color(hand))
        let turn = mainTurn(t)
        line(&c, point(center, turn + 0.5, 35), point(center, turn, 180), width: 2, color: hand)
        c.fill(circle(center, 4), with: .color(colors.background))
        c.stroke(circle(center, 4), with: .color(hand), lineWidth: 1.5)
    }

    // MARK: Pulse

    /// How swollen tick `i` is: full for the whole second it marks, then a short fade.
    /// Worked out from elapsed time alone, so it stays right after a pause or relaunch.
    /// Kept apart from Pulse's drawing so other styles could offer the swell later.
    static func swell(tick i: Int, elapsed t: TimeInterval) -> Double {
        let fade = 0.4
        let age = (t - Double(i)).truncatingRemainder(dividingBy: 60)
        let wrapped = age < 0 ? age + 60 : age
        if wrapped < 1 { return 1 }
        guard t >= 1, wrapped < 1 + fade else { return 0 }
        return 1 - (wrapped - 1) / fade
    }

    private static func pulseLive(_ c: inout GraphicsContext, _ t: TimeInterval, _ colors: DialColors) {
        for i in 0..<60 {
            let major = i % 5 == 0
            let s = swell(tick: i, elapsed: t)
            let color = s > 0 ? colors.secondHand : colors.fontTicks.opacity(major ? 1 : 0.35)
            tick(&c, center, turn: Double(i) / 60, outer: 174, length: (major ? 20 : 12) + s * 39,
                 width: (major ? 3.4 : 2) + s * 5.8, color: color, cap: .round)
        }
        largeReadout(&c, t, design: .rounded, colors)
    }

    // MARK: Orbit

    private static let orbitRadius: CGFloat = 164

    private static func orbitFace(_ c: inout GraphicsContext, _ colors: DialColors) {
        c.stroke(circle(center, orbitRadius), with: .color(colors.fontTicks.opacity(0.14)), lineWidth: 20)
    }

    private static func orbitLive(_ c: inout GraphicsContext, _ t: TimeInterval, _ colors: DialColors) {
        let turn = mainTurn(t)
        if turn > 0.001 {
            var arc = Path()
            arc.addArc(center: center, radius: orbitRadius, startAngle: .degrees(-90),
                       endAngle: .degrees(-90 + turn * 360), clockwise: false)
            c.stroke(arc, with: .color(colors.secondHand), style: StrokeStyle(lineWidth: 20, lineCap: .round))
        }
        let minutes = Int(t / 60) % 30
        for i in 0..<30 {
            let on = i <= minutes
            c.fill(circle(point(center, Double(i) / 30, 133), 3),
                   with: .color(on ? colors.secondHand : colors.fontTicks.opacity(0.25)))
        }
        largeReadout(&c, t, design: .rounded, colors)
    }

    // MARK: Block

    private static func blockFace(_ c: inout GraphicsContext, _ colors: DialColors) {
        for i in 0..<12 {
            let big = i % 3 == 0
            tick(&c, center, turn: Double(i) / 12, outer: 179, length: big ? 39 : 20, width: big ? 13 : 8, color: colors.fontTicks)
        }
        for (turn, label) in [(0.25, "15"), (0.5, "30"), (0.75, "45"), (0.0, "60")] {
            number(&c, label, center, turn: turn, radius: 101, size: 39, weight: .bold, design: .monospaced, color: colors.fontTicks)
        }
    }

    private static func blockLive(_ c: inout GraphicsContext, _ t: TimeInterval, _ colors: DialColors) {
        let turn = mainTurn(t)
        var wedge = Path()
        wedge.move(to: point(center, turn, 177))
        wedge.addLine(to: point(center, turn + 0.25, 21))
        wedge.addLine(to: point(center, turn - 0.25, 21))
        wedge.closeSubpath()
        c.fill(wedge, with: .color(colors.secondHand))
        c.fill(circle(center, 21), with: .color(colors.secondHand))

        // The wedge is wide enough to cover the time, so the time sits on a plate above it.
        let text = c.resolve(Text(TimeFormat.readout(t))
            .font(.system(size: 24, weight: .bold, design: .monospaced).monospacedDigit())
            .foregroundColor(colors.fontTicks))
        let size = text.measure(in: CGSize(width: 390, height: 60))
        let plate = CGRect(x: center.x - size.width / 2 - 8, y: 262 - size.height / 2 - 3,
                           width: size.width + 16, height: size.height + 6)
        c.fill(Path(plate), with: .color(colors.background))
        c.draw(text, at: CGPoint(x: center.x, y: 262), anchor: .center)
    }

    // MARK: Helpers

    private static func mainTurn(_ t: TimeInterval) -> Double { t.truncatingRemainder(dividingBy: 60) / 60 }
    private static func subTurn(_ t: TimeInterval) -> Double { t.truncatingRemainder(dividingBy: 1800) / 1800 }

    /// `turn` is in full turns, 0 = 12 o'clock, clockwise.
    private static func point(_ center: CGPoint, _ turn: Double, _ radius: CGFloat) -> CGPoint {
        let a = turn * 2 * .pi
        return CGPoint(x: center.x + CGFloat(sin(a)) * radius, y: center.y - CGFloat(cos(a)) * radius)
    }

    private static func circle(_ center: CGPoint, _ radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    }

    private static func line(_ c: inout GraphicsContext, _ from: CGPoint, _ to: CGPoint, width: CGFloat, color: Color,
                             cap: CGLineCap = .butt) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        c.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: cap))
    }

    private static func tick(_ c: inout GraphicsContext, _ center: CGPoint, turn: Double, outer: CGFloat, length: CGFloat,
                             width: CGFloat, color: Color, cap: CGLineCap = .butt) {
        line(&c, point(center, turn, outer - length), point(center, turn, outer), width: width, color: color, cap: cap)
    }

    private static func number(_ c: inout GraphicsContext, _ label: String, _ center: CGPoint, turn: Double, radius: CGFloat,
                               size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default, color: Color) {
        let text = Text(label).font(.system(size: size, weight: weight, design: design)).foregroundColor(color)
        c.draw(c.resolve(text), at: point(center, turn, radius), anchor: .center)
    }

    private static func readout(_ c: inout GraphicsContext, _ t: TimeInterval, y: CGFloat, size: CGFloat,
                                weight: Font.Weight = .regular, design: Font.Design = .default, color: Color) {
        let text = Text(TimeFormat.readout(t))
            .font(.system(size: size, weight: weight, design: design).monospacedDigit())
            .foregroundColor(color)
        c.draw(c.resolve(text), at: CGPoint(x: center.x, y: y), anchor: .center)
    }

    /// The time as the dial's main feature, with the hundredths smaller beneath it.
    private static func largeReadout(_ c: inout GraphicsContext, _ t: TimeInterval, design: Font.Design, _ colors: DialColors) {
        let parts = TimeFormat.readout(t).split(separator: ".")
        let size: CGFloat = parts[0].count > 5 ? 44 : 60
        let main = Text(parts[0]).font(.system(size: size, weight: .semibold, design: design).monospacedDigit())
            .foregroundColor(colors.fontTicks)
        let hundredths = Text("." + parts[1]).font(.system(size: 26, weight: .medium, design: design).monospacedDigit())
            .foregroundColor(colors.secondHand)
        c.draw(c.resolve(main), at: CGPoint(x: center.x, y: 197), anchor: .center)
        c.draw(c.resolve(hundredths), at: CGPoint(x: center.x, y: 248), anchor: .center)
    }
}
