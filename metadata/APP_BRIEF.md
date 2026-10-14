<!-- gf-brief source=6a65243c7c2e4bf464513c3ca25e160d1ca48829c27399aca554e263445eba28 written=2026-10-14T14:43:33+03:00 -->
# Spilltile

## What it is
Spilltile is a tray of daily caps for people who track several limits in one day. Each cap is a named counter on its own page. You tick the counter sitting in the center; while that count is below its brim the tick stays there, and at the brim the next tick spills once into a catch you chose, or drips and the count does not move if the catch is closed.

## Launch and onboarding
On a first install on a device, a cold launch shows the system launch screen (dark, no wordmark), then **“Loading tray”**. A full-screen cover then walks three pages. **“Skip”** is on every page and closes the cover. **“Continue”** advances. The last page’s primary button is **“Start ticking”**. Neither **“Skip”** nor **“Start ticking”** adds a counter; both open the tray as it is (empty on a device). VoiceOver on **“Skip”** says it “Writes the tray defaults and opens the counters.”

1. Illustration (decorative). Title **“Daily caps”**. Line **“Spilltile keeps a tile for each cap. Tick the one sitting in the center.”** Buttons **“Continue”** and **“Skip”**.
2. Illustration (decorative). Title **“Tick until it spills”**. Line **“Below the brim, the tick stays on this tile. At the brim it spills into the catch, or drips if the catch is closed.”** Buttons **“Continue”** and **“Skip”**.
3. Illustration (decorative). Title **“Peel the last mark”**. Line **“Hold the tile to drop the last tick or spill for today. Swipe only changes the page.”** Buttons **“Start ticking”** and **“Skip”**.

After the cover, a device install shows the empty tray. Later launches skip the cover and reopen the tray with the counters and today’s counts still there.

## Screens

### Daily caps
This is the home screen. There is no tab bar. The tray never leaves; **“Stats”**, **“Editor”**, and **“Settings”** open as sheets.

**Empty tray.** Decorative empty art. Title **“Tray empty”**. Line **“Add a counter to start a daily cap.”** Button **“Add a counter”** opens **Editor**. If the tray could not be read, the same screen also shows **“Tray unreadable”**, one of the recovery lines below, and **“Retry”**.

**Populated tray.**
- Status word at the top left: **“Flowing”** while ticks and spills are moving counts, or **“Dripping”** after a tick at a closed catch.
- Title **“Daily caps”**.
- Line **“Tick the center.”**
- Three icon buttons, spoken as **“Stats”**, **“Editor”**, and **“Settings”**. They open those sheets.
- A decorative header image.
- One counter per page. Swipe sideways only changes the page. A row of chips along the bottom, each labeled with that counter’s name, jumps to that page. VoiceOver on a chip is **“Show {name}”**.
- The page title is the counter’s name.
- Under the name, one of these status lines (numbers use the device’s whole-number format):
  - **“Below brim {cap}. Count {count}. Room {room}. Tick this tile.”**
  - **“At brim {cap}. Count {count}. Next tick spills.”**
  - **“At brim {cap}. Count {count}. Catch closed, drip.”**
- Under that: **“Ghosts {count}. Off-page taps stay off the count.”**
- Large control labeled **“Tick”**, with today’s count as a big number, and **“Hold to peel”**. A tap ticks this page if it is the centered page. A hold drops the last tick or spill for today. VoiceOver: **“Tick {name}”**, hint **“Adds one below brim. At brim it spills or drips. Hold to peel the last mark.”**
- Beside it, a readout (not a button) titled **“Catch”**. If a catch is open, it shows that counter’s name and that counter’s today count. VoiceOver: **“Catch {name}, {count}”**. If there is no open catch, it shows **“Closed”** and **0**. VoiceOver: **“Catch closed”**.
- If at least one other counter exists, a row under the tile shows one other counter’s name plus **“Off page. Ghosts {count}.”** Tapping it does not change any count. VoiceOver: **“Tick {name} off the centered page”**, hint **“Writes a ghost mark and does not change a count.”** That row is the first other counter, not a list of every page.
- A recovery line can also sit above the pages, with **“Retry”**. The possible lines are **“Tray record was unreadable. Restored the last good copy.”**, **“Tray record was unreadable. Started from an empty tray.”**, and **“Tray save failed. The on-screen tray is unchanged.”**

