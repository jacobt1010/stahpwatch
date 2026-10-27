import SwiftUI
import UIKit

/// iOS's built-in color picker (UIColorPickerViewController, the same picker SwiftUI's
/// `ColorPicker` presents) shown as a sheet from a square swatch, opacity off.
struct ColorPickerSheet: UIViewControllerRepresentable {
    let title: String
    let initial: Color
    let onChange: (Color) -> Void

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.title = title
        picker.supportsAlpha = false
        picker.selectedColor = UIColor(initial)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIColorPickerViewController, context: Context) {
        context.coordinator.onChange = onChange
    }

    func makeCoordinator() -> Coordinator { Coordinator(onChange: onChange) }

    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        var onChange: (Color) -> Void
        init(onChange: @escaping (Color) -> Void) { self.onChange = onChange }

        // Applies live while dragging, not only on dismiss.
        func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
            onChange(Color(uiColor: color))
        }
    }
}
