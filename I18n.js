.pragma library

// UI strings. English is the default; set the widget's "language" setting to
// "de" (or "auto" to follow the system locale) for German.
var strings = {
  en: {
    title: "Downtime",
    wallpaper: "WALLPAPER",
    wallpaperEvery: "Rotate every … min",
    next: "Next",
    screensaver: "SCREENSAVER",
    screensaverAfter: "Screensaver after … min",
    dim: "DIM DURING SCREENSAVER",
    dimTo: "Dim to … %",
    screenOff: "SCREEN OFF",
    screenOffAfter: "Screen off after … min",
    sleep: "SLEEP",
    sleepAfter: "Sleep after … min",
    sleepNote: "Counts from when the screensaver starts. Playing media keeps the machine awake.",
    off: "OFF",
    on: "On",
    offLower: "Off",
    min: "MIN",
    sleepIn: "Sleep",
    tooltipRotate: "Wallpaper every %1 min · Right-click: next",
    tooltipManual: "Downtime · Right-click: next wallpaper",
    languageTooltip: "Switch to German",
    shutdown: "SHUTDOWN TIMER",
    hours: "Shut down in … hours",
    minutes: "and … min",
    shutdownAt: "Shuts down at %1",
    timeLeft: "%1 left",
    shutdownHero: "Shutdown %1",
    sleepPaused: "Paused while the shutdown timer runs.",
    tooltipShutdown: "Shutting down at %1",
    hypridleMissing: "hypridle is not installed, so screen off and sleep do nothing. Install it with:\nomarchy pkg add hypridle"
  },
  de: {
    title: "Downtime",
    wallpaper: "WALLPAPER",
    wallpaperEvery: "Wechsel alle … Min",
    next: "Weiter",
    screensaver: "BILDSCHIRMSCHONER",
    screensaverAfter: "Bildschirmschoner nach … Min",
    dim: "DIMMEN BEIM SCHONER",
    dimTo: "Dimmen auf … %",
    screenOff: "BILDSCHIRM AUS",
    screenOffAfter: "Bildschirm aus nach … Min",
    sleep: "ENERGIESPARMODUS",
    sleepAfter: "Energiesparmodus nach … Min",
    sleepNote: "Zählt ab dem Start des Bildschirmschoners. Laufende Medien halten den Rechner wach.",
    off: "AUS",
    on: "An",
    offLower: "Aus",
    min: "MIN",
    sleepIn: "Energiesparmodus",
    tooltipRotate: "Wallpaper alle %1 Min · Rechtsklick: weiter",
    tooltipManual: "Downtime · Rechtsklick: nächstes Wallpaper",
    languageTooltip: "Auf Englisch umstellen",
    shutdown: "AUSSCHALT-TIMER",
    hours: "Herunterfahren in … Std",
    minutes: "und … Min",
    shutdownAt: "Fährt um %1 herunter",
    timeLeft: "noch %1",
    shutdownHero: "Ausschalten %1",
    sleepPaused: "Pausiert, solange der Ausschalt-Timer läuft.",
    tooltipShutdown: "Fährt um %1 herunter",
    hypridleMissing: "hypridle ist nicht installiert, darum tun Bildschirm aus und Energiesparmodus nichts. Installieren mit:\nomarchy pkg add hypridle"
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
