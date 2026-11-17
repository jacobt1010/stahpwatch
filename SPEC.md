# stahpwatch — Spec

## Overview

stahpwatch is a single-purpose stopwatch for iPhone: one big button, a dial drawn in code, five dial styles, fully custom colors saved as Looks, and nothing else. It replaces the Clock app's stopwatch for daily use and doubles as a portfolio piece. The heart of the app: super customizable, yet reliably performant.

This document describes the app as built. It's detailed enough to rebuild it, including on Android (see the last section). Planned work lives in [ROADMAP.md](ROADMAP.md).

**Goals**

- Start, pause, resume and reset with the fewest possible taps.
- Keep perfect time when the app is backgrounded or force-quit, at near-zero battery cost.
- Keep the screen awake for a user-set time (default 10 min) instead of iOS's usual shorter limit.
- Show and control the running stopwatch from the Lock Screen and Dynamic Island.
- Let every color, and the dial itself, be customized, and let people save combinations as Looks.

**Not in the app today:** laps, sounds, haptics, iPad, Apple Watch, landscape, iCloud sync, accounts, analytics. Some of these are on the roadmap.

**Platform:** native iOS (Swift + SwiftUI, iPhone only, portrait only, iOS 17 and later). A native Android port (Kotlin + Jetpack Compose) is planned; see the last section.

