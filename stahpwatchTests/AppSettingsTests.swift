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

    private func encoded(_ palette: Palette) -> Data {
        try! JSONEncoder().encode(palette)
    }

    func testFreshInstall() {
        let s = AppSettings(defaults: defaults)
        XCTAssertEqual(ColorSetting.allCases.count + 1, 14, "13 colors plus the Dim Timer")
        XCTAssertEqual(s.looks.map(\.name), ["Look 1"])
        XCTAssertEqual(s.activeLook.id, s.looks[0].id)
        XCTAssertEqual(s.style, .paper)
        XCTAssertTrue(s.usesStyleColors)
        XCTAssertEqual(s.effectiveHex(.background), "#F2EBDD")
        XCTAssertEqual(s.effectiveHex(.secondHand), "#D4431C")
        XCTAssertEqual(s.dimMinutes, 10)
        XCTAssertFalse(s.matchesBackground(.customizeText))
        for text in [ColorSetting.startText, .pauseText, .playIcon, .stopIcon] {
            XCTAssertTrue(s.matchesBackground(text))
        }
    }

    func testEveryStylePaletteIsComplete() {
        for style in DialStyle.allCases {
            let palette = style.defaultPalette
            for setting in ColorSetting.allCases {
                XCTAssertNotNil(HexColor.normalized(palette.hexes[setting.rawValue] ?? ""), "\(style) \(setting)")
            }
        }
    }

    func testOriginalKeepsV1Colors() {
        let s = AppSettings(defaults: defaults)
        s.style = .original
        s.useStyleColors()
        XCTAssertEqual(s.effectiveHex(.background), "#000000")
        XCTAssertEqual(s.effectiveHex(.secondHand), "#FF8B00")
        XCTAssertEqual(s.effectiveHex(.play), "#4F7A5A")
        XCTAssertEqual(s.effectiveHex(.customizeText), "#000000")
    }

    func testEditsChangeTheActiveLook() {
        let s = AppSettings(defaults: defaults)
        s.setHex("#123456", for: .secondHand)
        XCTAssertEqual(s.looks[0].palette.hexes["secondHand"], "#123456")
        XCTAssertEqual(AppSettings(defaults: defaults).effectiveHex(.secondHand), "#123456")
    }

    func testChangingStyleKeepsColors() {
        let s = AppSettings(defaults: defaults)
        s.setHex("#123456", for: .secondHand)
        let background = s.effectiveHex(.background)
        s.style = .orbit
        XCTAssertEqual(s.activeLook.style, .orbit)
        XCTAssertEqual(s.effectiveHex(.secondHand), "#123456")
        XCTAssertEqual(s.effectiveHex(.background), background)
        XCTAssertFalse(s.usesStyleColors)
    }

    func testUseStyleColors() {
        let s = AppSettings(defaults: defaults)
        s.style = .orbit
        s.useStyleColors()
        XCTAssertEqual(s.effectiveHex(.background), "#0F1B2D")
        XCTAssertTrue(s.usesStyleColors)
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

    func testAddLookCopiesAndSwitches() {
        let s = AppSettings(defaults: defaults)
        s.setHex("#123456", for: .secondHand)
        s.dimMinutes = 25
        s.addLook(named: "  Night  ")
        XCTAssertEqual(s.looks.map(\.name), ["Look 1", "Night"])
        XCTAssertEqual(s.activeLook.name, "Night")

        s.setHex("#ABCDEF", for: .secondHand)
        XCTAssertEqual(s.looks[0].palette.hexes["secondHand"], "#123456", "the copy is independent")
        s.select(s.looks[0])
        XCTAssertEqual(s.effectiveHex(.secondHand), "#123456")
        XCTAssertEqual(s.dimMinutes, 25, "the Dim Timer isn't part of a Look")
    }

    func testActiveLookSurvivesRelaunch() {
        let s = AppSettings(defaults: defaults)
        s.addLook(named: "Second")
        s.style = .orbit

        let r = AppSettings(defaults: defaults)
        XCTAssertEqual(r.looks, s.looks)
        XCTAssertEqual(r.activeLook.name, "Second")
        XCTAssertEqual(r.style, .orbit)
    }

    func testDuplicate() {
        let s = AppSettings(defaults: defaults)
        s.addLook(named: "Other")
        s.duplicate(s.looks[0])
        XCTAssertEqual(s.looks.map(\.name), ["Look 1", "Look 1 Copy", "Other"])
        XCTAssertEqual(s.activeLook.name, "Look 1 Copy")
        s.duplicate(s.looks[0])
        XCTAssertTrue(s.looks.contains { $0.name == "Look 1 Copy 2" })
    }

    func testRename() {
        let s = AppSettings(defaults: defaults)
        s.rename(s.looks[0], to: "   ")
        XCTAssertEqual(s.looks[0].name, "Look 1", "a blank name is ignored")
        s.rename(s.looks[0], to: String(repeating: "x", count: 50))
        XCTAssertEqual(s.looks[0].name.count, 30)
    }

    func testDelete() {
        let s = AppSettings(defaults: defaults)
        s.addLook(named: "Two")
        s.addLook(named: "Three")
        s.delete(s.looks[1])
        XCTAssertEqual(s.looks.map(\.name), ["Look 1", "Three"])
        XCTAssertEqual(s.activeLook.name, "Three", "deleting another Look keeps the active one")

        s.delete(s.activeLook)
        XCTAssertEqual(s.activeLook.name, "Look 1", "deleting the active Look moves to a neighbor")

        s.delete(s.activeLook)
        XCTAssertEqual(s.looks.count, 1, "the last Look can't be deleted")
        XCTAssertEqual(AppSettings(defaults: defaults).looks.map(\.name), ["Look 1"])
    }

    func testDefaultLookNames() {
        let s = AppSettings(defaults: defaults)
        XCTAssertEqual(s.nextLookName, "Look 2")
        s.addLook(named: "")
        XCTAssertEqual(s.looks.last?.name, "Look 2")
        s.delete(s.looks[0])
        XCTAssertEqual(s.nextLookName, "Look 1")
    }

    func testMigratesSavedLooksAndCustomColors() {
        var custom = DialStyle.original.defaultPalette
        custom.hexes["secondHand"] = "#112233"
        var look = Look(name: "Saved", style: .paper, palette: DialStyle.paper.defaultPalette)
        look.palette.hexes["play"] = "#445566"
        defaults.set(try! JSONEncoder().encode([look]), forKey: "settings.looks")
        defaults.set(encoded(custom), forKey: "settings.palette.original")
        defaults.set(encoded(look.palette), forKey: "settings.palette.paper")
        defaults.set(encoded(DialStyle.block.defaultPalette), forKey: "settings.palette.block")
        defaults.set("paper", forKey: "settings.dialStyle")

        let s = AppSettings(defaults: defaults)
        XCTAssertEqual(s.looks.map(\.name), ["Saved", "My Original"], "only customized, unsaved colors get a Look")
        XCTAssertEqual(s.activeLook.name, "Saved", "the app keeps showing what it showed")
        XCTAssertEqual(s.looks[1].palette, custom)
        XCTAssertNil(defaults.object(forKey: "settings.palette.original"))
        XCTAssertNil(defaults.object(forKey: "settings.dialStyle"))
        XCTAssertEqual(AppSettings(defaults: defaults).looks.count, 2, "migrates once")
    }

    func testMigrationKeepsAWorkingStyleWithNoLook() {
        defaults.set("orbit", forKey: "settings.dialStyle")
        let s = AppSettings(defaults: defaults)
        XCTAssertEqual(s.looks.map(\.name), ["Look 1"])
        XCTAssertEqual(s.style, .orbit)
        XCTAssertEqual(s.effectiveHex(.background), "#0F1B2D")
    }

    func testV1ColorsBecomeALook() {
        defaults.set("#112233", forKey: "settings.color.background")
        defaults.set(false, forKey: "settings.match.pauseText")
        defaults.set("#445566", forKey: "settings.color.pauseText")

        let s = AppSettings(defaults: defaults)
        XCTAssertEqual(s.activeLook.style, .paper, "new default applies")
        let saved = s.looks.first { $0.name == "My Original" }
        XCTAssertEqual(saved?.style, .original)
        XCTAssertEqual(saved?.palette.hexes["background"], "#112233")
        XCTAssertEqual(saved?.palette.hexes["pauseText"], "#445566")
        XCTAssertNil(defaults.object(forKey: "settings.color.background"), "migrates once")
    }

    func testUnreadableLooksDontCrash() {
        defaults.set(Data("not json".utf8), forKey: "settings.looks")
        XCTAssertEqual(AppSettings(defaults: defaults).looks.count, 1)
    }

    func testHexRoundTrip() {
        XCTAssertEqual(HexColor.hex(from: Color(hex: "#D5CB88")), "#D5CB88")
        XCTAssertEqual(HexColor.normalized("ff8b00"), "#FF8B00")
        XCTAssertNil(HexColor.normalized("#12345"))
    }

    func testStatusBarFollowsBackground() {
        let s = AppSettings(defaults: defaults)
        XCTAssertFalse(s.backgroundIsDark, "Paper is light")
        s.setHex("#000000", for: .background)
        XCTAssertTrue(s.backgroundIsDark)
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
