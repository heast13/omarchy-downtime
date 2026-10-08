# Changelog

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
