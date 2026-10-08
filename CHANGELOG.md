# Changelog

## 1.4.0 - 2026-10-08

- Dim during screensaver: lowers every display to a set brightness (default
  40 %) while the screensaver runs and restores it afterwards. Works wherever
  Omarchy's brightness keys work (backlight, DDC/CI). Greyed out with a hint
  when no display can be dimmed. Every change is read back, displays waking
  up from screen off are waited for, and a safety net restores anything left
  dimmed.
- Disabling the plugin restores dimmed displays.
- A shell restart no longer risks stopping screen off, sleep or a running
  shutdown timer when the new shell is slow to answer.
- Shutdown timer: a quick cancel is never lost, parallel starts no longer
  clash, a timer stopped from outside unpauses sleep, and the time left is
  right from the first moment.
- Script arguments with too many digits are refused instead of wrapping
  around.

## 1.3.0 - 2026-10-08

- One-shot shutdown timer, entered in hours and minutes. It confirms the time,
  warns one minute before, pauses and greys out sleep while it runs, survives
  shell restarts and is cancelled when the plugin is disabled or removed.
- EN/DE language button in the panel.
- The screensaver switch no longer rounds Omarchy's delay: switch and minutes
  are written separately.
- The panel warns when hypridle is missing and applies the timings once it
  appears.
- German header line reads "Energiesparmodus", like its section.

## 1.2.0 - 2026-10-08

- Every section has the same small on/off switch next to its title. The
  minutes are kept while a switch is off. Settings from earlier versions,
  where 0 minutes meant off, carry over.
- New moon icon.

## 1.1.0 - 2026-10-08

- Enabling the plugin no longer changes the screensaver. Omarchy's screensaver
  delay and toggle stay as they are until you change them in the widget, and
  the widget shows the current values until then.

## 1.0.0 - 2026-10-08

First release.

- Bar widget with screensaver, screen-off, sleep and wallpaper rotation timings.
- Runs its own hypridle instance with its own config, so an existing
  `~/.config/hypr/hypridle.conf` is never touched.
- Closes an open screensaver before sleep and turns the screen back on after wake.
- English and German UI.
- Turning the screensaver off uses Omarchy's own screensaver toggle.
- The apply script refuses unexpected arguments, so a mismatched caller
  changes nothing.
