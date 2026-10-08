import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "Settings.js" as Settings
import "I18n.js" as I18n

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
  readonly property string shutdownScript: pluginDir + "/scripts/shutdown"
  readonly property string dimScript: pluginDir + "/scripts/dim"
  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/downtime"

  property var settings: ({})
  property var idleConfig: ({})
  property bool systemSaverOff: false
  property bool configLoaded: false
  property string appliedKey: ""

  function num(name, fallback) {
    var v = Number(settings ? settings[name] : undefined)
    return isFinite(v) && v >= 0 ? Math.floor(v) : fallback
  }

  readonly property int wallpaperMinutes: Settings.effectiveMinutes(settings, "wallpaper")
  readonly property bool screensaverEnabled: !settings || settings.screensaverEnabled !== false
  readonly property int screensaverMinutes: Math.min(Settings.MAX_MINUTES, Math.max(1, num("screensaverMinutes", 5)))
  readonly property int screenOffMinutes: Settings.effectiveMinutes(settings, "screenOff")
  readonly property int suspendMinutes: Settings.effectiveMinutes(settings, "suspend")
  readonly property bool dimEnabled: Settings.dimEnabled(settings)
  readonly property int dimPercent: Settings.dimPercent(settings)
  readonly property string lang: I18n.language(settings ? settings.language : "auto", Qt.locale().name)

  // One-shot shutdown timer. The deadline (epoch seconds) comes from the state
  // file written by scripts/shutdown; the timer itself runs in systemd.
  property real shutdownDeadline: 0
  property real now: Date.now() / 1000
  readonly property bool shutdownActive: shutdownDeadline > now
  readonly property int shutdownMinutesLeft: shutdownActive ? Math.ceil((shutdownDeadline - now) / 60) : 0

  // The screensaver is Omarchy's own setting. Its on/off toggle and its delay
  // are each left alone ("keep") until the user changes that part here, so
  // enabling the plugin or flipping the switch never rounds the delay.
  readonly property bool saverStateSet: !!settings && settings.screensaverEnabled !== undefined
  readonly property bool saverMinutesSet: !!settings && settings.screensaverMinutes !== undefined
  readonly property int systemSaverSeconds: {
    var v = Number(idleConfig ? idleConfig.screensaver : undefined)
    return isFinite(v) && v > 0 ? Math.floor(v) : 150
  }

  readonly property var applyArgs: [
    saverStateSet ? (screensaverEnabled ? "on" : "off") : "keep",
    saverMinutesSet ? String(screensaverMinutes) : "keep",
    String(screenOffMinutes),
    // Sleep would stop the shutdown timer from ever firing, so it pauses.
    String(shutdownActive ? 0 : suspendMinutes)
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
        var config = JSON.parse(text())
        root.settings = root.findEntry(config)
        root.idleConfig = config && config.idle ? config.idle : ({})
      } catch (e) {
        // Caught mid-write; the next change notification reloads it.
        return
      }
      root.configLoaded = true
      root.scheduleApply()
    }
  }

  // Omarchy's screensaver on/off toggle, shown by the widget until the user
  // takes over the screensaver here.
  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/toggles/screensaver-off"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.systemSaverOff = true
    onLoadFailed: root.systemSaverOff = false
  }

  FileView {
    id: shutdownFile
    path: root.stateDir + "/shutdown-at"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var v = parseInt(text(), 10)
      root.shutdownDeadline = isFinite(v) ? v : 0
    }
    onLoadFailed: root.shutdownDeadline = 0
  }

  // Dims the displays while any screensaver window is open (one per monitor)
  // and restores them once the last one closes.
  property var saverWindows: ({})

  function setSaverWindow(address, open) {
    var next = {}
    for (var a in saverWindows) if (a !== address) next[a] = true
    if (open) next[address] = true
    var before = Object.keys(saverWindows).length
    var after = Object.keys(next).length
    saverWindows = next
    if (before === 0 && after > 0 && dimEnabled) runDim(["down", String(dimPercent)])
    else if (before > 0 && after === 0) runDim(["up"])
  }

  function runDim(args) { Quickshell.execDetached([root.dimScript].concat(args)) }

  // Whether any display's brightness can be controlled at all. The widget
  // greys out dimming when not. Assumed until a probe says otherwise, and a
  // probe that cannot tell (busy, displays off) keeps the last answer.
  property bool dimSupported: true

  function probeDim() {
    if (!dimProbe.running) dimProbe.running = true
  }

  Process {
    id: dimProbe
    command: [root.dimScript, "probe"]
    onExited: function(code) {
      if (code === 0) root.dimSupported = true
      else if (code === 1) root.dimSupported = false
    }
  }

  // Displays need a moment after being plugged in before they answer.
  Timer {
    id: dimProbeDelay
    interval: 3000
    onTriggered: root.probeDim()
  }

  // Safety net: saved brightness left behind while no screensaver is known to
  // run (a missed close event, a display that was off) gets restored.
  FileView {
    id: dimSavedFile
    path: root.stateDir + "/dim-saved"
    printErrors: false
    onLoaded: if (Object.keys(root.saverWindows).length === 0) root.runDim(["check"])
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var parts = String(event.data || "").split(",")
      if (event.name === "openwindow" && parts[2] === "org.omarchy.screensaver") root.setSaverWindow(parts[0], true)
      else if (event.name === "closewindow" && root.saverWindows[parts[0]]) root.setSaverWindow(parts[0], false)
      else if (/^monitor(added|removed)/.test(event.name)) dimProbeDelay.restart()
    }
  }

  function startShutdown(minutes) {
    runShutdown(["start", String(Math.max(1, Math.min(Settings.MAX_MINUTES, Math.floor(minutes)))), root.lang])
  }

  function cancelShutdown() { runShutdown(["cancel", root.lang]) }

  // A request made while the script still runs (a quick second click) is
  // run next instead of being dropped; only the latest one counts.
  property var pendingShutdown: null

  function runShutdown(args) {
    if (shutdownProc.running) {
      pendingShutdown = args
      return
    }
    shutdownProc.command = [root.shutdownScript].concat(args)
    shutdownProc.running = true
  }

  // A newly created file is not watched yet, so reload once the script is done.
  Process {
    id: shutdownProc
    onExited: {
      shutdownFile.reload()
      if (!root.pendingShutdown) return
      var args = root.pendingShutdown
      root.pendingShutdown = null
      Qt.callLater(root.runShutdown, args)
    }
  }

  // Keeps the countdown current and notices a timer that ended elsewhere.
  Timer {
    interval: 15000
    running: true
    repeat: true
    onTriggered: {
      root.now = Date.now() / 1000
      shutdownFile.reload()
      // A timer stopped outside the widget leaves its deadline file behind.
      if (root.shutdownActive && !shutdownProc.running && !root.pendingShutdown) root.runShutdown(["check"])
      dimSavedFile.reload()
      if (root.hypridleMissing) root.checkHypridle()
    }
  }

  // Screen off and sleep need hypridle. The widget warns while it is missing,
  // and once it appears the timings are applied again so it starts.
  property bool hypridleMissing: false

  function checkHypridle() {
    if (!hypridleCheck.running) hypridleCheck.running = true
  }

  Process {
    id: hypridleCheck
    command: ["sh", "-c", "command -v hypridle"]
    onExited: function(code) {
      var missing = code !== 0
      if (root.hypridleMissing && !missing) {
        root.appliedKey = ""
        root.scheduleApply()
      }
      root.hypridleMissing = missing
    }
  }

  Component.onCompleted: {
    runShutdown(["check"])
    // A shell restart while dimmed loses track of the screensaver windows.
    runDim(["check"])
    probeDim()
    checkHypridle()
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
  // hypridle and a running shutdown timer when the plugin really is disabled or
  // removed. Inline rather than in scripts/: on removal the folder is gone.
  Component.onDestruction: Quickshell.execDetached([
    "systemd-run", "--user", "--quiet", "--collect", "bash", "-c",
    "sleep 3; omarchy plugin list --json | jq -e --arg id \"$1\" 'any(.[]; .id == $id and .enabled)' >/dev/null"
      + " || { systemctl --user stop downtime-hypridle.service downtime-shutdown.timer downtime-shutdown-warn.timer;"
      + " rm -f \"$2/shutdown-at\"; }",
    "downtime-stop", root.pluginId, root.stateDir
  ])
}
