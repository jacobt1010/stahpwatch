import Foundation

/// A named combination of dial style and colors. Exactly one is active, and editing the
/// style or colors changes it. The Dim Timer isn't part of a Look: it's about how the app
/// is used, not how it looks.
struct Look: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String
    var style: DialStyle
    var palette: Palette
}
