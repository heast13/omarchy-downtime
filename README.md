# Downtime 💤

Screensaver, screen off, sleep and wallpaper rotation for [Omarchy](https://omarchy.org/), set from one bar widget.

Omarchy can start a screensaver and lock on idle out of the box. Downtime adds the two steps after that: turn the screen off, then put the machine to sleep.

An independent [MIT](LICENSE)-licensed plugin. Not affiliated with or endorsed by 37signals.

## What it does

| Setting | Default | Notes |
| --- | --- | --- |
| Wallpaper rotation | off | Calls `omarchy-theme-bg-next`. Right-click the widget for the next one. |
| Screensaver | 5 min | Sets Omarchy's own `idle.screensaver`. Off uses Omarchy's screensaver toggle, the same one as in its menu. |
| Screen off | 10 min | Via hypridle. |
| Sleep | off | Via hypridle and `systemctl suspend`. |

Things worth knowing:

- **Times count from when the screensaver starts.** Opening the screensaver resets the idle clock. With screensaver 5 and sleep 30, the machine sleeps after about 35 minutes.
- **Playing media keeps the machine awake.** Inhibitors from browsers and video players are respected.
- **The screensaver is closed before sleep**, so you wake up to your desktop, not to the screensaver.
- **Locking is not changed.** Omarchy still locks the screen before sleep. If you do not want a password after wake, see [Sleep without a password](#sleep-without-a-password).

## Install

```sh
omarchy plugin add https://github.com/heast13/omarchy-downtime.git --enable
```

Downtime needs `hypridle`. If it is missing:

```sh
omarchy pkg add hypridle
```

> [!IMPORTANT]
> Plugins run as unsandboxed code inside `omarchy-shell`. Only add repos you trust, and read the source before you enable one.

## Update

```sh
omarchy plugin update heast13.downtime
omarchy restart shell
```

Restart the shell after an update. A running shell can keep the old version of the plugin's background service loaded.

## How it works

- `Service.qml` reads the widget's settings straight from `~/.config/omarchy/shell.json` and runs `scripts/apply` whenever a timing changes, and once at login.
- `scripts/apply` takes exactly four values and refuses anything else, so a mismatched or half-updated caller changes nothing.
- `scripts/apply` writes `~/.local/state/downtime/hypridle.conf` and runs hypridle with it as the user unit `downtime-hypridle.service`. Your own `~/.config/hypr/hypridle.conf` is never touched.
- Disabling or removing the plugin stops that unit.

If you already start hypridle yourself (for example in `~/.config/hypr/autostart.lua`), both run side by side and Downtime shows a notification. Remove one of them.

Check what is running:

```sh
systemctl --user status downtime-hypridle.service
cat ~/.local/state/downtime/hypridle.conf
```

## Language

The UI follows the system locale and falls back to English. To pick a language yourself:

```sh
omarchy bar set heast13.downtime language de
```

`en`, `de` or `auto` (the default).

## Sleep without a password

Omarchy locks the screen right before sleep with the user unit `omarchy-sleep-lock.service`. On a desktop nobody else uses, you can turn that off:

```sh
systemctl --user mask --now omarchy-sleep-lock.service
```

Undo:

```sh
systemctl --user unmask omarchy-sleep-lock.service
systemctl --user enable --now omarchy-sleep-lock.service
```

Only do this on a machine you trust everyone around.

## Uninstall

```sh
omarchy plugin remove heast13.downtime
rm -rf ~/.local/state/downtime
```

The screensaver delay stays at the last value. Change it back in `~/.config/omarchy/shell.json` under `idle.screensaver` if you like.

## License

[MIT](LICENSE)
