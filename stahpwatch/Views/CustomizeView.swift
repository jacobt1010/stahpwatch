import SwiftUI

/// The 14 settings in three groups. Every change applies immediately and is saved.
struct CustomizeView: View {
    @Environment(AppSettings.self) private var settings
    let layout: Layout

    @State private var editing: ColorSetting?
    @State private var editingDimTimer = false
    @State private var confirmingReset = false

    var body: some View {
        let ink = settings.color(.fontTicks)
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header("Dial")
                ForEach(ColorSetting.allCases.filter { $0.group == .dial }) { colorRow($0) }
                header("Buttons")
                ForEach(ColorSetting.allCases.filter { $0.group == .buttons }) { colorRow($0) }
                header("Screen")
                dimTimerRow

                Button("Reset to defaults") { confirmingReset = true }
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(settings.color(.secondHand))
                    .padding(.top, 24)
                    .padding(.bottom, 8)
            }
            .padding(.leading, 36)
            .padding(.trailing, 24)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .foregroundStyle(ink)
        // End the list above the fixed Main Menu pill.
        .padding(.bottom, (Layout.pillHeight + Layout.bottomPad + 12) * layout.s)
        .sheet(item: $editing) { setting in
            ColorPickerSheet(title: setting.title, initial: settings.color(setting)) { color in
                settings.setColor(color, for: setting)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $editingDimTimer) {
            DimTimerPicker(minutes: Binding(get: { settings.dimMinutes }, set: { settings.dimMinutes = $0 }))
                .presentationDetents([.height(320)])
        }
        .alert("Reset all colors and the Dim Timer?", isPresented: $confirmingReset) {
            Button("Reset", role: .destructive) { settings.resetToDefaults() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func header(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold))
            .textCase(.uppercase)
            .opacity(0.6)
            .padding(.top, 14)
            .accessibilityAddTraits(.isHeader)
    }

    private func colorRow(_ setting: ColorSetting) -> some View {
        let matching = settings.matchesBackground(setting)
        return HStack(spacing: 16) {
            Button { editing = setting } label: {
                Swatch(fill: settings.color(setting), border: settings.color(.fontTicks))
            }
            .buttonStyle(PressDimStyle())
            .disabled(matching)
            .accessibilityLabel("\(setting.title) color")
            .accessibilityValue(matching ? "Matches background" : settings.effectiveHex(setting))

            Text(setting.title)
                .font(.system(size: 24, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityHidden(true)

            Spacer(minLength: 8)

            if setting.canMatchBackground {
                Toggle("Match Background", isOn: Binding(
                    get: { settings.matchesBackground(setting) },
                    set: { settings.setMatchesBackground($0, for: setting) }
                ))
                .labelsHidden()
                .tint(settings.color(.secondHand))
                .accessibilityLabel("\(setting.title) matches background")
            }
        }
    }

    private var dimTimerRow: some View {
        HStack(spacing: 16) {
            Button { editingDimTimer = true } label: {
                ZStack {
                    Swatch(fill: .clear, border: settings.color(.fontTicks))
                    Text(settings.dimMinutes == 0 ? "Off" : "\(settings.dimMinutes)")
                        .font(.system(size: 16, weight: .bold))
                        .minimumScaleFactor(0.6)
                }
            }
            .buttonStyle(PressDimStyle())
            .accessibilityLabel("Dim Timer")
            .accessibilityValue(settings.dimMinutes == 0 ? "Off" : "\(settings.dimMinutes) minutes")

            Text("Dim Timer")
                .font(.system(size: 24, weight: .bold))
                .accessibilityHidden(true)
        }
    }
}

/// A 45 × 45 square with a 4 pt border.
struct Swatch: View {
    let fill: Color
    let border: Color

    var body: some View {
        Rectangle()
            .fill(fill)
            .frame(width: 45, height: 45)
            .overlay(Rectangle().strokeBorder(border, lineWidth: 4))
            .contentShape(Rectangle())
    }
}
