import QtQuick
import Quickshell
import Quickshell.Io

// Headless half of Downtime. It reads its settings straight from shell.json
// instead of waiting for the bar widget to push them, so it works the same
// after login, after a shell restart and after a plugin hot-reload.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string pluginId: manifest && manifest.id ? String(manifest.id) : "heast13.downtime"
  readonly property string pluginDir: manifest && manifest.__sourceDir
    ? String(manifest.__sourceDir)
    : Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, "")
  readonly property string applyScript: pluginDir + "/scripts/apply"

  property var settings: ({})
  property bool configLoaded: false
  property string appliedKey: ""

  function num(name, fallback) {
    var v = Number(settings ? settings[name] : undefined)
    return isFinite(v) && v >= 0 ? Math.floor(v) : fallback
  }

  readonly property int wallpaperMinutes: num("wallpaperMinutes", 0)
  readonly property bool screensaverEnabled: !settings || settings.screensaverEnabled !== false
  readonly property int screensaverMinutes: Math.min(1440, Math.max(1, num("screensaverMinutes", 5)))
  readonly property int screenOffMinutes: Math.min(1440, num("screenOffMinutes", 10))
  readonly property int suspendMinutes: Math.min(1440, num("suspendMinutes", 0))

  readonly property var applyArgs: [
    screensaverEnabled ? "on" : "off",
    String(screensaverMinutes),
    String(screenOffMinutes),
    String(suspendMinutes)
  ]

  // The bar widget lives in bar.layout, or as a top-level entry in plugins[].
  function findEntry(config) {
    var lists = []
    var layout = config && config.bar && config.bar.layout
    if (layout) for (var section in layout) if (Array.isArray(layout[section])) lists.push(layout[section])
    if (config && Array.isArray(config.plugins)) lists.push(config.plugins)
    for (var i = 0; i < lists.length; i++)
      for (var j = 0; j < lists[i].length; j++)
        if (lists[i][j] && lists[i][j].id === pluginId) return lists[i][j]
    return ({})
  }

  // Only re-apply when a timing actually changed. The apply script writes
  // idle.screensaver back into shell.json, which must not loop.
  // Nothing is applied before shell.json has been read, so the defaults never
  // overwrite the user's timings for a moment at startup.
  function scheduleApply() {
    if (configLoaded && applyArgs.join(" ") !== appliedKey) applyDebounce.restart()
  }

  onApplyArgsChanged: scheduleApply()

  FileView {
    id: configFile
    path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        root.settings = root.findEntry(JSON.parse(text()))
      } catch (e) {
        // Caught mid-write; the next change notification reloads it.
        return
      }
      root.configLoaded = true
      root.scheduleApply()
    }
  }

  Timer {
    id: wallpaperTimer
    interval: Math.max(1, root.wallpaperMinutes) * 60000
    running: root.wallpaperMinutes > 0
    repeat: true
    onTriggered: Quickshell.execDetached(["omarchy-theme-bg-next"])
  }

  Timer {
    id: applyDebounce
    interval: 700
    onTriggered: {
      root.appliedKey = root.applyArgs.join(" ")
      // Detached through systemd-run: the script rewrites shell.json, and the
      // shell may reload this plugin while it runs.
      Quickshell.execDetached(["systemd-run", "--user", "--quiet", "--collect", root.applyScript]
        .concat(root.applyArgs))
    }
  }

  // A hot-reload destroys and recreates this object too, so wait and only stop
  // hypridle when the plugin really is disabled or removed. Inline rather than
  // in scripts/: on removal the plugin folder is already gone.
  Component.onDestruction: Quickshell.execDetached([
    "systemd-run", "--user", "--quiet", "--collect", "bash", "-c",
    "sleep 3; omarchy plugin list --json | jq -e --arg id \"$1\" 'any(.[]; .id == $id and .enabled)' >/dev/null"
      + " || systemctl --user stop downtime-hypridle.service",
    "downtime-stop", root.pluginId
  ])
}
