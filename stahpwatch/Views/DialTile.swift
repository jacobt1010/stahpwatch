import SwiftUI

/// A small dial preview with a name, used for dial styles and saved Looks.
struct DialTile: View {
    let title: String
    let style: DialStyle
    let colors: DialColors
    let border: Color
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            DialView(style: style, elapsed: { _ in 42 }, isRunning: false, colors: colors)
                .frame(width: 84, height: 89)
                .background(colors.background)
                .overlay(Rectangle().strokeBorder(border, lineWidth: isSelected ? 4 : 1))
            Text(title)
                .font(.system(size: 15, weight: .bold, design: style.fontDesign))
                .lineLimit(1)
                .frame(width: 84)
        }
        // A preview shows its own style's font, not the one the app is currently using.
        .fontDesign(style.fontDesign)
    }
}
