import SwiftUI
import UIKit

/// Reports every touch anywhere in the window without interfering with it, so any touch
/// (not just a button tap) restarts the Dim Timer countdown.
struct TouchObserver: UIViewRepresentable {
    let onTouch: () -> Void

    func makeUIView(context: Context) -> InstallerView {
        let view = InstallerView()
        view.onTouch = onTouch
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: InstallerView, context: Context) {
        view.onTouch = onTouch
    }

    final class InstallerView: UIView {
        var onTouch: (() -> Void)? {
            didSet { recognizer.onTouch = onTouch }
        }
        private let recognizer = TouchDownRecognizer()

        override func didMoveToWindow() {
            super.didMoveToWindow()
            recognizer.view?.removeGestureRecognizer(recognizer)
            window?.addGestureRecognizer(recognizer)
        }
    }

    /// Fires on touch-down, then fails immediately so it never blocks other gestures.
    final class TouchDownRecognizer: UIGestureRecognizer {
        var onTouch: (() -> Void)?

        override init(target: Any? = nil, action: Selector? = nil) {
            super.init(target: target, action: action)
            cancelsTouchesInView = false
            delaysTouchesBegan = false
            delaysTouchesEnded = false
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            onTouch?()
            state = .failed
        }
    }
}
