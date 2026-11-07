import UIKit

/// Asks for a Look's name. Uses UIAlertController because a text field in a SwiftUI alert
/// takes on the current style's font and color; this one always looks like standard iOS.
@MainActor
enum NamePrompt {
    static func present(initialName: String, onSave: @escaping (String) -> Void) {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard var presenter = scene?.keyWindow?.rootViewController else { return }
        while let next = presenter.presentedViewController { presenter = next }

        let alert = UIAlertController(title: "Name this Look", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.text = initialName
            field.placeholder = "Name"
            field.clearButtonMode = .whileEditing
            field.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak alert] _ in
            onSave(alert?.textFields?.first?.text ?? "")
        })
        presenter.present(alert, animated: true)
    }
}
