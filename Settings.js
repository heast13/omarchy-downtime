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

// On battery, screen off and sleep can have times of their own. The source is
// "ac" or "battery"; without one, or for any other timing, the AC keys count.
// Battery keys that were never set follow the AC ones.
var batteryTimings = {
  screenOff: { flag: "screenOffBatteryEnabled", minutes: "screenOffBatteryMinutes" },
  suspend: { flag: "suspendBatteryEnabled", minutes: "suspendBatteryMinutes" }
}

function battery(name, source) {
  return source === "battery" && batteryTimings[name] ? batteryTimings[name] : null
}

// The keys a switch or a stepper writes for that source.
function keys(name, source) {
  return battery(name, source) || timings[name]
}

// Whether the battery has a time of its own for this timing.
function batteryOwn(settings, name) {
  var b = batteryTimings[name]
  return !!settings && (settings[b.flag] !== undefined || settings[b.minutes] !== undefined)
}

function storedMinutes(settings, key) {
  var v = Number(settings ? settings[key] : undefined)
  return isFinite(v) && v >= 0 ? Math.min(MAX_MINUTES, Math.floor(v)) : -1
}

function enabled(settings, name, source) {
  var b = battery(name, source)
  var own = b && settings ? settings[b.flag] : undefined
  if (own !== undefined && own !== null) return own !== false
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

// Gradual dimming while idle: starts after a delay, then lowers the brightness
// by one percent per step until the target is reached. Start in minutes,
// step in seconds, target in percent.
var FADE_START = { fallback: 3, min: 1, max: 60 }
var FADE_STEP = { fallback: 5, min: 1, max: 60 }
var FADE_PERCENT_FALLBACK = 50

function fadeEnabled(settings) {
  return !!settings && settings.idleDimEnabled === true
}

function fadeValue(settings, key, range) {
  var v = Math.floor(Number(settings ? settings[key] : undefined))
  return isFinite(v) && v >= range.min && v <= range.max ? v : range.fallback
}

function fadeStart(settings) { return fadeValue(settings, "idleDimStartMinutes", FADE_START) }
function fadeStep(settings) { return fadeValue(settings, "idleDimStepSeconds", FADE_STEP) }

function fadePercent(settings) {
  var v = Math.floor(Number(settings ? settings.idleDimPercent : undefined))
  return isFinite(v) && v >= 1 && v <= 99 ? v : FADE_PERCENT_FALLBACK
}

// Minutes shown in the field and used while the switch is on (never 0).
function minutes(settings, name, source) {
  var b = battery(name, source)
  var own = b ? storedMinutes(settings, b.minutes) : -1
  if (own > 0) return own
  var stored = storedMinutes(settings, timings[name].minutes)
  return stored > 0 ? stored : timings[name].fallback
}

// Minutes the service times, where 0 means off.
function effectiveMinutes(settings, name, source) {
  return enabled(settings, name, source) ? minutes(settings, name, source) : 0
}
