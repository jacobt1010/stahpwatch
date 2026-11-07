import SwiftUI

/// A wheel with Off, then 1 to 60 minutes.
struct DimTimerPicker: View {
    @Binding var minutes: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Dim Timer").font(.headline)
                Spacer()
                Button("Done") { dismiss() }.font(.headline)
            }
            .padding()
            Picker("Dim Timer", selection: $minutes) {
                Text("Off").tag(0)
                ForEach(AppSettings.dimRange, id: \.self) { m in
                    Text(m == 1 ? "1 minute" : "\(m) minutes").tag(m)
                }
            }
            .pickerStyle(.wheel)
            Text("Keeps the screen awake this long while the stopwatch is running or paused. After that, your iPhone's Auto-Lock applies.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if minutes != AppSettings.defaultDimMinutes {
                Button("Reset to \(AppSettings.defaultDimMinutes) minutes") { minutes = AppSettings.defaultDimMinutes }
                    .font(.footnote.bold())
                    .padding(.top, 6)
            }
        }
    }
}
