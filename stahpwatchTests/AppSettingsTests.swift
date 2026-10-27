import SwiftUI
import XCTest
@testable import stahpwatch

final class AppSettingsTests: XCTestCase {
    var defaults: UserDefaults!
    let suite = "stahpwatch.tests.settings"

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    func testDefaults() {
        let s = AppSettings(defaults: defaults)
        XCTAssertEqual(ColorSetting.allCases.count + 1, 14, "13 colors plus the Dim Timer")
        XCTAssertEqual(s.effectiveHex(.background), "#000000")
        XCTAssertEqual(s.effectiveHex(.secondHand), "#FF8B00")
        XCTAssertEqual(s.effectiveHex(.play), "#4F7A5A")
        XCTAssertEqual(s.dimMinutes, 10)
        for text in [ColorSetting.startText, .pauseText, .playIcon, .stopIcon, .customizeText] {
            XCTAssertTrue(s.matchesBackground(text))
        }
    }

    func testMatchBackgroundFollowsLaterChanges() {
        let s = AppSettings(defaults: defaults)
        s.setHex("#123456", for: .background)
        XCTAssertEqual(s.effectiveHex(.startText), "#123456")
        s.setHex("#ABCDEF", for: .background)
        XCTAssertEqual(s.effectiveHex(.startText), "#ABCDEF")
    }

    func testTurningOffMatchStartsFromBackground() {
        let s = AppSettings(defaults: defaults)
        s.setHex("#224466", for: .background)
        s.setMatchesBackground(false, for: .pauseText)
        XCTAssertEqual(s.effectiveHex(.pauseText), "#224466")
        s.setHex("#FFFFFF", for: .background)
        XCTAssertEqual(s.effectiveHex(.pauseText), "#224466", "no longer follows Background")
    }

    func testSettingsSurviveRelaunch() {
        let s = AppSettings(defaults: defaults)
        s.setHex("#00FF00", for: .stop)
        s.setMatchesBackground(false, for: .stopIcon)
        s.setHex("#FF00FF", for: .stopIcon)
        s.dimMinutes = 0

        let r = AppSettings(defaults: defaults)
        XCTAssertEqual(r.effectiveHex(.stop), "#00FF00")
        XCTAssertFalse(r.matchesBackground(.stopIcon))
        XCTAssertEqual(r.effectiveHex(.stopIcon), "#FF00FF")
        XCTAssertEqual(r.dimMinutes, 0)
    }

    func testResetRestoresTable() {
        let s = AppSettings(defaults: defaults)
        s.setHex("#FFFFFF", for: .background)
        s.setMatchesBackground(false, for: .customizeText)
        s.dimMinutes = 42
        s.resetToDefaults()
        for setting in ColorSetting.allCases where !setting.canMatchBackground {
            XCTAssertEqual(s.effectiveHex(setting), setting.defaultHex, setting.title)
        }
        XCTAssertTrue(s.matchesBackground(.customizeText))
        XCTAssertEqual(s.dimMinutes, 10)
        XCTAssertEqual(AppSettings(defaults: defaults).effectiveHex(.background), "#000000")
    }

    func testHexRoundTrip() {
        XCTAssertEqual(HexColor.hex(from: Color(hex: "#D5CB88")), "#D5CB88")
        XCTAssertEqual(HexColor.normalized("ff8b00"), "#FF8B00")
        XCTAssertNil(HexColor.normalized("#12345"))
    }

    func testStatusBarFollowsBackground() {
        let s = AppSettings(defaults: defaults)
        XCTAssertTrue(s.backgroundIsDark)
        s.setHex("#F0F0F0", for: .background)
        XCTAssertFalse(s.backgroundIsDark)
    }
}

@MainActor
final class ScreenAwakeControllerTests: XCTestCase {
    func testHoldRules() async throws {
        var applied: [Bool] = []
        let c = ScreenAwakeController { applied.append($0) }

        c.update(eligible: false, minutes: 10)        // Idle never holds
        XCTAssertFalse(c.isHolding)
        c.update(eligible: true, minutes: 0)          // Off never holds
        XCTAssertFalse(c.isHolding)
        c.update(eligible: true, minutes: 10)
        XCTAssertTrue(c.isHolding)
        c.touched()
        XCTAssertTrue(c.isHolding)
        c.update(eligible: false, minutes: 10)        // Stop releases immediately
        XCTAssertFalse(c.isHolding)
        XCTAssertEqual(applied, [true, false])
    }
}
