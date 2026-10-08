.pragma library

// UI strings. English is the default; set the widget's "language" setting to
// "de" (or "auto" to follow the system locale) for German.
var strings = {
  en: {
    title: "Downtime",
    wallpaper: "WALLPAPER",
    wallpaperEvery: "Rotate every … min (0 = off)",
    next: "Next",
    screensaver: "SCREENSAVER",
    screensaverToggle: "Screensaver",
    screensaverOn: "Starts when idle",
    screensaverOff: "Off",
    screensaverAfter: "Screensaver after … min",
    screenOff: "SCREEN OFF",
    screenOffAfter: "Screen off after … min (0 = never)",
    sleep: "SLEEP",
    sleepAfter: "Sleep after … min (0 = never)",
    sleepNote: "Counts from when the screensaver starts. Playing media keeps the machine awake.",
    off: "OFF",
    min: "MIN",
    sleepIn: "Sleep",
    tooltipRotate: "Wallpaper every %1 min · Right-click: next",
    tooltipManual: "Downtime · Right-click: next wallpaper"
  },
  de: {
    title: "Downtime",
    wallpaper: "WALLPAPER",
    wallpaperEvery: "Wechsel alle … Min (0 = aus)",
    next: "Weiter",
    screensaver: "BILDSCHIRMSCHONER",
    screensaverToggle: "Bildschirmschoner",
    screensaverOn: "Startet bei Inaktivität",
    screensaverOff: "Aus",
    screensaverAfter: "Bildschirmschoner nach … Min",
    screenOff: "BILDSCHIRM AUS",
    screenOffAfter: "Bildschirm aus nach … Min (0 = nie)",
    sleep: "ENERGIESPARMODUS",
    sleepAfter: "Energiesparmodus nach … Min (0 = nie)",
    sleepNote: "Zählt ab dem Start des Bildschirmschoners. Laufende Medien halten den Rechner wach.",
    off: "AUS",
    min: "MIN",
    sleepIn: "Schlafen",
    tooltipRotate: "Wallpaper alle %1 Min · Rechtsklick: weiter",
    tooltipManual: "Downtime · Rechtsklick: nächstes Wallpaper"
  }
}

function language(setting, localeName) {
  var wanted = String(setting || "auto")
  if (strings[wanted]) return wanted
  var prefix = String(localeName || "").split(/[_-]/)[0]
  return strings[prefix] ? prefix : "en"
}

function tr(lang, key, arg) {
  var table = strings[lang] || strings.en
  var text = table[key] !== undefined ? table[key] : strings.en[key]
  return arg !== undefined ? String(text).replace("%1", arg) : text
}
