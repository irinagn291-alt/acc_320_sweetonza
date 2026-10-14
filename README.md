# Spilltile

Spilltile is a desk tray for people who track several daily caps. The centered tile takes the tick. When that tile is still under its brim, the count stays there. When it is at the brim, the next tick spills once into the chosen catch tile. If that catch is closed, the tick drips and the count does not move. A tick that is not on the centered page is a ghost and changes nothing. Hold the tile to peel the last tick or spill for today.

## Architecture

The tray is a spill-routing fold, `TrayFold`: Bare, Flowing, or Dripping. An empty tray is Bare. Each civil day is one daykey, and the tray document is a fold over tiles for that day. `TrayEngine` is the only place a tick, spill, drip, ghost, peel, or day snap is decided. Screens call `TrayStore`, and the store calls the engine, then writes one Codable root through `TrayVault`.

That split fits this product because the home verb is a route, not a sum. The same tap means four different marks depending on brim, catch, and which page is centered. Keeping that decision in the fold means the pager, the stats sheet, and the settings reset cannot each invent a second rule.

## Spill-then-tick

Tick on the centered tile below brim writes `TickMark` and increments that tile's `DayTally` by one. Tick at or above brim with an open catch writes `SpillMark` and increments only the catch tile, one hop. Tick at brim with no open catch writes `DripMark` and refuses the increment, folding to Dripping. Tick on a non-centered page writes `GhostMark` and changes nothing. Peel drops the latest tick or spill for today and reverses that one tally change. When the calendar day elapses, each live tally snaps and the log stores the old value as a negative delta. Every tally is held at max(0, value + delta).

The home screen is the paging bento. Stats, the editor, and Settings are sheets. There is no tab bar.

## Art

Style: vaporwave documentary. Base prompt:

Vaporwave documentary. Photographed still life of a desk tray, solid chrome and marble forms, a grid horizon, and light scan grain. Observational framing, solid opaque subjects centered in the frame. Cutouts keep transparent corners and a solid center. The icon, splash, and backdrop fill the canvas edge to edge. No letters, no hollow glass, no wire outline.

Asset prompts:

- spt_AppIcon: A solid square tile emblem with a heavy runoff lip, photographed chrome and marble, vaporwave grid grain, subject filling the canvas edge to edge, no letters, no rounded mask, opaque.
- spt_Splash: A tall vaporwave documentary field, grid horizon and scan grain reaching all four edges, a quiet center band with one solid tile standing in the middle third.
- spt_Onboarding1: A solid opaque tray holding one heavy tile, photographed chrome and marble, vaporwave documentary, subject centered.
- spt_Onboarding2: A solid token pressing the center of a heavy tile, mid gesture, photographed, vaporwave documentary, opaque forms, subject centered.
- spt_Onboarding3: A solid mass leaving one tile and resting in a second lower tile, photographed chrome and marble, vaporwave documentary, opaque, subject centered.
- spt_EmptyHome: A solid closed tray with a lid, ceramic and metal, fully opaque, photographed, vaporwave documentary, not glass, not a hollow frame, subject centered.
- spt_EmptyList: A solid closed folio of tally cards, opaque cover, photographed, vaporwave documentary, subject centered.
- spt_CardBackdrop: An edge-to-edge vaporwave grid horizon with scan grain, quiet pattern, no competing subject, fills the canvas.
- spt_ControlFace: The face of a solid tick tile, heavy lip, photographed chrome inlay, opaque, centered.
- spt_TwistHero: A solid tile at the lip with a heavy mass moving into a second tile, photographed, vaporwave documentary, opaque, centered.
- spt_SuccessMark: A solid filled seal with a thick center, photographed metal, opaque, not a hollow ring, centered.
- spt_HeaderDecor: A wide horizontal row of solid tiles in the center, photographed, vaporwave documentary, opaque slabs, not a wire grid.

## How this differs

Soroban ticks one lit bead on a fixed rail. Spilltile routes brim overflow between tiles the user links, on a pager, and refuses a tick that is off the centered page. It is not a single shared quota and not a tap-anywhere counter.

## Build

```bash
cd apps/Spilltile
xcodegen generate
xcodebuild build-for-testing -scheme Spilltile -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```

Zero external packages. UIKit hosts the page controller. Core Graphics draws the centered tile plate only.
