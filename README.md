# stahpwatch

A single-purpose analog stopwatch for iPhone: one big button, a dial drawn in code, fully custom colors, and a Lock Screen / Dynamic Island Live Activity. Swift + SwiftUI, iOS 17+, iPhone only, portrait only, no third-party packages. See [SPEC.md](SPEC.md) for the full design.

<p align="center">
  <img src="docs/idle.png" width="160" alt="Idle: dial at 00:00.00 with the Start button and Customize pill">
  <img src="docs/running.png" width="160" alt="Running: the hand sweeping at 07:41 with the Pause button">
  <img src="docs/paused.png" width="160" alt="Paused at 23:04.61 with green Play and red Stop buttons">
  <img src="docs/customize.png" width="160" alt="Customize: color swatches with Match Background toggles">
  <img src="docs/custom-colors.png" width="160" alt="A custom color scheme: navy background, cream dial and coral hand">
</p>
<p align="center"><sub>Idle · Running · Paused · Customize · Custom colors</sub></p>

<p align="center">
  <img src="docs/demo.gif" width="280" alt="Start, Pause, Play, Pause and Stop in sequence, with the hands sweeping smoothly">
</p>

## Build

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen) and isn't committed.

```bash
brew install xcodegen        # or download the release zip and put bin/xcodegen on your PATH
xcodegen generate
open stahpwatch.xcodeproj
```

### Signing (free personal team)

Personal signing details stay out of git. Copy the example config and fill in your values:

```bash
cp Config/Local.xcconfig.example Config/Local.xcconfig
```

- `DEVELOPMENT_TEAM`: your personal Team ID. If you don't know it, add your Apple ID in Xcode → Settings → Accounts, open the project, pick your Personal Team under the stahpwatch target's Signing & Capabilities, and read the ID back (it appears in the build settings as `DEVELOPMENT_TEAM`). Then put it in `Local.xcconfig` and run `xcodegen generate` again, so it survives regeneration.
- `BUNDLE_ID_PREFIX`: free teams need a globally unique bundle ID. The default is `com.jacobtehrani`.

The project uses no capabilities that need a paid account: no App Groups, push notifications or iCloud.

## Run on a physical iPhone

1. Connect the iPhone by cable (or on the same Wi-Fi once paired) and pick it as the run destination in Xcode.
2. **Turn on Developer Mode** on the iPhone: Settings → Privacy & Security → Developer Mode, then restart when asked.
3. Press Run in Xcode. The first install fails to open with an "Untrusted Developer" message.
4. **Trust your developer profile:** Settings → General → VPN & Device Management → your Apple ID → Trust.
5. Launch stahpwatch again.

**Free accounts expire after 7 days.** Apps signed with a free Apple account stop launching after 7 days. Reinstall from Xcode (just press Run again) to renew. Your settings and any running stopwatch are kept.

## Test

```bash
xcodebuild -project stahpwatch.xcodeproj -scheme stahpwatch \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

The tests cover elapsed-time math, every transition, saving and restoring state (including a simulated force-quit), readout formatting (including the one-hour switch), settings and Match Background, and the screen-awake hold rules.

`DialSnapshot` is skipped by default. Set `TEST_RUNNER_DIAL_SNAPSHOT_DIR=/some/dir` to render the dial at 2× for comparison with the Figma dial reference (frame `2:4` in the StopWatch file). That reference isn't published here; export it locally to `Design/dial-reference.png`, which git ignores. It also renders the Paused screen at iPhone SE (375 × 647) and Pro Max (440 × 868) safe-area sizes.

## Screenshots and demo

The images in `docs/` come from the iPhone 17 Simulator with the status bar set to 9:41 (`xcrun simctl status_bar booted override --time 9:41`). The demo GIF is a Simulator screen recording (`xcrun simctl io booted recordVideo demo.mov`) converted with:

```bash
swift Scripts/make_gif.swift demo.mov docs/demo.gif 320 15 1.6 31
```

The arguments are width, frames per second, and the start and end of the clip in seconds.

## App icon

`Scripts/make_icon.swift` draws the 1024 × 1024 icon with Core Graphics. It uses no SF Symbols, since Apple's license doesn't allow them in app icons. To change the icon, edit the script and run:

```bash
swift Scripts/make_icon.swift
```

## License

stahpwatch is released under the [MIT License](LICENSE). Copyright (c) 2026 Jacob Tehrani.

## Structure

| Path | What |
| --- | --- |
| `stahpwatch/Model/StopwatchState.swift` | Timestamp-only timing, transitions, UserDefaults store |
| `stahpwatch/Model/StopwatchModel.swift` | Observable source of truth shared by the UI and Live Activity intents |
| `stahpwatch/Model/AppSettings.swift` | The 14 settings, defaults, Match Background, reset |
| `stahpwatch/Model/ScreenAwakeController.swift` | Dim Timer hold and touch-reset countdown |
| `stahpwatch/Model/LiveActivityController.swift` | Starts, updates and ends the Live Activity |
| `stahpwatch/Views/` | `MainView`, `DialView` (Canvas in a TimelineView), `ControlsView`, `CustomizeView`, pickers |
| `Shared/` | Live Activity attributes and the Pause / Resume / Reset intents (compiled into both targets) |
| `LiveActivity/` | Widget extension: Lock Screen and Dynamic Island UI |

## Choices where the spec was silent

- **Color picker:** the swatch opens `UIColorPickerViewController` in a sheet. This is the same built-in picker SwiftUI's `ColorPicker` presents. It's used directly so the square 45 × 45 swatch can be the trigger, since `ColorPicker` always draws its own round well. Changes apply live while dragging.
- **Touch after the Dim Timer ran out:** a touch while Running or Paused starts a new hold, even if the previous countdown already handed control back to Auto-Lock.
- **Inactive scene** (Control Center, notification shade, app switcher) releases the hold. Returning starts a fresh one, as on unlock.
- **Status bar:** light text when white has more contrast on Background than black does (relative luminance below 0.179).
- **Readout hundredths** are truncated, not rounded.
- **Layout:** buttons scale with screen width. The dial scales with width too, but shrinks further on short screens (iPhone SE) so everything fits. Space for the "Paused" label and the Customize pill is always reserved, so the buttons never move between states.
- **Live Activity running time** counts up with `Text(timerInterval:)` over a one-year range.
- **Debug only:** launching with `-showCustomize` opens straight to Customize, for Simulator screenshots.
