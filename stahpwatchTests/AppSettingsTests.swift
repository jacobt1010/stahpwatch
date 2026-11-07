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
        XCTAssertEqual(s.style, .paper)
        XCTAssertEqual(s.effectiveHex(.background), "#F2EBDD")
        XCTAssertEqual(s.effectiveHex(.secondHand), "#D4431C")
        XCTAssertEqual(s.dimMinutes, 10)
        XCTAssertFalse(s.matchesBackground(.customizeText))
        for text in [ColorSetting.startText, .pauseText, .playIcon, .stopIcon] {
            XCTAssertTrue(s.matchesBackground(text))
        }
    }

    func testOriginalKeepsV1Colors() {
        let s = AppSettings(defaults: defaults)
        s.style = .original
        XCTAssertEqual(s.effectiveHex(.background), "#000000")
        XCTAssertEqual(s.effectiveHex(.secondHand), "#FF8B00")
        XCTAssertEqual(s.effectiveHex(.play), "#4F7A5A")
        XCTAssertEqual(s.effectiveHex(.customizeText), "#000000")
    }

    func testEveryStylePaletteIsComplete() {
        for style in DialStyle.allCases {
            let palette = style.defaultPalette
            for setting in ColorSetting.allCases {
                XCTAssertNotNil(HexColor.normalized(palette.hexes[setting.rawValue] ?? ""), "\(style) \(setting)")
            }
        }
    }

    func testEachStyleKeepsItsOwnColors() {
        let s = AppSettings(defaults: defaults)
        s.setHex("#123456", for: .secondHand)
        s.style = .block
        XCTAssertEqual(s.effectiveHex(.secondHand), "#E4FF4A")
        s.setHex("#654321", for: .secondHand)
        s.style = .paper
        XCTAssertEqual(s.effectiveHex(.secondHand), "#123456")

        let relaunched = AppSettings(defaults: defaults)
        XCTAssertEqual(relaunched.style, .paper)
        XCTAssertEqual(relaunched.effectiveHex(.secondHand), "#123456")
        relaunched.style = .block
        XCTAssertEqual(relaunched.effectiveHex(.secondHand), "#654321")
    }

    func testV1ColorsMoveToOriginal() {
        defaults.set("#112233", forKey: "settings.color.background")
        defaults.set(false, forKey: "settings.match.pauseText")
        defaults.set("#445566", forKey: "settings.color.pauseText")

        let s = AppSettings(defaults: defaults)
        XCTAssertEqual(s.style, .paper, "new default applies")
        XCTAssertEqual(s.effectiveHex(.background), "#F2EBDD")
        s.style = .original
        XCTAssertEqual(s.effectiveHex(.background), "#112233")
        XCTAssertEqual(s.effectiveHex(.pauseText), "#445566")
        XCTAssertNil(defaults.object(forKey: "settings.color.background"), "migrates once")
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
        s.setMatchesBackground(true, for: .customizeText)
        s.style = .orbit
        s.dimMinutes = 42
        s.resetToDefaults()
        XCTAssertEqual(s.style, .paper)
        for setting in ColorSetting.allCases where !setting.canMatchBackground {
            XCTAssertEqual(s.effectiveHex(setting), DialStyle.paper.defaultPalette.hexes[setting.rawValue], setting.title)
        }
        XCTAssertFalse(s.matchesBackground(.customizeText))
        XCTAssertEqual(s.dimMinutes, 10)
        XCTAssertEqual(AppSettings(defaults: defaults).effectiveHex(.background), "#F2EBDD")
    }

    func testHexRoundTrip() {
        XCTAssertEqual(HexColor.hex(from: Color(hex: "#D5CB88")), "#D5CB88")
        XCTAssertEqual(HexColor.normalized("ff8b00"), "#FF8B00")
        XCTAssertNil(HexColor.normalized("#12345"))
    }

    func testStatusBarFollowsBackground() {
        let s = AppSettings(defaults: defaults)
        XCTAssertFalse(s.backgroundIsDark, "Paper is light")
        s.style = .original
        XCTAssertTrue(s.backgroundIsDark)
        s.setHex("#F0F0F0", for: .background)
        XCTAssertFalse(s.backgroundIsDark)
    }

    func testPulseSwell() {
        XCTAssertEqual(DialRenderer.swell(tick: 2, elapsed: 2.5), 1, "the current second is full size")
        XCTAssertEqual(DialRenderer.swell(tick: 3, elapsed: 2.5), 0, "the next second hasn't started")
        XCTAssertEqual(DialRenderer.swell(tick: 2, elapsed: 3.2), 0.5, accuracy: 1e-9, "the last second is fading")
        XCTAssertEqual(DialRenderer.swell(tick: 2, elapsed: 3.5), 0, "the fade is over")
        XCTAssertEqual(DialRenderer.swell(tick: 59, elapsed: 0), 0, "no fading tick at 00:00")
        XCTAssertEqual(DialRenderer.swell(tick: 59, elapsed: 60.2), 0.5, accuracy: 1e-9, "fades across the minute")
        XCTAssertEqual(DialRenderer.swell(tick: 2, elapsed: 3602.5), 1, "works after an hour")
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
