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
        case .customize: "Customize Button"
        case .customizeText: "Customize Icon"
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
/// One Look is always active, and every color or style change edits that Look.
@Observable
final class AppSettings {
    static let defaultDimMinutes = 10
    static let defaultStyle = DialStyle.paper
    static let dimRange = 1...60

    /// Never empty.
    private(set) var looks: [Look] {
        didSet { saveLooks() }
    }
    /// Saved Looks this version can't read at all, such as ones from a newer version.
    /// They're never shown, and every save writes them back unchanged.
    @ObservationIgnored private let unreadableLooks: [JSONValue]
    private(set) var activeLookID: UUID {
        didSet { defaults.set(activeLookID.uuidString, forKey: Self.activeLookKey) }
    }
    /// Minutes to keep the screen awake; 0 means Off.
    var dimMinutes: Int {
        didSet { defaults.set(dimMinutes, forKey: Self.dimKey) }
    }

    @ObservationIgnored private let defaults: UserDefaults
    private static let dimKey = "settings.dimMinutes"
    private static let looksKey = "settings.looks"
    private static let activeLookKey = "settings.activeLook"
    /// Where unreadable Looks data is kept before it's replaced, so it's never lost.
    static let unreadableLooksBackupKey = "settings.looks.unreadableBackup"
    private static let maxLookNameLength = 30

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        dimMinutes = defaults.object(forKey: Self.dimKey) as? Int ?? Self.defaultDimMinutes
        let loaded = Self.loadLooks(from: defaults)
        unreadableLooks = loaded.unreadable
        looks = loaded.looks
        activeLookID = loaded.activeID
        saveLooks()
        defaults.set(loaded.activeID.uuidString, forKey: Self.activeLookKey)
    }

    // MARK: Reading

    var activeLook: Look {
        looks.first { $0.id == activeLookID } ?? looks[0]
    }

    /// The active Look's dial style. Changing it keeps the Look's colors.
    var style: DialStyle {
        get { activeLook.style }
        set { editActiveLook { $0.style = newValue } }
    }

    /// The color an element should use, following Background when Match Background is on.
    func color(_ setting: ColorSetting) -> Color {
        Color(hex: effectiveHex(setting))
    }

    func effectiveHex(_ setting: ColorSetting) -> String {
        hex(setting, in: activeLook)
    }

    func matchesBackground(_ setting: ColorSetting) -> Bool {
        setting.canMatchBackground && (activeLook.palette.matches[setting.rawValue] ?? true)
    }

    /// The colors the active Look's dial draws with.
    func dialColors() -> DialColors {
        dialColors(for: activeLook)
    }

    func dialColors(for look: Look) -> DialColors {
        DialColors(background: Color(hex: hex(.background, in: look)),
                   fontTicks: Color(hex: hex(.fontTicks, in: look)),
                   secondHand: Color(hex: hex(.secondHand, in: look)))
    }

    /// True when white text has more contrast on the background than black does.
    var backgroundIsDark: Bool {
        HexColor.luminance(effectiveHex(.background)) < 0.179
    }

    /// True when the active Look already has its style's default colors.
    var usesStyleColors: Bool {
        activeLook.palette == activeLook.style.defaultPalette
    }

    // MARK: Editing the active Look

    func setHex(_ hex: String, for setting: ColorSetting) {
        guard let hex = HexColor.normalized(hex) else { return }
        editActiveLook { $0.palette.hexes[setting.rawValue] = hex }
    }

    func setColor(_ color: Color, for setting: ColorSetting) {
        setHex(HexColor.hex(from: color), for: setting)
    }

    func setMatchesBackground(_ on: Bool, for setting: ColorSetting) {
        guard setting.canMatchBackground else { return }
        let background = effectiveHex(.background)
        editActiveLook { look in
            // The picker starts from the current Background color.
            if !on { look.palette.hexes[setting.rawValue] = background }
            look.palette.matches[setting.rawValue] = on
        }
    }

    /// Replaces the active Look's colors with its style's defaults.
    func useStyleColors() {
        editActiveLook { $0.palette = $0.style.defaultPalette }
    }

    private func editActiveLook(_ edit: (inout Look) -> Void) {
        guard let index = looks.firstIndex(where: { $0.id == activeLookID }) else { return }
        edit(&looks[index])
    }

    // MARK: Managing Looks

    func select(_ look: Look) {
        guard looks.contains(where: { $0.id == look.id }) else { return }
        activeLookID = look.id
    }

    /// The first unused default name: "Look 1", "Look 2" and so on.
    var nextLookName: String {
        Self.unusedName(among: looks)
    }

    /// Adds a copy of the active Look with this name and switches to it.
    func addLook(named name: String) {
        var copy = activeLook
        copy.id = UUID()
        copy.name = cleaned(name) ?? nextLookName
        insert(copy, after: activeLook)
    }

    /// Adds a copy of a Look, named after it, and switches to it.
    func duplicate(_ look: Look) {
        var copy = look
        copy.id = UUID()
        let names = Set(looks.map(\.name))
        let base = String(look.name.prefix(Self.maxLookNameLength - 7))
        copy.name = (1...).lazy.map { $0 == 1 ? "\(base) Copy" : "\(base) Copy \($0)" }
            .first { !names.contains($0) } ?? base
        insert(copy, after: look)
    }

    func rename(_ look: Look, to name: String) {
        guard let name = cleaned(name), let index = looks.firstIndex(where: { $0.id == look.id }) else { return }
        looks[index].name = name
    }

    /// Deletes a Look, moving to a neighbor if it was active. The last Look can't be deleted.
    func delete(_ look: Look) {
        guard looks.count > 1, let index = looks.firstIndex(where: { $0.id == look.id }) else { return }
        if look.id == activeLookID {
            activeLookID = looks[index == looks.count - 1 ? index - 1 : index + 1].id
        }
        looks.remove(at: index)
    }

    private func insert(_ look: Look, after original: Look) {
        let index = looks.firstIndex { $0.id == original.id } ?? looks.count - 1
        looks.insert(look, at: index + 1)
        activeLookID = look.id
    }

    private func cleaned(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : String(trimmed.prefix(Self.maxLookNameLength))
    }

    private func hex(_ setting: ColorSetting, in look: Look) -> String {
        let palette = look.palette
        let key = setting.canMatchBackground && (palette.matches[setting.rawValue] ?? true)
            ? ColorSetting.background.rawValue : setting.rawValue
        return palette.hexes[key] ?? look.style.defaultPalette.hexes[key] ?? "#000000"
    }

    // MARK: Loading and migration

    private static func unusedName(among looks: [Look]) -> String {
        let names = Set(looks.map(\.name))
        return (1...).lazy.map { "Look \($0)" }.first { !names.contains($0) } ?? "Look"
    }

    /// Writes the readable Looks, then the unreadable ones exactly as they were found.
    private func saveLooks() {
        guard let readable = try? looks.map(JSONValue.init(encoding:)),
              let data = try? JSONEncoder().encode(readable + unreadableLooks) else { return }
        defaults.set(data, forKey: Self.looksKey)
    }

    private struct Loaded {
        var looks: [Look]
        var unreadable: [JSONValue]
        var activeID: UUID
    }

    /// Reads saved Looks without ever losing data this version doesn't understand:
    /// each Look is read on its own, Looks it can't read are kept aside, and data that
    /// isn't a list of Looks at all is backed up before a fresh Look replaces it.
    private static func loadLooks(from defaults: UserDefaults) -> Loaded {
        var looks: [Look] = []
        var unreadable: [JSONValue] = []
        if let data = defaults.data(forKey: looksKey) {
            if let items = try? JSONDecoder().decode([JSONValue].self, from: data) {
                for item in items {
                    if let look = try? item.decode(Look.self) {
                        looks.append(look)
                    } else {
                        unreadable.append(item)
                    }
                }
            } else if defaults.object(forKey: unreadableLooksBackupKey) == nil {
                defaults.set(data, forKey: unreadableLooksBackupKey)
            }
        }

        let legacy = migrateLegacyColors(into: &looks, from: defaults)

        if let id = defaults.string(forKey: activeLookKey).flatMap(UUID.init(uuidString:)),
           looks.contains(where: { $0.id == id }) {
            return Loaded(looks: looks, unreadable: unreadable, activeID: id)
        }
        // Coming from before Looks: the look the app was showing becomes the active Look.
        if let (style, palette) = legacy {
            if let current = looks.first(where: { $0.style == style && $0.palette == palette }) {
                return Loaded(looks: looks, unreadable: unreadable, activeID: current.id)
            }
            let current = Look(name: unusedName(among: looks), style: style, palette: palette)
            return Loaded(looks: looks + [current], unreadable: unreadable, activeID: current.id)
        }
        // The active Look is missing or unreadable: use the first one this version can show.
        if let first = looks.first {
            return Loaded(looks: looks, unreadable: unreadable, activeID: first.id)
        }
        let fresh = Look(name: unusedName(among: looks), style: defaultStyle, palette: defaultStyle.defaultPalette)
        return Loaded(looks: [fresh], unreadable: unreadable, activeID: fresh.id)
    }

    /// Before Looks took over, each style kept its own colors. Anything customized becomes a
    /// Look, so nothing is lost. Returns the style and colors the app was showing, if there
    /// was any data from before Looks.
    private static func migrateLegacyColors(into looks: inout [Look], from defaults: UserDefaults)
        -> (DialStyle, Palette)? {
        var working: [DialStyle: Palette] = [:]
        var found = false
        for style in DialStyle.allCases {
            let key = "settings.palette.\(style.rawValue)"
            if let data = defaults.data(forKey: key) {
                found = true
                working[style] = try? JSONDecoder().decode(Palette.self, from: data)
            }
            defaults.removeObject(forKey: key)
        }
        if let palette = takeV1Palette(from: defaults) {
            working[.original] = palette
            found = true
        }
        for style in DialStyle.allCases {
            guard let palette = working[style], palette != style.defaultPalette,
                  !looks.contains(where: { $0.style == style && $0.palette == palette }) else { continue }
            looks.append(Look(name: "My \(style.title)", style: style, palette: palette))
        }

        let oldStyleKey = "settings.dialStyle"
        let oldStyle = defaults.string(forKey: oldStyleKey)
        defaults.removeObject(forKey: oldStyleKey)
        guard found || oldStyle != nil else { return nil }
        let style = oldStyle.flatMap(DialStyle.init(rawValue:)) ?? defaultStyle
        return (style, working[style] ?? style.defaultPalette)
    }

    /// v1 saved one set of colors. Those were the Original look.
    private static func takeV1Palette(from defaults: UserDefaults) -> Palette? {
        var palette = DialStyle.original.defaultPalette
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
        return found ? palette : nil
    }
}
