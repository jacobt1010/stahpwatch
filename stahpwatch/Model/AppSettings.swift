import SwiftUI
import Observation

/// The 13 color settings. Dim Timer is the 14th setting and lives on `AppSettings`.
enum ColorSetting: String, CaseIterable, Identifiable {
    case background, fontTicks, secondHand
    case start, startText, pause, pauseText, play, playIcon, stop, stopIcon, customize, customizeText

    enum Group: String, CaseIterable {
        case dial = "Dial", buttons = "Buttons"
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .background: "Background"
        case .fontTicks: "Font & Ticks"
        case .secondHand: "Second Hand"
        case .start: "Start"
        case .startText: "Start Text"
        case .pause: "Pause"
        case .pauseText: "Pause Text"
        case .play: "Play"
        case .playIcon: "Play Icon"
        case .stop: "Stop"
        case .stopIcon: "Stop Icon"
        case .customize: "Customize Btn"
        case .customizeText: "Customize Text"
        }
    }

    var group: Group {
        switch self {
        case .background, .fontTicks, .secondHand: .dial
        default: .buttons
        }
    }

    /// Text and icon settings can follow the Background color.
    var canMatchBackground: Bool {
        switch self {
        case .startText, .pauseText, .playIcon, .stopIcon, .customizeText: true
        default: false
        }
    }
}

/// All customization, saved to UserDefaults and applied immediately.
/// Each dial style keeps its own colors, so switching styles never loses a customization.
@Observable
final class AppSettings {
    static let defaultDimMinutes = 10
    static let defaultStyle = DialStyle.paper
    static let dimRange = 1...60

    var style: DialStyle {
        didSet { defaults.set(style.rawValue, forKey: Self.styleKey) }
    }
    private var palettes: [DialStyle: Palette] = [:]
    /// Minutes to keep the screen awake; 0 means Off.
    var dimMinutes: Int {
        didSet { defaults.set(dimMinutes, forKey: Self.dimKey) }
    }

    @ObservationIgnored private let defaults: UserDefaults
    private static let dimKey = "settings.dimMinutes"
    private static let styleKey = "settings.dialStyle"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        dimMinutes = defaults.object(forKey: Self.dimKey) as? Int ?? Self.defaultDimMinutes
        style = defaults.string(forKey: Self.styleKey).flatMap(DialStyle.init(rawValue:)) ?? Self.defaultStyle
        for style in DialStyle.allCases {
            palettes[style] = defaults.data(forKey: Self.paletteKey(style))
                .flatMap { try? JSONDecoder().decode(Palette.self, from: $0) } ?? style.defaultPalette
        }
        migrateFromV1()
    }

    // MARK: Reading

    /// The color an element should use, following Background when Match Background is on.
    func color(_ setting: ColorSetting) -> Color {
        Color(hex: effectiveHex(setting))
    }

    func effectiveHex(_ setting: ColorSetting) -> String {
        effectiveHex(setting, in: style)
    }

    func matchesBackground(_ setting: ColorSetting) -> Bool {
        setting.canMatchBackground && (palette(style).matches[setting.rawValue] ?? true)
    }

    /// The colors a dial draws with, for the current style or a style preview.
    func dialColors(for style: DialStyle? = nil) -> DialColors {
        let style = style ?? self.style
        return DialColors(background: Color(hex: effectiveHex(.background, in: style)),
                          fontTicks: Color(hex: effectiveHex(.fontTicks, in: style)),
                          secondHand: Color(hex: effectiveHex(.secondHand, in: style)))
    }

    /// True when white text has more contrast on the background than black does.
    var backgroundIsDark: Bool {
        HexColor.luminance(effectiveHex(.background)) < 0.179
    }

    // MARK: Writing

    func setHex(_ hex: String, for setting: ColorSetting) {
        guard let hex = HexColor.normalized(hex) else { return }
        var palette = palette(style)
        palette.hexes[setting.rawValue] = hex
        store(palette, for: style)
    }

    func setColor(_ color: Color, for setting: ColorSetting) {
        setHex(HexColor.hex(from: color), for: setting)
    }

    func setMatchesBackground(_ on: Bool, for setting: ColorSetting) {
        guard setting.canMatchBackground else { return }
        var palette = palette(style)
        if !on {
            // The picker starts from the current Background color.
            palette.hexes[setting.rawValue] = effectiveHex(.background)
        }
        palette.matches[setting.rawValue] = on
        store(palette, for: style)
    }

    /// Restores every style's colors, the default style and the Dim Timer.
    func resetToDefaults() {
        for style in DialStyle.allCases {
            store(style.defaultPalette, for: style)
        }
        style = Self.defaultStyle
        dimMinutes = Self.defaultDimMinutes
    }

    // MARK: Private

    private func palette(_ style: DialStyle) -> Palette {
        palettes[style] ?? style.defaultPalette
    }

    private func effectiveHex(_ setting: ColorSetting, in style: DialStyle) -> String {
        let palette = palette(style)
        let key = setting.canMatchBackground && (palette.matches[setting.rawValue] ?? true)
            ? ColorSetting.background.rawValue : setting.rawValue
        return palette.hexes[key] ?? style.defaultPalette.hexes[key] ?? "#000000"
    }

    private func store(_ palette: Palette, for style: DialStyle) {
        palettes[style] = palette
        if let data = try? JSONEncoder().encode(palette) {
            defaults.set(data, forKey: Self.paletteKey(style))
        }
    }

    /// v1 saved one set of colors. Those were the Original look, so they become Original's colors.
    private func migrateFromV1() {
        var palette = palette(.original)
        var found = false
        for setting in ColorSetting.allCases {
            let hexKey = "settings.color.\(setting.rawValue)", matchKey = "settings.match.\(setting.rawValue)"
            if let hex = defaults.string(forKey: hexKey).flatMap(HexColor.normalized) {
                palette.hexes[setting.rawValue] = hex
                found = true
            }
            if let match = defaults.object(forKey: matchKey) as? Bool {
                palette.matches[setting.rawValue] = match
                found = true
            }
            defaults.removeObject(forKey: hexKey)
            defaults.removeObject(forKey: matchKey)
        }
        if found { store(palette, for: .original) }
    }

    private static func paletteKey(_ style: DialStyle) -> String { "settings.palette.\(style.rawValue)" }
}
