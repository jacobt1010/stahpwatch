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

    var defaultHex: String {
        switch self {
        case .background: "#000000"
        case .fontTicks: "#FFFFFF"
        case .secondHand: "#FF8B00"
        case .start: "#D9D9D9"
        case .pause: "#D5CB88"
        case .play: "#4F7A5A"
        case .stop: "#BC5959"
        case .customize: "#BDA69D"
        case .startText, .pauseText, .playIcon, .stopIcon, .customizeText: "#000000"
        }
    }
}

/// All customization, saved to UserDefaults as hex strings and applied immediately.
@Observable
final class AppSettings {
    static let defaultDimMinutes = 10
    static let dimRange = 1...60

    private var hexes: [ColorSetting: String] = [:]
    private var matches: [ColorSetting: Bool] = [:]
    /// Minutes to keep the screen awake; 0 means Off.
    var dimMinutes: Int {
        didSet { defaults.set(dimMinutes, forKey: Self.dimKey) }
    }

    @ObservationIgnored private let defaults: UserDefaults
    private static let dimKey = "settings.dimMinutes"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        dimMinutes = defaults.object(forKey: Self.dimKey) as? Int ?? Self.defaultDimMinutes
        for setting in ColorSetting.allCases {
            hexes[setting] = defaults.string(forKey: Self.hexKey(setting)).flatMap(HexColor.normalized) ?? setting.defaultHex
            if setting.canMatchBackground {
                matches[setting] = defaults.object(forKey: Self.matchKey(setting)) as? Bool ?? true
            }
        }
    }

    // MARK: Reading

    /// The color an element should use, following Background when Match Background is on.
    func color(_ setting: ColorSetting) -> Color {
        Color(hex: effectiveHex(setting))
    }

    func effectiveHex(_ setting: ColorSetting) -> String {
        if matchesBackground(setting) { return hexes[.background] ?? ColorSetting.background.defaultHex }
        return hexes[setting] ?? setting.defaultHex
    }

    func matchesBackground(_ setting: ColorSetting) -> Bool {
        setting.canMatchBackground && (matches[setting] ?? true)
    }

    /// True when white text has more contrast on the background than black does.
    var backgroundIsDark: Bool {
        HexColor.luminance(effectiveHex(.background)) < 0.179
    }

    // MARK: Writing

    func setHex(_ hex: String, for setting: ColorSetting) {
        guard let hex = HexColor.normalized(hex) else { return }
        hexes[setting] = hex
        defaults.set(hex, forKey: Self.hexKey(setting))
    }

    func setColor(_ color: Color, for setting: ColorSetting) {
        setHex(HexColor.hex(from: color), for: setting)
    }

    func setMatchesBackground(_ on: Bool, for setting: ColorSetting) {
        guard setting.canMatchBackground else { return }
        if !on {
            // The picker starts from the current Background color.
            setHex(effectiveHex(.background), for: setting)
        }
        matches[setting] = on
        defaults.set(on, forKey: Self.matchKey(setting))
    }

    func resetToDefaults() {
        for setting in ColorSetting.allCases {
            setHex(setting.defaultHex, for: setting)
            if setting.canMatchBackground { setMatchesBackground(true, for: setting) }
        }
        dimMinutes = Self.defaultDimMinutes
    }

    private static func hexKey(_ setting: ColorSetting) -> String { "settings.color.\(setting.rawValue)" }
    private static func matchKey(_ setting: ColorSetting) -> String { "settings.match.\(setting.rawValue)" }
}
