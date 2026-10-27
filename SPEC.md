# stahpwatch — Build Spec

## Overview

stahpwatch is a single-purpose analog stopwatch for iPhone: one big button, a beautiful dial, fully custom colors, and nothing else. It replaces the Clock app's stopwatch for daily use and doubles as a portfolio piece.

**Goals**

- Start, pause, resume and reset with the fewest possible taps.
- Keep perfect time when the app is backgrounded or force-quit, at near-zero battery cost.
- Keep the screen awake for a user-set time (default 10 min) instead of iOS's usual shorter limit.
- Show and control the running stopwatch from the Lock Screen and Dynamic Island.
- Let every color be customized.

**Out of scope (intentionally):** laps, sounds, haptics, iPad, Apple Watch, landscape, iCloud sync, accounts, analytics.

**Platform:** native iOS first (Swift + SwiftUI, iPhone only, portrait only). A native Android port (Kotlin + Jetpack Compose) follows later from this same spec; see the last section.

**Design source:** Figma file [StopWatch](https://www.figma.com/design/UUMA01WU09GWTL5zVQEZLE/StopWatch?node-id=0-1). Frames: Idle `2:2`, Running `2:29`, Paused `2:52`, Customize `2:69`, Color picker `2:117`, dial reference image `2:4`. The mockup is the visual target, but this doc overrides it where they differ (the Running screen, the Play button, the removed outline, and the extra Customize settings).

**For Claude Code:** build in the order of the Acceptance checklist. Where this spec is silent, choose the simplest native iOS behavior and note the choice in the README.

## Screens and states

The app has one main screen that changes with the stopwatch state (Idle, Running, Paused), plus a Customize screen. Every screen fills its whole background with the **Background** color. The dial sits at the top of all three main states and never moves.

**Idle** (00:00.00, nothing running)

- Dial, readout at 00:00.00, all hands at 12 o'clock.
- **Start** button: wide, centered.
- **Customize** pill near the bottom: opens Customize.

**Running**

- One wide **Pause** button in the same spot and size as Start. It shows the word "Pause" only, no icon. This replaces the mockup's Pause + Stop pair.
- Customize is hidden.

**Paused**

- Two buttons side by side in the same row: **Play** (left, right-pointing triangle icon) and **Stop** (right, filled square icon). No outline on either. The mockup's white outline is removed.
- The word **Paused** below them, in the Pause color.
- Customize stays hidden.

**Customize**

- A scrolling list of settings (see Customization), with a **Reset to defaults** text button at the end of the list.
- A **Main Menu** pill fixed at the bottom, same style and position as the Customize pill. It returns to Idle.
- The mockup's separate color-picker page (frame `2:117`) is replaced by iOS's built-in color picker, which opens as a sheet when a swatch is tapped.

**Sizes** (points, measured on the 390 × 844 Figma frame; corner radius in the last column)

| Element | Size | Position | Text | Radius |
| --- | --- | --- | --- | --- |
| Dial area | 390 × 414 | top, below the status bar | see The dial | — |
| Start / Pause button | 282 × 106 | centered, top at y = 471 | 40 pt bold | 30 |
| Play button | 133 × 106 | left at x = 54, same row | icon about 40 pt | 30 |
| Stop button | 134 × 106 | left at x = 202 (15 pt gap) | 32 × 32 square icon | 30 |
| "Paused" label | full width | centered, top at y = 650 | 48 pt bold | — |
| Customize / Main Menu pill | 168 × 47 | centered, top at y = 744 | 20 pt bold | 30 |
| Customize swatch | 45 × 45 | rows on the left at x = 36 | — | 0, 4 pt border |

**Layout rules**

- Font: San Francisco (the system font), bold, everywhere. Do not bundle Inter.
- Lay out relative to the safe area, not with fixed y values. Keep the mockup's proportions: dial on top, button row about 57 pt below the dial, Paused label under the buttons, pill near the bottom.
- Buttons scale with screen width (Start = about 72 % of width). On the smallest supported iPhones (iPhone SE, 375 × 667) shrink the dial so everything fits without scrolling.
- Status bar text switches between light and dark automatically so it stays readable on the chosen Background color.
- Every button has a VoiceOver label (Start, Pause, Resume, Reset, Customize, Main Menu), and the readout is read aloud as the elapsed time.

## The dial

The dial must be drawn in code as vectors, not shipped as an image. The Figma frame holds a pasted image (node `2:4`) that serves only as the visual reference. Drawing it in code is what makes the Font & Ticks and Second Hand colors customizable, and keeps it sharp on every screen.

All measurements below are on the 390 × 414 reference canvas. Scale the whole dial uniformly to the available width.

**Main dial (seconds)**

- Center at (195, 209). Ticks run around the outer edge, outer end at radius 180.
- Minor ticks: 4 per second (240 total), about 9 pt long and 1 pt wide. Ticks on whole seconds are slightly longer than the quarter-second ticks.
- Major ticks: every 5 seconds (12 total), about 14 pt long and 2.5 pt wide.
- Numbers 5, 10 … 55, with 60 at the top: about 28 pt, regular weight, centered on radius 137, upright (not rotated).

**Sub-dial (minutes, 0–30)**

- Center at (195, 145), outer radius about 50.
- 60 minor ticks (one per 30 seconds) and longer major ticks every 5 minutes.
- Numbers 30 at the top, then 5, 10, 15, 20, 25 clockwise: about 14 pt, regular weight, centered on radius 27.
- After 30 minutes the hand keeps going and wraps around past the 30.

**Hands** (Second Hand color, drawn on top of everything)

- Main hand: about 2 pt wide. The tip reaches radius 180, and a tail runs 35 pt past the center. At the center sits a hollow ring, about 8 pt across with a 1.5 pt stroke, filled with the Background color.
- Sub-dial hand: about 2 pt wide, from the sub-dial center to about 45 pt out, with a solid dot about 5 pt across at its center.
- Both hands sweep smoothly, never in steps. Main hand angle = (elapsed seconds mod 60) / 60 × 360°. Sub-dial hand angle = (elapsed seconds mod 1800) / 1800 × 360°. Both start at 12 o'clock.

**Digital readout**

- Centered horizontally, about 71 pt below the main center (y ≈ 280). About 22 pt, regular weight, monospaced digits so it doesn't jitter.
- Format under an hour: `MM:SS.hh` (for example `07:42.18`). From an hour on: `H:MM:SS.hh` (for example `1:02:15.33`).

**Colors**

- Numbers, major ticks and readout use Font & Ticks.
- Minor ticks use Font & Ticks at about 45 % opacity, which reproduces the gray in the reference.
- Both hands and the center ring stroke and dot use Second Hand.

**Accuracy check:** Claude Code can read the Figma file directly if the Figma MCP server is connected to it. Otherwise, export frame `2:4` as a PNG into the project as `Design/dial-reference.png`. Compare the drawn dial side by side with the reference and adjust the numbers above until they match.

## Timing behavior

The stopwatch never counts in the background. It stores timestamps and computes the elapsed time whenever it needs to show it. This costs no battery while the app is closed and stays accurate through backgrounding, force-quit and restarts.

**Stored state** (saved to UserDefaults on every change, restored on launch)

- `state`: idle, running or paused
- `accumulated`: seconds banked before the current run
- `runStart`: the date the current run began (only while running)

Elapsed time = `accumulated` + (now − `runStart`) while running, or `accumulated` while paused. If the user changes the device clock and this comes out negative, clamp it to 0.

**Transitions** (one tap each, no confirmations)

| From | Tap | Becomes | What happens |
| --- | --- | --- | --- |
| Idle | Start | Running | `accumulated` = 0, `runStart` = now; start the Live Activity and the screen-awake countdown |
| Running | Pause | Paused | `accumulated` += now − `runStart`; update the Live Activity |
| Paused | Play | Running | `runStart` = now; update the Live Activity |
| Paused | Stop | Idle | Reset straight to 00:00.00; end the Live Activity; release the screen-awake hold |

Stop is only reachable from Paused, so resetting always takes two taps (Pause, then Stop). That built-in two-step is why Stop asks for no confirmation.

**After force-quit or restart:** reopening the app restores the saved state exactly. A running stopwatch is still running with the correct time, and a paused one is still paused.

**Drawing:** animate the dial and readout with SwiftUI's `TimelineView(.animation)`, which only redraws while the screen is on and the app is visible. No `Timer` and no background tasks.

## Customization

There are 14 settings in three groups. Every change applies immediately and is saved; there is no Save or Cancel. Defaults come from the Figma file, except Play, which is new.

| Group | Setting | Default | Used for |
| --- | --- | --- | --- |
| Dial | Background | `#000000` | Every screen's background, the hand's center ring fill |
| Dial | Font & Ticks | `#FFFFFF` | Dial numbers, ticks, readout, Customize screen text and swatch borders |
| Dial | Second Hand | `#FF8B00` | Both hands, center ring and dot |
| Buttons | Start | `#D9D9D9` | Start button |
| Buttons | Start Text | Match Background | The word "Start" |
| Buttons | Pause | `#D5CB88` | Pause button and the "Paused" label |
| Buttons | Pause Text | Match Background | The word "Pause" |
| Buttons | Play | `#4F7A5A` (dark green) | Play button |
| Buttons | Play Icon | Match Background | Play triangle |
| Buttons | Stop | `#BC5959` | Stop button |
| Buttons | Stop Icon | Match Background | Stop square |
| Buttons | Customize Btn | `#BDA69D` | Customize and Main Menu pills |
| Buttons | Customize Text | Match Background | The words "Customize" and "Main Menu" |
| Screen | Dim Timer | 10 min | See Screen awake |

The mockup's Pause Outline setting is removed.

**Match Background** (the four Text and Icon settings)

- Each has a Match Background toggle, on by default.
- While on, the element always uses the current Background color, even when Background changes later. The swatch shows the Background color and is not tappable.
- Turning it off makes the swatch tappable. The picker starts from the current Background color.

**Layout of the Customize screen**

- Section headers: Dial, Buttons, Screen. Scroll if the list is taller than the screen; the Main Menu pill stays fixed at the bottom.
- Each row: a 45 × 45 swatch with a 4 pt border in Font & Ticks, then the setting name in about 24 pt bold (smaller than the mockup's 32 pt so 14 rows fit). Text and Icon rows show their Match Background toggle at the right.
- Tapping a color swatch opens iOS's built-in color picker (SwiftUI `ColorPicker`, opacity off).
- The Dim Timer swatch shows the number of minutes ("10") or "Off". Tapping it opens a small sheet with a wheel: Off, then 1 to 60 minutes.
- **Reset to defaults** sits at the end of the list. It asks once ("Reset all colors and the Dim Timer?") and then restores every setting in the table above.

**Storage:** colors are saved as hex strings in UserDefaults (`@AppStorage`). The Lock Screen does not need them.

## Screen awake (Dim Timer)

While the stopwatch is running or paused, stahpwatch keeps the screen awake for the Dim Timer length (default 10 minutes). After that it hands control back to iOS, which dims and locks the screen according to the phone's own Auto-Lock setting. iOS doesn't let apps dim the screen themselves, so this hand-back is how "dim after N minutes" works.

- **Hold:** set `UIApplication.shared.isIdleTimerDisabled = true` and start an N-minute countdown.
- **Any touch restarts the countdown.** Catch touches app-wide (for example, a window-level touch observer), not just button taps.
- **Countdown ends:** set `isIdleTimerDisabled = false`. The phone then follows its normal Auto-Lock.
- **Applies only while Running or Paused.** In Idle and on the Customize screen, the hold is always released.
- **Stop** releases the hold immediately.
- **Returning to the app** (unlock, or switching back) while Running or Paused starts a fresh N-minute hold.
- **Off:** never hold the screen awake; the phone's Auto-Lock always applies.
- **Changing the Dim Timer** while a hold is active restarts the countdown with the new length.

If the phone's Auto-Lock is set to Never, the screen simply stays on; the app does nothing extra. Battery cost is mainly the screen itself. The dark default background on an OLED iPhone keeps that low.

## Lock Screen and Dynamic Island

A Live Activity shows the stopwatch on the Lock Screen and in the Dynamic Island, with buttons to control it without unlocking. It uses the standard system look, not the custom colors.

**Lifecycle:** start it on Start; update it on Pause and Play; end it immediately on Stop.

**What it shows**

| State | Time | Label | Buttons |
| --- | --- | --- | --- |
| Running | Live elapsed time, updated by iOS | — | Pause |
| Paused | Frozen elapsed time | Paused | Play, Stop |

- Running time uses SwiftUI's system timer text (`Text(timerInterval:countsDown: false)`, starting at `runStart − accumulated`). iOS updates it on its own with no app work. It shows `M:SS` / `H:MM:SS` without hundredths, which is a system limit and fine here.
- Lock Screen: a small stopwatch glyph, the time large, buttons on the right.
- Dynamic Island: compact = stopwatch glyph on the left, time (or frozen time) on the right; minimal = stopwatch glyph; expanded = time large with the buttons beneath.

**Buttons:** use `Button(intent:)` with three `LiveActivityIntent`s: Pause, Resume and Reset. They run inside the app's process and change the same stored state as the in-app buttons, so the app and the Lock Screen never disagree. Reset ends the Live Activity.

**Edge cases**

- iOS ends any Live Activity after about 8 hours. If that happens while the stopwatch is still running, the stopwatch keeps counting; opening the app starts a new Live Activity.
- If the user has turned Live Activities off for stahpwatch in Settings, the app works normally without it.
- After force-quit or restart, if the restored state is Running or Paused and no Live Activity exists, start one.

**Free Apple account:** no App Groups and no push notifications. Pass everything the Live Activity needs through its attributes and content state, and run the intents in the app, so it all works with a personal (free) development team. Add `NSSupportsLiveActivities = YES` to the app's Info.plist.

## iOS implementation notes

Build it in Swift and SwiftUI with no third-party packages, targeting iOS 17 and later (the earliest version with Lock Screen buttons).

**Project**

- App display name: **stahpwatch**. Bundle ID: `com.<owner>.stahpwatch`, where the owner supplies their own prefix.
- iPhone only, portrait only.
- Two targets: the app, and a widget extension for the Live Activity. The Live Activity attributes and the three intents are compiled into both targets.
- Prefer generating the project with XcodeGen (`project.yml`), so targets and settings live in a text file and no clicking in Xcode is needed. If XcodeGen can't be installed, have the owner create an empty iOS App project named stahpwatch in Xcode first and build inside it.
- Signing: automatic, using the owner's free personal team. Avoid any capability that needs a paid account (App Groups, push notifications, iCloud).
- Source control: initialize a git repository with a standard Swift/Xcode `.gitignore` (ignore `xcuserdata`, `DerivedData` and build output), and commit after each checklist item. The repository will be published to GitHub later as a portfolio piece, so keep personal signing details (the team ID) out of committed files where possible.

**Suggested structure**

- `StopwatchModel`: state, `accumulated`, `runStart`, transitions, persistence, elapsed-time math.
- `ScreenAwakeController`: the Dim Timer hold and the touch-reset countdown.
- `LiveActivityController`: starts, updates and ends the Live Activity.
- `Settings`: the 14 settings, defaults, Match Background logic, reset.
- Views: `MainView` (states), `DialView` (drawn with `Canvas` inside a `TimelineView`), `ControlsView`, `CustomizeView`, `DimTimerPicker`.
- Unit tests for elapsed-time math, every transition, saving and restoring state, and readout formatting (including the one-hour switch).

**App icon:** draw an original icon. It should be a simple stopwatch in the spirit of Apple's stopwatch, not a copy: for example, a white stopwatch outline with an orange hand on black, matching the app's defaults. Apple's license doesn't allow SF Symbols in app icons, so draw the shapes directly. Generate one 1024 × 1024 PNG with a script and keep the script in the repo so the icon can be tweaked later.

**README:** include how to build and run on a physical iPhone. Cover turning on Developer Mode (Settings → Privacy & Security), trusting the developer profile (Settings → General → VPN & Device Management), and the note that apps signed with a free account must be reinstalled from Xcode every 7 days.

## Acceptance checklist

Build in this order; each item should work on a real iPhone before moving on.

- [ ] Project builds and runs on the owner's iPhone with a free account; display name stahpwatch; portrait only
- [ ] Dial drawn in code matches the Figma reference side by side
- [ ] Idle → Start → Pause → Play → Stop works, and Stop resets straight to 00:00.00
- [ ] Hands sweep smoothly; the sub-dial wraps past 30 minutes; the readout switches to `H:MM:SS.hh` at one hour
- [ ] Time stays correct after backgrounding, force-quit and a phone restart, both while running and while paused
- [ ] Customize hidden while Running and Paused
- [ ] All 14 settings work, apply immediately and survive relaunch; Match Background follows later Background changes; Reset to defaults restores the table
- [ ] Screen stays awake for the Dim Timer length, any touch restarts it, Off never holds it, Idle never holds it
- [ ] Live Activity appears on Start; Pause, Play and Stop on the Lock Screen and Dynamic Island control the app; Stop removes it
- [ ] Layout fits without scrolling on iPhone SE and the largest Pro Max
- [ ] No sounds and no haptics anywhere
- [ ] Original app icon in place; README covers install and the 7-day reinstall
- [ ] Unit tests pass

## Android port notes (phase 2)

The Android version is a separate native app built later, in Kotlin with Jetpack Compose. It keeps every behavior, color default and measurement in this spec. Only the platform pieces below change.

| Piece | iOS | Android |
| --- | --- | --- |
| Font | San Francisco (system) | Roboto (system) |
| Dial drawing | SwiftUI `Canvas` | Compose `Canvas`, same geometry |
| Saved state and settings | UserDefaults | DataStore |
| Screen awake | `isIdleTimerDisabled` | `FLAG_KEEP_SCREEN_ON`, cleared after N minutes |
| Lock Screen control | Live Activity with buttons | Ongoing notification with a counting chronometer and Pause / Play / Stop actions; use Android's promoted live-update style where available |
| Color picker | iOS built-in `ColorPicker` | No system picker; a small custom HSV picker or a maintained library |
| Sharing with others | TestFlight or App Store (paid Apple account) | Signed APK shared directly, or Google Play |

Android 13 and later need the notification permission before the Lock Screen control can appear; ask for it the first time the user taps Start.
