# Changelog

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