**Design history:** v1 was built from the Figma file [StopWatch](https://www.figma.com/design/UUMA01WU09GWTL5zVQEZLE/StopWatch?node-id=0-1) (frames: Idle `2:2`, Running `2:29`, Paused `2:52`, Customize `2:69`, Color picker `2:117`, dial reference image `2:4`). That design survives as the **Original** dial style and its colors. **Paper** is now the default. Where this spec and the Figma file differ, this spec wins.

**Where the spec is silent:** choose the simplest native platform behavior and note the choice in the README.

## Screens and states

The app has one main screen that changes with the stopwatch state (Idle, Running, Paused), plus a Customize screen. Every screen fills its whole background with the active Look's **Background** color. The dial sits at the top of all three main states and never moves.

**Idle** (00:00.00, nothing running)

- Dial at zero, with all hands (or the style's equivalent) at 12 o'clock.
- **Start** button: wide, centered.
- **Customize** icon button at the bottom center: opens Customize.

**Running**

- One wide **Pause** button in the same spot and size as Start, showing the word "Pause" only.
- The Customize button is hidden, but its space is kept so nothing shifts.

**Paused**

- Two buttons side by side in the same row: **Play** (left, filled right-pointing triangle) and **Stop** (right, filled square). No outlines.
- The word **Paused** below them, in the Pause color.
- The Customize button stays hidden.

**Customize**

- A scrolling list (see Customize screen), ending in a **Delete This Look** text button when more than one Look exists.
- A **Done** icon button (checkmark), fixed in the same spot as the Customize button. It returns to Idle.
- Color swatches open the platform's built-in color picker as a sheet.

**Sizes** (points on a 390-point-wide reference frame; everything scales, see Layout)

| Element | Size | Text or icon | Corner radius |
| --- | --- | --- | --- |
| Dial area | 390 × 414 | see Dial styles | — |
| Start / Pause button | 282 × 106 | 40 pt bold | style's button radius |
| Play button | 133 × 106 | play icon about 40 pt | style's button radius |
| Stop button | 134 × 106, 15 pt gap from Play | 32 × 32 square | style's button radius |
| "Paused" label | full width × 58 | 48 pt bold, Pause color | — |
| Customize / Done icon button | 80 × 47, never smaller than 44 × 44 | 22 pt semibold `paintpalette` / `checkmark` | style's button radius |
| Customize swatch | 45 × 45 | — | 0, 4 pt border |

All button text uses the active dial style's font design (see Dial styles), bold.

**Layout**

Lay everything out inside the safe area. Let `W` and `H` be the safe area's width and height.

- Width scale `s = W / 390`. Buttons, text, gaps and corner radii all scale by `s`.
- Vertical stack, top to bottom: dial; gap `57·s`; button row `106·s`; gap `73·s`; "Paused" label `58·s`; flexible space (at least `8·s`); Customize/Done button `47·s`; bottom padding `12·s`.
- Everything except the dial takes `361·s`. Dial scale = `min(s, max(0.5, (H − 361·s) / 414))`. The dial is `390 × 414` times that scale, centered horizontally. On short phones (iPhone SE) the dial shrinks so nothing scrolls.
- The "Paused" label's space and the Customize button's space are always reserved, so the buttons never move between states.
- The keyboard never pushes the layout up.

**Status bar:** light text when the Background's relative luminance (WCAG) is below 0.179, which is when white has more contrast than black; dark text otherwise.

**Accessibility:** VoiceOver labels are Start, Pause, Resume (Play), Reset (Stop), Customize and Done. The dial reads as "Elapsed time" with the spoken time ("1 hour, 2 minutes, 15 seconds") and updates frequently. Style tiles read as "<Name> dial style", and Look tiles as "<Name> Look" with Rename, Duplicate and Delete actions. The selected tile has the selected trait.

## Dial styles

There are five styles: **Paper** (default), **Original**, **Pulse**, **Orbit** and **Block**. A style decides the dial drawing, the font design used across the app, and the corner radius of every button. Colors come from the active Look, not the style. Each style also has a default palette, which Use Default Colors applies.

| Style | Font design | Dial numbers | Digital time | Button radius (×s) |
| --- | --- | --- | --- | --- |
| Paper | Serif (New York) | 28 pt regular serif, 12 numbers | 22 pt regular serif, one size including hundredths | 15 |
| Original | Default (San Francisco) | 28 pt regular; sub-dial 15 pt | 22 pt regular, one size | 30 |
| Pulse | Rounded | none | `MM:SS` 60 pt semibold (44 pt from an hour on) + `.hh` 26 pt medium | 34 |
| Orbit | Rounded | none | same as Pulse | 50 (fully rounded) |
| Block | Monospaced | 39 pt bold mono, 4 numbers | 24 pt bold mono, one size | 8 |

Every readout uses monospaced digits so it doesn't jitter.

### Shared geometry

- Draw on a 390 × 414 reference canvas and scale it uniformly to fit. Main center **(195, 209)**.
- Angles are in turns: 0 = 12 o'clock, clockwise. A point at `turn` and `radius` from center `(cx, cy)` is `(cx + sin(2π·turn)·radius, cy − cos(2π·turn)·radius)`.
- Main turn = `(elapsed mod 60) / 60`. Sub-dial turn = `(elapsed mod 1800) / 1800`, so the sub-dial wraps past 30 minutes. Everything sweeps smoothly, never in steps.
- **Readout format:** `MM:SS.hh` under an hour (`07:42.18`), `H:MM:SS.hh` from an hour on (`1:02:15.33`). Hundredths are truncated, not rounded.
- **Ink** below means the Font & Ticks color, and **accent** means the Second Hand color.
- **Performance:** draw the parts that never move (the face) once, in a layer that redraws only when the style or colors change. Redraw only the moving parts each frame, and only while the screen is on and the app is visible (SwiftUI `TimelineView(.animation)`; no timers, no background work).

### Paper (default)

- Outer circle, radius 174, 1 pt ink.
- 60 ticks, outer end at radius 169: majors every 5 s, 18 long and 2 wide; minors 8 long and 0.8 wide. All ink.
- Numbers 5 … 60 (60 at the top), 28 pt serif regular, centered on radius 122, upright.
- Sub-dial (minutes, 0–30): center (195, 273), circle radius 31 at 1 pt, 6 ticks every 5 minutes (6 long, 1.2 wide, outer end on the circle). No numbers.
- Digital time: 22 pt serif regular, centered at y = 149 (above the center), ink. One size, hundredths included.
- Sub-dial hand: accent, 1.5 wide, round cap, from the sub-dial center to radius 23.
- Main hand: accent, 1.6 wide, from radius 44 on the tail side to radius 164. Counterweight disc, radius 6.5, at the tail end. Center dot, radius 4.

### Original (the v1 Figma dial)

- 240 ticks (quarter seconds), outer end at radius 180. Majors every 5 s: 14 long, 2.5 wide, ink. Whole seconds: 12 long. Quarter seconds: 7 long. Both are 2 wide, ink at 38 % opacity.
- Numbers 5 … 55 with 60 at the top, 28 pt regular, centered on radius 137.
- Sub-dial: center (195, 145), 60 ticks with outer end at radius 50. Majors every 5 minutes: 10 long, 2 wide, ink. Minors: 7 long, 1.5 wide, ink at 38 %. Numbers 30 (top), 5, 10, 15, 20, 25 clockwise, 15 pt, on radius 27.
- Digital time: 22 pt regular, centered at y = 280.
- Sub-dial hand: accent, 2 wide, round cap, to radius 45, with a center dot of radius 3.
- Main hand: accent, 2 wide, from radius 35 on the tail side to radius 180. Hollow center ring: radius 4, Background fill, 1.5 pt accent stroke.

### Pulse

- No hand: the tick for the current second swells instead.
- 60 ticks, outer end at radius 174, round caps. At rest: majors (every 5 s) 20 long and 3.4 wide, in ink; minors 12 long and 2 wide, in ink at 35 %.
- **Swell** `s` (0…1) for tick `i` at elapsed time `t`: let `age = (t − i) mod 60`, wrapped into 0…60. `s = 1` when `age < 1`. Otherwise, if `t ≥ 1` and `age < 1.4`, `s = 1 − (age − 1) / 0.4`, a 0.4 s fade. Otherwise `s = 0`. A swollen tick is `+39·s` longer and `+5.8·s` wider, and is drawn in accent while `s > 0`. This depends only on elapsed time, so it stays correct after a pause or relaunch.
- Large readout (shared with Orbit): `MM:SS` (or `H:MM:SS`) at y = 197 in ink, 60 pt semibold rounded (44 pt from an hour on). `.hh` below at y = 248 in accent, 26 pt medium rounded.

### Orbit

- No hand: a ring fills over each minute.
- Track: circle of radius 164, 20 wide, ink at 14 %.
- Progress arc: the same circle in accent, 20 wide with round caps, from 12 o'clock clockwise through the main turn. It isn't drawn below a turn of 0.001.
- Minute dots: 30 dots of radius 3 on radius 133. Dot `i` (from 12 o'clock, clockwise) is accent when `i ≤ floor(elapsed / 60) mod 30`, otherwise ink at 25 %.
- Large readout: as in Pulse.

### Block

- 12 ticks, outer end at radius 179, ink. At 12, 3, 6 and 9 o'clock: 39 long and 13 wide. The others: 20 long and 8 wide.
- Numbers 60, 15, 30, 45 at the four quarters, 39 pt bold monospaced, on radius 101.
- Hand: a filled accent wedge with its tip at radius 177 and its base corners at radius 21, a quarter turn either side of the tip. Plus an accent hub disc of radius 21.
- Digital time: 24 pt bold monospaced, centered at y = 262, drawn after the wedge on a Background-colored plate (text size plus 8 horizontal and 3 vertical padding), so it's never covered.

### Default palettes

The text and icon settings are **Match** (they follow Background) unless a color is given.

| Setting | Paper | Original | Pulse | Orbit | Block |
| --- | --- | --- | --- | --- | --- |
| Background | `#F2EBDD` | `#000000` | `#17121F` | `#0F1B2D` | `#121212` |
| Font & Ticks | `#1F1C18` | `#FFFFFF` | `#F3EEF8` | `#EAF2F8` | `#F2F2F2` |
| Second Hand | `#D4431C` | `#FF8B00` | `#FF5FA2` | `#5FE3C0` | `#E4FF4A` |
| Start | `#1F1C18` | `#D9D9D9` | `#FF5FA2` | `#5FE3C0` | `#E4FF4A` |
| Start Text | Match | Match | Match | Match | Match |
| Pause | `#A9782A` | `#D5CB88` | `#E8C26A` | `#F5C76B` | `#F2F2F2` |
| Pause Text | Match | Match | Match | Match | Match |
| Play | `#3F6B52` | `#4F7A5A` | `#4FD1A5` | `#4FC3F7` | `#6CFF8F` |
| Play Icon | Match | Match | Match | Match | Match |
| Stop | `#D4431C` | `#BC5959` | `#FF6B5B` | `#FF7A6B` | `#FF4D3D` |
| Stop Icon | Match | Match | Match | Match | Match |
| Customize Button | `#DDD3BF` | `#BDA69D` | `#30273D` | `#24344D` | `#2B2B2B` |
| Customize Icon | `#1F1C18` | Match | `#F3EEF8` | `#EAF2F8` | `#F2F2F2` |

Original's palette is the v1 Figma defaults, plus Play `#4F7A5A`, which v1 added.

## Timing behavior

The stopwatch never counts in the background. It stores timestamps and computes the elapsed time whenever it needs to show it. This costs no battery while the app is closed and stays accurate through backgrounding, force-quit and restarts.

**Stored state** (saved on every change, restored on launch)

- `state`: idle, running or paused
- `accumulated`: seconds banked before the current run
- `runStart`: the date the current run began (only while running)

Elapsed time = `accumulated` + (now − `runStart`) while running, `accumulated` while paused, and 0 while idle. If the device clock changes and the result is negative, clamp it to 0. A saved "running" state with no `runStart` loads as paused.

**Transitions** (one tap each, no confirmations; any other tap is ignored)

| From | Tap | Becomes | What happens |
| --- | --- | --- | --- |
| Idle | Start | Running | `accumulated` = 0, `runStart` = now; start the Live Activity and the screen-awake hold |
| Running | Pause | Paused | `accumulated` += now − `runStart`; update the Live Activity |
| Paused | Play | Running | `runStart` = now; update the Live Activity |
| Paused | Stop | Idle | Reset straight to 00:00.00; end the Live Activity; release the screen-awake hold |

Stop is only reachable from Paused, so resetting always takes two taps (Pause, then Stop). That built-in two-step is why Stop asks for no confirmation.

**After force-quit or restart:** reopening the app restores the saved state exactly. A running stopwatch is still running with the correct time, and a paused one is still paused.

## Looks

A **Look** is a named combination of one dial style and a full palette (the 13 color settings, including each Match Background toggle). Exactly one Look is active at all times. The Dim Timer is not part of a Look.

**Editing is live.** Changing any color, toggle or the dial style edits the active Look and saves immediately. There is no Save or Cancel.

- **Changing the dial style keeps the Look's colors.** The style tiles preview each style in the active Look's colors, so a tile shows exactly what tapping it gives.
- **Use [Style]'s Default Colors** (for example "Use Orbit's Default Colors") replaces the active Look's palette with its style's default palette. It appears only when the palette differs from those defaults, and asks first: "Replace this Look's colors with Orbit's defaults?" (Replace / Cancel).

**Managing Looks**

- **Select:** tap a Look tile. The whole app switches immediately.
- **New:** the first tile (a plus, labeled New). It asks for a name, prefilled with the first unused "Look N", then adds a copy of the active Look right after it and makes the copy active.
- **Duplicate** (long-press menu): adds a copy of that Look right after it, named "<Name> Copy", then "<Name> Copy 2" and so on if that's taken, and makes it active. The base name is cut to 23 characters so the result fits.
- **Rename** (long-press menu): asks for a name, prefilled with the current one.
- **Delete:** from the long-press menu or the **Delete This Look** button at the bottom of Customize (which deletes the active Look). Both ask first: "Delete <Name>?" (Delete / Cancel). Deleting the active Look switches to the next Look, or the previous one if it was last. The last remaining Look can't be deleted: neither the menu item nor the button appears.
- **A style from a newer version** shows as Paper, with its saved style kept (see Storage).
- **Names:** trimmed of surrounding spaces and limited to 30 characters. A blank name is ignored (a new Look gets the default name instead). Duplicate names are allowed.
- **The name prompt** is the platform's standard alert with a text field (title "Name this Look", Cancel / Save). It always uses the system font and colors, whatever the active style.

**First launch:** one Look, "Look 1", in Paper with Paper's default palette.

**Migration from older versions** (runs once, when no active Look is saved):

- v1 colors (`settings.color.<setting>` and `settings.match.<setting>`) become a palette over Original's defaults.
- Pre-Looks per-style colors (`settings.palette.<style>`) are read.
- Every per-style palette that differs from its style's defaults, and isn't already a saved Look, becomes a Look named "My <Style>" (for example "My Original").
- The style that was showing (`settings.dialStyle`, default Paper) with its colors becomes the active Look: an existing Look if one matches exactly, otherwise a new "Look N".
- The old keys are then removed.

## Customize screen

A scrolling list on the Background color, in the style's font design, with Font & Ticks text. The Done button stays fixed at the bottom, and the list ends above it. Sections, in order:

1. **Looks:** a horizontal row of tiles. The New tile comes first, then the saved Looks.
2. **Style:** a horizontal row of the five style tiles, then the Use Default Colors button when shown (17 pt bold, Second Hand color).
3. **Dial:** Background, Font & Ticks, Second Hand.
4. **Buttons:** Start, Start Text, Pause, Pause Text, Play, Play Icon, Stop, Stop Icon, Customize Button, Customize Icon.
5. **Screen:** Dim Timer.
6. **Delete This Look** (20 pt bold, Stop color), only when more than one Look exists.

**Section headers:** 17 pt bold, uppercase, Font & Ticks at 60 % opacity.

**Tiles** (Looks and styles): an 84 × 89 dial preview on its own background with a Font & Ticks border, 1 pt or 4 pt when selected. The name is underneath, in 15 pt bold in that tile's own style font, on one line. The selected Look tile is the active Look; the selected style tile is the active Look's style.

**Color rows:** a 45 × 45 swatch with a 4 pt Font & Ticks border, then the setting name in 24 pt bold (shrinking to 70 % if needed). The five Text/Icon rows end with a Match Background toggle, tinted Second Hand.

- **Match Background on:** the element always uses the current Background color, even after Background changes. The swatch shows the Background color and can't be tapped.
- **Match Background off:** the swatch can be tapped. Turning the toggle off starts the color at the current Background color.
- **Tapping a swatch** opens the built-in color picker (opacity off). Changes apply live while dragging.

**Dim Timer row:** the swatch shows the minutes ("10") or "Off". Tapping it opens a small sheet with a wheel (Off, then 1 to 60 minutes), a short explanation, and "Reset to 10 minutes" when it isn't already 10.

**Settings count:** 13 color settings per Look, plus the Dim Timer, makes 14 settings. The dial style and saved Looks are on top of that.

| Group | Setting | Used for |
| --- | --- | --- |
| Dial | Background | Every screen's background; the Original hand's center ring fill; the Block readout plate |
| Dial | Font & Ticks | Dial numbers, ticks and readout; Customize text, tile borders and swatch borders |
| Dial | Second Hand | Hands, Pulse's swelling tick, Orbit's ring and dots, Customize toggles and the Use Default Colors button |
| Buttons | Start / Start Text | Start button and its word |
| Buttons | Pause / Pause Text | Pause button, the "Paused" label, and the word "Pause" |
| Buttons | Play / Play Icon | Play button and its triangle |
| Buttons | Stop / Stop Icon | Stop button, its square, and the Delete This Look button |
| Buttons | Customize Button / Customize Icon | The Customize and Done icon buttons and their glyphs |
| Screen | Dim Timer | See Screen awake |

## Screen awake (Dim Timer)

While the stopwatch is running or paused, stahpwatch keeps the screen awake for the Dim Timer length (default 10 minutes). After that it hands control back to the system, which dims and locks the screen according to the phone's own Auto-Lock setting. Apps can't dim the screen themselves, so this hand-back is how "dim after N minutes" works.

- **Hold:** set `UIApplication.shared.isIdleTimerDisabled = true` and start an N-minute countdown.
- **Any touch restarts the countdown,** including a touch after a countdown already ended. Touches are caught app-wide with a window-level touch observer that never blocks other gestures, not just button taps.
- **Countdown ends:** set `isIdleTimerDisabled = false`. The phone then follows its normal Auto-Lock.
- **Applies only while Running or Paused, on the main screen, with the app active.** In Idle, on the Customize screen, and while the app is inactive or in the background, the hold is released.
- **Stop** releases the hold immediately.
- **Returning to the app** (unlock, or switching back) while Running or Paused starts a fresh hold.
- **Off:** never hold the screen awake.
- **Changing the Dim Timer** while a hold is active restarts the countdown with the new length.

## Lock Screen and Dynamic Island

A Live Activity shows the stopwatch on the Lock Screen and in the Dynamic Island, with buttons to control it without unlocking. It uses the standard system look, not the Look's colors.

**Lifecycle:** start it on Start; update it on Pause and Play; end it immediately on Stop. Whenever the app becomes active, bring it in line with the stored state: start one if Running or Paused and none is active, update it otherwise, and end any extras.

**What it shows**

| State | Time | Label | Buttons |
| --- | --- | --- | --- |
| Running | Live elapsed time, updated by the system | — | Pause |
| Paused | Frozen elapsed time (`M:SS` or `H:MM:SS`) | Paused | Play, Stop |

- Running time uses the system's counting timer text (`Text(timerInterval:countsDown: false)` from `runStart − accumulated`), so the app does no work. It shows no hundredths, which is a system limit.
- **Lock Screen:** a stopwatch glyph, the time large, buttons on the right.
- **Dynamic Island:** compact = stopwatch glyph left, time right; minimal = stopwatch glyph; expanded = time large with the buttons beneath.

**Buttons:** three `LiveActivityIntent`s, Pause, Resume and Reset. They run inside the app's process and change the same stored state as the in-app buttons, so the app and the Lock Screen never disagree. Reset ends the Live Activity.

**Edge cases**

- The system ends any Live Activity after about 8 hours. The stopwatch keeps counting, and opening the app starts a new one.
- If Live Activities are turned off for stahpwatch, the app works normally without them.

**Free Apple account:** no App Groups and no push notifications. Everything the Live Activity needs travels in its content state, and the intents run in the app. Info.plist has `NSSupportsLiveActivities = YES`.

## Storage

All in UserDefaults:

| Key | Contents |
| --- | --- |
| `stopwatch.state` | `idle`, `running` or `paused` |
| `stopwatch.accumulated` | seconds (double) |
| `stopwatch.runStart` | date, only while running |
| `settings.looks` | JSON array of Looks |
| `settings.activeLook` | the active Look's UUID string |
| `settings.dimMinutes` | integer; 0 = Off |
| `settings.looks.unreadableBackup` | Looks data that couldn't be read at all, kept before it was replaced |

A Look in JSON looks like this:

```json
{ "id": "UUID", "name": "Look 1", "style": "paper",
  "palette": { "hexes": { "background": "#F2EBDD", "...": "..." },
               "matches": { "startText": true, "...": "..." } } }
```

Palette keys are the setting identifiers: `background`, `fontTicks`, `secondHand`, `start`, `startText`, `pause`, `pauseText`, `play`, `playIcon`, `stop`, `stopIcon`, `customize`, `customizeText`. Colors are uppercase `#RRGGBB` in sRGB. A missing color falls back to the style's default.

**Forward compatibility.** Every version must keep, and never destroy, saved data it doesn't understand. That way, installing an older version over a newer one's data loses nothing:

- **Unknown fields** in a Look or its palette, and unknown color keys, are kept and written back unchanged on every save.
- **An unknown dial style** keeps the Look. It's drawn as Paper, but the saved style name stays until the user picks a style for that Look.
- **A Look that can't be read at all** (for example, a missing name) isn't shown, but every save writes it back exactly as found. Other Looks still load.
- **If the active Look can't be shown,** the first Look that can becomes active. If none can, a fresh "Look 1" is added, and the unreadable ones are kept alongside it.
- **Data that isn't a list of Looks at all** is copied to `settings.looks.unreadableBackup` before a fresh "Look 1" replaces it.
- **An unknown stopwatch state** keeps its time: it counts if a `runStart` is saved, and is paused otherwise. Nothing is written back until the stopwatch is used.
- **Never rename or reuse a key, or change the meaning of a value.** Add new keys instead.

v1.1 predates these rules. It replaces all Looks if any Look is unreadable or uses an unknown style, and drops unknown Look fields when it opens. Downgrading to v1.1 from a version that adds styles or Look fields loses Looks.

## iOS implementation notes

Swift and SwiftUI, no third-party packages, iOS 17 and later.

**Project**

- Display name **stahpwatch**; bundle ID `$(BUNDLE_ID_PREFIX).stahpwatch`. The prefix and the personal team come from the git-ignored `Config/Local.xcconfig`.
- iPhone only, portrait only. The launch screen is Paper's cream.
- Three targets, generated by XcodeGen from `project.yml`: the app; a widget extension for the Live Activity; and unit tests. The Live Activity attributes and the three intents are compiled into both the app and the extension. The extension has a stub for the intents' actions.
- Automatic signing with a free personal team. No capability that needs a paid account.

**Structure**

- `StopwatchState` / `StopwatchStore` / `StopwatchModel`: timing, transitions, persistence. The model is shared by the UI and the intents.
- `JSONValue`: holds saved data this version doesn't understand, so it can be written back unchanged.
- `AppSettings`: Looks, the active Look, colors and Match Background, migration.
- `DialStyle` and `Look`: style metadata and default palettes; the saved Look.
- `ScreenAwakeController`, `LiveActivityController`.
- Views: `MainView`, `ControlsView` (including `IconButton`), `DialView` (a static face Canvas under a live Canvas in a `TimelineView`), `DialRenderer` (all five styles), `CustomizeView`, `LooksRow`, `DialTile`, `ColorPickerSheet`, `DimTimerPicker`, `NamePrompt`, `TouchObserver`.
- Unit tests for elapsed-time math, every transition, saving and restoring state, readout formatting (including the one-hour switch), Looks (new, duplicate, rename, delete, live edits, default colors, migration, and data from newer versions), Pulse's swell, the screen-awake rules, and the icon button's minimum size. An opt-in snapshot test renders every style, and the Idle and Paused screens at iPhone SE and Pro Max sizes.

**App icon:** Instrument, a simplified Paper dial: cream background, ink ring with 12 ticks, a vermilion hand with a counterweight. It's drawn by `Scripts/make_icon.swift`, with no SF Symbols (Apple's license excludes them from app icons). It's a placeholder until the owner designs a final icon.

**README:** covers building, installing on a physical iPhone (Developer Mode, trusting the developer profile, the 7-day reinstall for free accounts), tests, screenshots and the demo GIF.

## Acceptance checklist

- [x] Builds and runs on a physical iPhone with a free account; display name stahpwatch; portrait only
- [x] Idle → Start → Pause → Play → Stop works, and Stop resets straight to 00:00.00
- [x] Hands sweep smoothly; the sub-dial wraps past 30 minutes; the readout switches to `H:MM:SS.hh` at one hour
- [ ] Time stays correct after backgrounding, force-quit and a phone restart, both running and paused (backgrounding and force-quit are covered by tests; a phone restart hasn't been confirmed on a device)
- [x] The Customize button is hidden while Running and Paused, and nothing shifts between states
- [x] All five styles draw as specified; Paper is the default
- [x] Looks: live edits, New, Duplicate, Rename, Delete (both entry points), Use Default Colors; everything survives relaunch; older data migrates without loss
- [x] Screen stays awake for the Dim Timer length, any touch restarts it, Off never holds it, Idle never holds it
- [ ] Live Activity appears on Start; Pause, Play and Stop on the Lock Screen and Dynamic Island control the app; Stop removes it (confirmed on the Lock Screen; the Dynamic Island hasn't been tested on a device that has one)
- [x] Layout fits without scrolling on iPhone SE and the largest Pro Max
- [x] No sounds and no haptics anywhere
- [x] Unit tests pass

## Android port notes

The Android version is a separate native app in Kotlin with Jetpack Compose. It keeps every behavior, measurement, style, palette and Look rule in this spec. Only the platform pieces below change.

| Piece | iOS | Android |
| --- | --- | --- |
| Fonts | San Francisco; New York for serif; SF Rounded; SF Mono | Roboto (`FontFamily.Default`); `FontFamily.Serif`; no system rounded face, so bundle an open-licensed rounded font (for example Nunito) or fall back to Roboto; `FontFamily.Monospace` |
| Monospaced digits | `.monospacedDigit()` | `fontFeatureSettings = "tnum"` |
| Dial drawing | SwiftUI `Canvas`; static face under a `TimelineView` canvas | Compose `Canvas` with the same geometry. Draw the face in a layer that recomposes only when the style or colors change. Animate the live layer with `withFrameNanos` only while the screen is visible. Draw text with `TextMeasurer` |
| Saved state and Looks | UserDefaults, Looks as JSON | DataStore, using the same JSON shape and keys |
| Screen awake | `isIdleTimerDisabled` | `FLAG_KEEP_SCREEN_ON`, cleared after N minutes; any touch (`onTouchEvent` at the window or activity level) restarts it |
| Lock Screen control | Live Activity with buttons | An ongoing notification with a counting chronometer and Pause / Play / Stop actions; use Android's promoted live-update style where available. Ask for the notification permission (Android 13 and later) the first time Start is tapped |
| Color picker | Built-in system picker | No system picker: a small custom HSV picker, or a maintained library |
| Customize / Done icons | SF Symbols `paintpalette`, `checkmark` | Material Symbols `palette`, `check` |
| Name prompt | Standard alert with a text field | `AlertDialog` with an `OutlinedTextField`, in the default Material theme rather than the Look's colors |
| Look tile menu | Long-press context menu | Long-press `DropdownMenu` |
| App icon | 1024 PNG from a script | Adaptive icon (foreground and background layers) generated from the same drawing |
| Sharing with others | TestFlight or App Store (paid account) | Signed APK shared directly, or Google Play |