### Stats
Sheet title **“Stats”**. Close control spoken as **“Close stats”**.

- If the tray could not be read: **“Stats unavailable”**, the recovery line, button **“Retry”**.
- If there are no counters: **“No tallies yet”**, **“Add a counter on the editor, then tick the centered page.”**, button **“Close”** (dismisses the sheet).
- If there are counters, two sections:
  - **“Today”** — each counter’s name and **“Count {n}. Brim {n}.”**
  - **“Spills”** — **“No spills today.”** or one line per spill, **“{source} spilled to {catch}.”** If a name is missing the line uses **“Tile”**.

Stats is today only. Earlier days are not listed.

### Editor
Sheet title **“Editor”**. Close control spoken as **“Close editor”**. Keyboard bar button **“Done”** dismisses the keyboard. Tapping outside a field also dismisses it. **“Save counter”** does not close the sheet.

- If the tray could not be read and there are no counters: **“Editor unavailable”**, the recovery line, **“Retry”**.
- If there are no counters yet: **“Tray empty”**, **“Add a counter, then set its cap and an optional catch.”**, then the fields below.
- If there is at least one counter: section **“Counters”**, picker **“Edit”** with **“New counter”** plus each counter’s name.
- Section **“Counter”**:
  - Field **“Name”** (words capitalized).
  - Field **“Cap”** (number pad; digits only).
  - With only one counter (or while the first is the only other one and you are not editing a second): **“Add another counter before a catch can open.”**
  - With another counter available: toggle **“Catch open”** and picker **“Catch”** with **“None”** plus the other counters’ names. A counter cannot catch to itself.
- Button **“Save counter”**. While the save is in flight the label is **“Saving”** and the button is disabled.
- Inline errors: **“Name the counter, then save.”** and **“Cap needs a whole number of at least 1.”**

**“Save counter”** on **“New counter”** adds a counter, then clears **“Name”** and **“Cap”**. On an existing name it renames, sets the cap, and sets or clears the catch. Turning **“Catch open”** off, or leaving **“Catch”** on **“None”**, closes that catch.

### Settings
Sheet title **“Settings”**. Close control spoken as **“Close settings”**.

- If the tray could not be read: **“Settings blocked”**, the recovery line, **“Retry”**, then **“Contact support”**, **“Show onboarding again”**, and **“Erase tray”**.
- If there are no counters: **“No counters to reset”**, **“The tray has no counters. Contact and onboarding stay available.”**, then **“Contact support”**, **“Show onboarding again”**, and **“Erase tray”**.
- If there are counters:
  - Section **“Day tally”**: picker **“Counter”** (each name), button **“Reset day tally”** (disabled until a counter is selected).
  - Confirm titled **“Reset this day tally”**, message **“The selected counter returns to zero for today. Earlier days stay in the log.”**, buttons **“Reset day tally”** and **“Cancel”**.
  - Section **“Contact”**: **“Opens the support page.”** and **“Contact support”** (opens the support page).
  - **“Show onboarding again”** dismisses Settings and shows the three-page cover again. Counters already on the tray stay.
  - **“Erase tray”** opens confirm titled **“Erase the tray”**, message **“Deletes every counter, mark, and tally on this device. This cannot be undone.”**, buttons **“Erase tray”** and **“Cancel”**. Confirming returns home to **“Tray empty”**.

There is no control to delete one counter. Only **“Erase tray”** removes them.

