import SwiftUI
import XCTest
@testable import stahpwatch

/// Renders the dial at 2× to a PNG for side-by-side comparison with Design/dial-reference.png.
/// Runs only when DIAL_SNAPSHOT_DIR is set, so it never writes files during normal test runs.
@MainActor
final class DialSnapshot: XCTestCase {
    func testRenderDial() throws {
        guard let dir = ProcessInfo.processInfo.environment["DIAL_SNAPSHOT_DIR"] else { throw XCTSkip("DIAL_SNAPSHOT_DIR not set") }
        let colors = DialColors(background: .black, fontTicks: .white, secondHand: Color(red: 1, green: 0x8B / 255, blue: 0))
        for (name, t) in [("dial-0", 0.0), ("dial-1937", 1937.5)] {
            let view = DialView(elapsed: { _ in t }, isRunning: false, colors: colors)
                .frame(width: 390, height: 414)
                .background(Color.black)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            let data = try XCTUnwrap(renderer.uiImage?.pngData())
            try data.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
    }
}
