import SwiftUI
import UIKit

enum HexColor {
    /// Returns `#RRGGBB` in upper case, or nil if the string isn't a 6-digit hex color.
    static func normalized(_ string: String) -> String? {
        var s = string.trimmingCharacters(in: .whitespaces).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, UInt32(s, radix: 16) != nil else { return nil }
        return "#" + s
    }

    static func components(_ hex: String) -> (r: Double, g: Double, b: Double) {
        let value = UInt32(normalized(hex)?.dropFirst() ?? "000000", radix: 16) ?? 0
        return (Double((value >> 16) & 0xFF) / 255, Double((value >> 8) & 0xFF) / 255, Double(value & 0xFF) / 255)
    }

    static func hex(from color: Color) -> String {
        hex(from: UIColor(color))
    }

    static func hex(from color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        // Convert to sRGB so wide-gamut picks are clamped to something we can store.
        let srgb = color.cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)
            .map(UIColor.init(cgColor:)) ?? color
        srgb.getRed(&r, green: &g, blue: &b, alpha: &a)
        func byte(_ v: CGFloat) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(r), byte(g), byte(b))
    }

    /// Relative luminance (WCAG), 0 = black, 1 = white.
    static func luminance(_ hex: String) -> Double {
        let c = components(hex)
        func linear(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b)
    }
}

extension Color {
    init(hex: String) {
        let c = HexColor.components(hex)
        self.init(.sRGB, red: c.r, green: c.g, blue: c.b)
    }
}