## Features
- Daily caps on a paged tray; swipe or tap a name chip to change page
- Tick the centered tile
- Per-counter cap (brim)
- Optional catch, opened or closed
- Spill: at brim, the next tick adds one to the catch and leaves this count at the brim
- Drip: at brim with the catch closed, the tick does not change any count
- Ghost: an off-page tap does not change any count; **“Ghosts”** still rises
- Peel: hold the tile to drop the last tick or spill for today
- Stats for **“Today”** counts and **“Spills”**
- Editor to add or rename a counter, set **“Cap”**, and set **“Catch”**
- **“Reset day tally”** for one counter for today
- **“Erase tray”**
- **“Show onboarding again”**
- **“Contact support”**
- New calendar day starts today’s counts at zero
- Everything stays on this device

## Behaviours that can look like bugs
- **“Save counter”** stays dim until **“Name”** has text. Type a name.
- **“Cap”** must be a whole number of at least 1. Empty, 0, or non-numeric shows **“Cap needs a whole number of at least 1.”**
- **“Save counter”** does not close **Editor**. After a new counter, **“Name”** and **“Cap”** clear on purpose so another can be added. Use the close control to leave.
- **“Add another counter before a catch can open.”** until a second counter exists. Save one, then add or edit another.
- A tap on **“Tick”** at brim with **“Catch closed, drip.”** does not raise the big number. The status word becomes **“Dripping”**. Open a catch in **Editor**, raise **“Cap”**, hold to peel the last tick, or use **“Reset day tally”**.
- A tap on **“Tick”** at brim with an open catch does not raise the big number. The **“Catch”** number goes up, and **Stats** can show **“{source} spilled to {catch}.”** That catch can go past its own cap.
- The off-page row and any tick that is not on the centered page leave counts unchanged and raise **“Ghosts”**. Swipe or tap a chip so that counter is in the center, then **“Tick”**.
- **“Hold to peel”** is a hold, not a tap. A tap ticks. A hold with no tick or spill today does nothing. Hold does not undo a drip or a ghost.
- **“Reset day tally”** is dim until a counter is chosen. Confirming when today’s count is already 0 changes nothing on screen.
- **“No tallies yet”**, **“Tray empty”**, **“No counters to reset”**, and **“No spills today.”** are empty states. Add a counter and tick the center to fill them.
- **“Show onboarding again”** brings the three pages back on purpose. **“Skip”** or **“Start ticking”** returns to the tray.
- **“Skip”** / **“Start ticking”** on a device still leave **“Tray empty”** until **“Add a counter”**.
- The chip row and the **“Counters”** / **“Counter”** pickers grow as counters are saved. **“Erase tray”** clears them all.
- When the calendar day changes, today’s counts, **“Ghosts”**, and **“Spills”** reset to empty for the new day. That is the daily cap.
- **“Retry”** appears only after a recovery line. Tap it to reload the tray.
- There is no per-counter delete. Removing one counter is not offered.

## Starter content and resume
On a device, none. After onboarding the tray is empty until **“Add a counter”**.

On Simulator, a first run can skip the cover and already show three counters: **“Calls”** (cap 4, today’s count 3, catch **“Inbox”**), **“Inbox”** (cap 6), and **“Errands”** (cap 3). The first **“Tick”** on **“Calls”** is then a spill into **“Inbox”**.

Saved counters, caps, catch links, and today’s marks come back after quitting. An **Editor** form that was not saved does not. Hold-to-peel resumes only the last tick or spill from today.

## Permissions
None.

## Absent
Login or accounts, in-app purchase, ads, analytics, user-generated content (no public posts or shared feed; names typed here stay on this device), account deletion flow, and the App Tracking Transparency prompt are all absent.

## Data and support
Data stays on this device. The erase confirm says **“Deletes every counter, mark, and tally on this device. This cannot be undone.”** The support control is **“Contact support”** in **Settings**, under **“Contact”**, with the line **“Opens the support page.”**

## Scanning and health
None.

## Platform
English only. No region lock. Counts use the device’s whole-number format. The day follows the device calendar and time zone. Portrait only, on iPhone and iPad. Dark appearance. The iPad view is full screen. Minimum iOS 17.0.

## Category
Lifestyle
