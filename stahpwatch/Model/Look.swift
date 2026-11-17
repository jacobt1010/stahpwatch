import Foundation

/// A named combination of dial style and colors. Exactly one is active, and editing the
/// style or colors changes it. The Dim Timer isn't part of a Look: it's about how the app
/// is used, not how it looks.
struct Look: Equatable, Identifiable {
    var id = UUID()
    var name: String
    /// The saved style name. Kept as text so a style from a newer version survives here.
    var styleID: String
    var palette: Palette
    /// Fields saved by a newer version, written back unchanged.
    var extras: [String: JSONValue] = [:]

    init(id: UUID = UUID(), name: String, style: DialStyle, palette: Palette) {
        self.id = id
        self.name = name
        self.styleID = style.rawValue
        self.palette = palette
    }

    /// The style to draw. A style this version doesn't know draws as Paper until it's changed.
    var style: DialStyle {
        get { DialStyle(rawValue: styleID) ?? .paper }
        set { styleID = newValue.rawValue }
    }

    /// False when the Look uses a style from a newer version.
    var hasKnownStyle: Bool { DialStyle(rawValue: styleID) != nil }
}

extension Look: Codable {
    private static let known: Set<String> = ["id", "name", "style", "palette"]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: AnyCodingKey.self)
        id = try c.decode(UUID.self, forKey: AnyCodingKey("id"))
        name = try c.decode(String.self, forKey: AnyCodingKey("name"))
        styleID = try c.decode(String.self, forKey: AnyCodingKey("style"))
        palette = try c.decode(Palette.self, forKey: AnyCodingKey("palette"))
        extras = try c.unknownFields(besides: Self.known)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: AnyCodingKey.self)
        try c.encodeUnknownFields(extras)
        try c.encode(id, forKey: AnyCodingKey("id"))
        try c.encode(name, forKey: AnyCodingKey("name"))
        try c.encode(styleID, forKey: AnyCodingKey("style"))
        try c.encode(palette, forKey: AnyCodingKey("palette"))
    }
}
