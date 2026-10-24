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
    fade: "DIM WHEN IDLE",
    fadeStart: "Start after … min idle",
    fadeStep: "One step every … sec",
    fadeTo: "Fade to … %",
    fadeNote: "Lowers the brightness by 1 % per step, down to the target. Any activity brings it back.",
    fadeAfterSaver: "Starts no earlier than the screensaver, so it never shows. Pick a shorter time.",
    fadeEta: "From %1 % it reaches the target after %2 idle.",
    fadeCutSaver: "The screensaver starts first, after %1 min. By then: %2 %.",
    fadeCutOff: "The screen turns off first, after %1 min. By then: %2 %.",
    fadeNothing: "Already at %1 %, so there is nothing to dim.",
    minShort: "min",
    dimUnsupported: "This display's brightness can't be controlled. On a monitor, turn on DDC/CI in its own menu.",
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
    hypridleMissing: "hypridle is not installed, so idle dimming, screen off and sleep do nothing. Install it with:\nomarchy pkg add hypridle",
    stayAwake: "Stay Awake is on: no idle dimming, screen off or sleep until you turn it off."
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
    fade: "DIMMEN BEI UNTÄTIGKEIT",
    fadeStart: "Beginn nach … Min Untätigkeit",
    fadeStep: "Eine Stufe alle … Sek",
    fadeTo: "Abdunkeln auf … %",
    fadeNote: "Senkt die Helligkeit pro Stufe um 1 % bis zum Ziel. Jede Eingabe stellt sie zurück.",
    fadeAfterSaver: "Beginnt nicht vor dem Bildschirmschoner und wirkt darum nie. Kürzere Zeit wählen.",
    fadeEta: "Von %1 % aus ist das Ziel nach %2 Untätigkeit erreicht.",
    fadeCutSaver: "Der Bildschirmschoner kommt vorher, nach %1 Min. Bis dahin: %2 %.",
    fadeCutOff: "Der Bildschirm geht vorher aus, nach %1 Min. Bis dahin: %2 %.",
    fadeNothing: "Schon bei %1 %, darum gibt es nichts zu dimmen.",
    minShort: "Min",
    dimUnsupported: "Die Helligkeit dieses Bildschirms lässt sich nicht steuern. Bei Monitoren: DDC/CI im Monitormenü einschalten.",
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
    hypridleMissing: "hypridle ist nicht installiert, darum tun Dimmen bei Untätigkeit, Bildschirm aus und Energiesparmodus nichts. Installieren mit:\nomarchy pkg add hypridle",
    stayAwake: "Stay Awake ist an: kein Dimmen bei Untätigkeit, kein Bildschirm aus und kein Energiesparmodus, bis du es ausschaltest."
  }
}

function language(setting, localeName) {
  var wanted = String(setting || "auto")
  if (strings[wanted]) return wanted
  var prefix = String(localeName || "").split(/[_-]/)[0]
  return strings[prefix] ? prefix : "en"
}

// arg fills %1, or an array fills %1, %2, ...
function tr(lang, key, arg) {
  var table = strings[lang] || strings.en
  var text = table[key] !== undefined ? table[key] : strings.en[key]
  if (arg === undefined) return text
  var args = Array.isArray(arg) ? arg : [arg]
  return String(text).replace(/%(\d)/g, function(m, n) { return args[n - 1] !== undefined ? args[n - 1] : m })
}
