import CoreGraphics

/// Scales the 390 × 844 Figma layout to the current safe area.
/// Buttons scale with width; the dial shrinks further when height is short (iPhone SE).
struct Layout {
    let width: CGFloat
    let height: CGFloat

    /// Width scale for buttons and text.
    var s: CGFloat { width / 390 }

    // Reference sizes (points on the Figma frame).
    static let dialGap: CGFloat = 57          // dial bottom → button row
    static let buttonHeight: CGFloat = 106
    static let pausedGap: CGFloat = 73        // button row bottom → "Paused"
    static let pausedHeight: CGFloat = 58
    static let pillHeight: CGFloat = 47
    static let pillMinGap: CGFloat = 8
    static let bottomPad: CGFloat = 12

    var nonDialHeight: CGFloat {
        (Self.dialGap + Self.buttonHeight + Self.pausedGap + Self.pausedHeight + Self.pillMinGap + Self.pillHeight + Self.bottomPad) * s
    }

    /// Dial scale: full width when there's room, smaller when the screen is short.
    var dialScale: CGFloat {
        min(s, max(0.5, (height - nonDialHeight) / 414))
    }
}
