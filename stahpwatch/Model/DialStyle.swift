import SwiftUI

/// One color scheme: the 13 color settings, keyed by `ColorSetting.rawValue`.
struct Palette: Codable, Equatable {
    var hexes: [String: String]
    var matches: [String: Bool]
}

/// The selectable stopwatch faces. Each has its own drawing, font and default colors.
enum DialStyle: String, CaseIterable, Identifiable {
    case paper, original, pulse, orbit, block

    var id: String { rawValue }

    var title: String {
        switch self {
        case .paper: "Paper"
        case .original: "Original"
        case .pulse: "Pulse"
        case .orbit: "Orbit"
        case .block: "Block"
        }
    }

    var fontDesign: Font.Design {
        switch self {
        case .paper: .serif
        case .original: .default
        case .pulse, .orbit: .rounded
        case .block: .monospaced
        }
    }

    /// Button corner radius on the 390-point reference width.
    var buttonRadius: CGFloat {
        switch self {
        case .paper: 15
        case .original: 30
        case .pulse: 34
        case .orbit: 50
        case .block: 8
        }
    }

    var defaultPalette: Palette {
        switch self {
        case .paper:
            Self.palette(background: "#F2EBDD", ink: "#1F1C18", hand: "#D4431C", start: "#1F1C18", pause: "#A9782A",
                         play: "#3F6B52", stop: "#D4431C", customize: "#DDD3BF", customizeText: "#1F1C18")
        case .original:
            Self.palette(background: "#000000", ink: "#FFFFFF", hand: "#FF8B00", start: "#D9D9D9", pause: "#D5CB88",
                         play: "#4F7A5A", stop: "#BC5959", customize: "#BDA69D")
        case .pulse:
            Self.palette(background: "#17121F", ink: "#F3EEF8", hand: "#FF5FA2", start: "#FF5FA2", pause: "#E8C26A",
                         play: "#4FD1A5", stop: "#FF6B5B", customize: "#30273D", customizeText: "#F3EEF8")
        case .orbit:
            Self.palette(background: "#0F1B2D", ink: "#EAF2F8", hand: "#5FE3C0", start: "#5FE3C0", pause: "#F5C76B",
                         play: "#4FC3F7", stop: "#FF7A6B", customize: "#24344D", customizeText: "#EAF2F8")
        case .block:
            Self.palette(background: "#121212", ink: "#F2F2F2", hand: "#E4FF4A", start: "#E4FF4A", pause: "#F2F2F2",
                         play: "#6CFF8F", stop: "#FF4D3D", customize: "#2B2B2B", customizeText: "#F2F2F2")
        }
    }

    /// Text and icons match Background, except a Customize label given its own color for contrast.
    private static func palette(background: String, ink: String, hand: String, start: String, pause: String,
                                play: String, stop: String, customize: String, customizeText: String? = nil) -> Palette {
        var hexes: [ColorSetting: String] = [
            .background: background, .fontTicks: ink, .secondHand: hand, .start: start, .pause: pause,
            .play: play, .stop: stop, .customize: customize,
        ]
        var matches: [String: Bool] = [:]
        for setting in ColorSetting.allCases where setting.canMatchBackground {
            hexes[setting] = background
            matches[setting.rawValue] = true
        }
        if let customizeText {
            hexes[.customizeText] = customizeText
            matches[ColorSetting.customizeText.rawValue] = false
        }
        return Palette(hexes: Dictionary(uniqueKeysWithValues: hexes.map { ($0.key.rawValue, $0.value) }), matches: matches)
    }
}
