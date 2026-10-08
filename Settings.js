.pragma library

// One place that turns the stored widget settings into on/off plus minutes,
// shared by the bar widget and the background service so both always agree.
//
// Each timing has an on/off switch and a minutes value. The minutes are kept
// while a switch is off. Older settings without a switch used 0 minutes for
// "off", so a missing switch falls back to "minutes > 0".

var MAX_MINUTES = 1440

var timings = {
  wallpaper: { flag: "wallpaperEnabled", minutes: "wallpaperMinutes", on: false, fallback: 10 },
  screenOff: { flag: "screenOffEnabled", minutes: "screenOffMinutes", on: true, fallback: 10 },
  suspend: { flag: "suspendEnabled", minutes: "suspendMinutes", on: false, fallback: 30 },
  // One-shot: only the minutes are stored. Whether it runs is live state.
  shutdown: { flag: "", minutes: "shutdownMinutes", on: false, fallback: 60 }
}

function storedMinutes(settings, key) {
  var v = Number(settings ? settings[key] : undefined)
  return isFinite(v) && v >= 0 ? Math.min(MAX_MINUTES, Math.floor(v)) : -1
}

function enabled(settings, name) {
  var t = timings[name]
  var flag = settings ? settings[t.flag] : undefined
  if (flag !== undefined && flag !== null) return flag !== false
  var stored = storedMinutes(settings, t.minutes)
  return stored < 0 ? t.on : stored > 0
}

// Dimming while the screensaver runs: a switch plus a brightness in percent.
var DIM_FALLBACK = 40

function dimEnabled(settings) {
  return !!settings && settings.screensaverDimEnabled === true
}

function dimPercent(settings) {
  var v = Math.floor(Number(settings ? settings.screensaverDimPercent : undefined))
  return isFinite(v) && v >= 1 && v <= 99 ? v : DIM_FALLBACK
}

// Minutes shown in the field and used while the switch is on (never 0).
function minutes(settings, name) {
  var stored = storedMinutes(settings, timings[name].minutes)
  return stored > 0 ? stored : timings[name].fallback
}

// Minutes handed to the apply script, where 0 means off.
function effectiveMinutes(settings, name) {
  return enabled(settings, name) ? minutes(settings, name) : 0
}
