import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "I18n.js" as I18n
import "Settings.js" as Settings

Panel {
  id: root
  moduleName: "heast13.downtime"
  ipcTarget: "downtime.panel"

  readonly property var service: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor(moduleName) : null
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string lang: I18n.language(setting("language", "auto"), Qt.locale().name)

  readonly property bool wallpaperEnabled: Settings.enabled(settings, "wallpaper")
  readonly property int wallpaperMinutes: Settings.minutes(settings, "wallpaper")
  // Until the user sets the screensaver here, show what Omarchy currently uses.
  readonly property bool screensaverEnabled: setting("screensaverEnabled",
    service ? !service.systemSaverOff : true) !== false
  readonly property int screensaverMinutes: intSetting("screensaverMinutes",
    service ? Math.max(1, Math.round(service.systemSaverSeconds / 60)) : 5, 1)
  readonly property bool dimEnabled: Settings.dimEnabled(settings)
  // Both dimming sections exist only while a display's brightness can be set.
  readonly property bool dimSupported: !!service && service.dimSupported
  // Dimming follows the screensaver and needs a display whose brightness can be set.
  readonly property bool dimAvailable: screensaverEnabled && dimSupported
  readonly property int dimPercent: Settings.dimPercent(settings)
  readonly property bool fadeEnabled: Settings.fadeEnabled(settings)
  readonly property int fadeStart: Settings.fadeStart(settings)
  readonly property int fadeStep: Settings.fadeStep(settings)
  readonly property int fadePercent: Settings.fadePercent(settings)
  readonly property int brightness: service ? service.brightness : -1
  // When the fade reaches its target, counted from the last input. The
  // screensaver ends it early, or without one the screen turning off.
  readonly property string fadeEta: {
    if (brightness < 0) return ""
    if (brightness <= fadePercent) return root.tr("fadeNothing", brightness)
    var start = fadeStart * 60
    var done = start + (brightness - fadePercent) * fadeStep
    var stop = screensaverEnabled ? screensaverMinutes * 60 : (screenOffEnabled ? screenOffMinutes * 60 : 0)
    if (stop > 0 && stop < done) {
      var reached = brightness - Math.max(0, Math.floor((stop - start) / fadeStep))
      return root.tr(screensaverEnabled ? "fadeCutSaver" : "fadeCutOff", [Math.round(stop / 60), reached])
    }
    var sec = done % 60
    var time = Math.floor(done / 60) + (sec ? ":" + (sec < 10 ? "0" : "") + sec : "") + " " + root.tr("minShort")
    return root.tr("fadeEta", [brightness, time])
  }
  // Screen off and sleep have times for AC and for battery. These are the
  // ones in effect right now; the sections show both on a machine with a battery.
  readonly property bool hasBattery: !!service && service.hasBattery
  readonly property string liveSource: service ? service.powerSource : "ac"
  readonly property bool screenOffEnabled: Settings.enabled(settings, "screenOff", liveSource)
  readonly property int screenOffMinutes: Settings.minutes(settings, "screenOff", liveSource)
  readonly property bool suspendEnabled: Settings.enabled(settings, "suspend", liveSource)
  readonly property int suspendMinutes: Settings.minutes(settings, "suspend", liveSource)
  readonly property int shutdownMinutes: Settings.minutes(settings, "shutdown")
  readonly property bool shutdownActive: !!service && service.shutdownActive
  // Weekday only when the deadline is not today, e.g. "Fri 15:32".
  readonly property string shutdownTime: {
    if (!shutdownActive) return ""
    var at = new Date(service.shutdownDeadline * 1000)
    var today = new Date(service.now * 1000).toDateString() === at.toDateString()
    return at.toLocaleString(Qt.locale(root.lang === "de" ? "de_DE" : "en_US"), today ? "HH:mm" : "ddd HH:mm")
  }
  readonly property string shutdownLeft: duration(service ? service.shutdownMinutesLeft : 0)

  // The section whose settings are open. One at a time keeps the panel short.
  property string expanded: ""

  function tr(key, arg) { return I18n.tr(root.lang, key, arg) }

  function intSetting(name, fallback, min) {
    var v = Math.floor(Number(setting(name, fallback)))
    return isFinite(v) ? Math.max(min, v) : fallback
  }

  function duration(m) {
    var min = root.tr("minShort")
    if (m < 60) return m + " " + min
    return Math.floor(m / 60) + " h" + (m % 60 ? " " + (m % 60) + " " + min : "")
  }

  // Short value next to a section title, e.g. "10 min" or "Off".
  function minutesSummary(on, minutes) { return on ? minutes + " " + root.tr("minShort") : root.tr("offLower") }

  // Screen off and sleep on a machine with a battery: "AC 10 min · Battery 5 min".
  function sourceSummary(name) {
    if (!hasBattery) return minutesSummary(Settings.enabled(settings, name, "ac"), Settings.minutes(settings, name, "ac"))
    return ["ac", "battery"].map(function(source) {
      var on = Settings.enabled(settings, name, source)
      return root.tr(source + "Short") + " "
        + (on ? Settings.minutes(settings, name, source) + " " + root.tr("minShort") : root.tr("offLower").toLowerCase())
    }).join(" · ")
  }

  // Only writes shell.json; the service watches that file and applies.
  function persist(values) {
    var entry = { id: moduleName }
    for (var k in settings) if (k !== "id") entry[k] = settings[k]
    for (var key in values) entry[key] = values[key]
    root.settings = entry
    if (bar && bar.shell && typeof bar.shell.updateEntryInline === "function")
      bar.shell.updateEntryInline(moduleName, entry)
  }

  // A switch always stores its minutes too, so the value shown is the value kept.
  function persistTiming(name, on, minutes, source) {
    var keys = Settings.keys(name, source)
    var values = {}
    values[keys.flag] = on
    values[keys.minutes] = minutes
    root.persist(values)
  }

  function persistShutdown(hours, minutes) {
    var total = Math.max(1, Math.min(Settings.MAX_MINUTES, hours * 60 + minutes))
    root.persist({ shutdownMinutes: total })
  }

  function nextWallpaper() { Quickshell.execDetached(["omarchy-theme-bg-next"]) }

  // Displays come and go, so ask again whenever the panel opens.
  onOpenedChanged: if (opened && service) service.probeDim()

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // One row per feature: title, a short summary and an optional on/off
  // switch. A click on the row opens its settings below it.
  component Section: Column {
    id: section

    property string name: ""
    property string title: ""
    property string summary: ""
    property bool switchable: true
    property bool checked: false
    readonly property bool open: root.expanded === name
    default property alias content: body.data
    signal toggled()

    width: parent ? parent.width : 0
    spacing: Style.space(10)

    Item {
      width: parent.width
      implicitHeight: Math.max(title.implicitHeight, toggle.implicitHeight)

      MouseArea {
        anchors.left: parent.left
        anchors.right: section.switchable ? toggle.left : parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expanded = section.open ? "" : section.name
      }

      Text {
        id: chevron
        anchors.left: parent.left
        anchors.verticalCenter: title.verticalCenter
        width: Style.space(14)
        textFormat: Text.PlainText
        text: String.fromCodePoint(section.open ? 0xF0140 : 0xF0142)
        color: Qt.darker(root.fg, 1.4)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      PanelSectionHeader {
        id: title
        anchors.left: chevron.right
        anchors.verticalCenter: parent.verticalCenter
        text: section.title
        foreground: root.fg
        fontFamily: root.fontFamily
      }

      Text {
        anchors.left: title.right
        anchors.leftMargin: Style.space(10)
        anchors.right: toggle.left
        anchors.rightMargin: Style.space(10)
        anchors.verticalCenter: title.verticalCenter
        anchors.verticalCenterOffset: Math.round(title.topPadding / 2)
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
        textFormat: Text.PlainText
        text: section.summary
        color: Qt.darker(root.fg, 1.4)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      // Without a switch it still holds its place, so all summaries line up.
      ToggleSwitch {
        id: toggle
        opacity: section.switchable ? 1 : 0
        enabled: section.switchable
        anchors.right: parent.right
        anchors.verticalCenter: title.verticalCenter
        anchors.verticalCenterOffset: Math.round(title.topPadding / 2)
        trackHeight: Math.round(title.font.pixelSize * 1.2)
        cursorPad: Style.space(3)
        checked: section.checked
        foreground: root.fg
        onToggled: section.toggled()

        PanelToolTip {
          visible: toggle.containsMouse
          text: section.checked ? root.tr("on") : root.tr("offLower")
          fontFamily: root.fontFamily
        }
      }
    }

    Column {
      id: body
      width: parent.width
      visible: section.open
      spacing: Style.space(10)
    }
  }

  // Screen off or sleep for one power source: its own switch and minutes.
  component SourceRow: Item {
    id: sourceRow

    property string name: ""
    property string source: "ac"
    readonly property bool on: Settings.enabled(root.settings, name, source)
    readonly property int minutes: Settings.minutes(root.settings, name, source)

    width: parent ? parent.width : 0
    implicitHeight: stepper.implicitHeight

    Text {
      anchors.left: parent.left
      anchors.right: sourceToggle.left
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
      textFormat: Text.PlainText
      text: root.tr(sourceRow.source) + (sourceRow.source === root.liveSource ? " · " + root.tr("now") : "")
      color: Qt.darker(root.fg, 1.4)
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }

    ToggleSwitch {
      id: sourceToggle
      anchors.right: stepper.left
      anchors.rightMargin: Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      trackHeight: Math.round(Style.font.caption * 1.2)
      cursorPad: Style.space(3)
      checked: sourceRow.on
      foreground: root.fg
      onToggled: root.persistTiming(sourceRow.name, !sourceRow.on, sourceRow.minutes, sourceRow.source)
    }

    Stepper {
      id: stepper
      anchors.right: parent.right
      fieldWidth: Style.space(110)
      enabled: sourceRow.on
      opacity: enabled ? 1 : 0.4
      foreground: root.fg
      fontFamily: root.fontFamily
      from: 1
      to: Settings.MAX_MINUTES
      value: sourceRow.minutes
      onModified: function(v) { root.persistTiming(sourceRow.name, true, v, sourceRow.source) }
    }
  }

  component Note: Text {
    width: parent ? parent.width : 0
    wrapMode: Text.WordWrap
    color: Qt.darker(root.fg, 1.4)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // A running shutdown timer swaps the moon for a power icon.
    text: String.fromCodePoint(root.shutdownActive ? 0xF0425 : 0xF0904)
    tooltipText: root.shutdownActive ? root.tr("tooltipShutdown", root.shutdownTime)
      : root.wallpaperEnabled ? root.tr("tooltipRotate", root.wallpaperMinutes)
      : root.tr("tooltipManual")
    onPressed: function(b) {
      if (b === Qt.RightButton) root.nextWallpaper()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(10)

        // ---------- Hero ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            text: String.fromCodePoint(0xF0904)
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: langButton.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: root.tr("title")
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: ((root.hasBattery ? root.tr(root.liveSource + "Short") + " · " : "")
                + (root.shutdownActive ? root.tr("shutdownHero", root.shutdownTime)
                  : root.tr("sleepIn") + " "
                    + (root.suspendEnabled ? root.suspendMinutes + " " + root.tr("min") : root.tr("off")))).toUpperCase()
              color: Qt.darker(root.fg, 1.4)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }

          // Omarchy has no settings window for plugins, so the language
          // switch lives here. A click picks the other language explicitly.
          Button {
            id: langButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.lang.toUpperCase()
            tooltipText: root.tr("languageTooltip")
            foreground: root.fg
            fontFamily: root.fontFamily
            fontSize: Style.font.caption
            horizontalPadding: Style.space(6)
            verticalPadding: Style.space(2)
            bordered: true
            onClicked: root.persist({ language: root.lang === "de" ? "en" : "de" })
          }
        }

        Note {
          visible: !!root.service && root.service.stayAwake
            && (root.screenOffEnabled || root.suspendEnabled || (root.fadeEnabled && root.dimSupported))
          text: root.tr("stayAwake")
        }

        PanelSeparator { foreground: root.fg }

        // ---------- Wallpaper ----------
        Section {
          name: "wallpaper"
          title: root.tr("wallpaper")
          summary: root.minutesSummary(root.wallpaperEnabled, root.wallpaperMinutes)
          checked: root.wallpaperEnabled
          onToggled: root.persistTiming("wallpaper", !root.wallpaperEnabled, root.wallpaperMinutes)

          Row {
            width: parent.width
            spacing: Style.space(10)

            Stepper {
              inline: true
              enabled: root.wallpaperEnabled
              opacity: enabled ? 1 : 0.4
              label: root.tr("wallpaperEvery")
              width: parent.width - nextButton.width - parent.spacing
              fieldWidth: Style.space(110)
              foreground: root.fg
              fontFamily: root.fontFamily
              from: 1
              to: Settings.MAX_MINUTES
              value: root.wallpaperMinutes
              onModified: function(v) { root.persistTiming("wallpaper", true, v) }
            }

            Button {
              id: nextButton
              anchors.verticalCenter: parent.verticalCenter
              iconText: String.fromCodePoint(0xF04AD)
              tooltipText: root.tr("next")
              foreground: root.fg
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              bordered: true
              onClicked: root.nextWallpaper()
            }
          }
        }

        // ---------- Screensaver ----------
        Section {
          name: "screensaver"
          title: root.tr("screensaver")
          summary: root.minutesSummary(root.screensaverEnabled, root.screensaverMinutes)
          checked: root.screensaverEnabled
          onToggled: root.persist({ screensaverEnabled: !root.screensaverEnabled })

          Stepper {
            inline: true
            width: parent.width
            enabled: root.screensaverEnabled
            opacity: enabled ? 1 : 0.4
            label: root.tr("screensaverAfter")
            fieldWidth: Style.space(110)
            foreground: root.fg
            fontFamily: root.fontFamily
            from: 1
            to: Settings.MAX_MINUTES
            value: root.screensaverMinutes
            onModified: function(v) { root.persist({ screensaverMinutes: v }) }
          }
        }

        // ---------- Dim ----------
        // Hidden without a display whose brightness can be set, and greyed
        // out while the screensaver is off. The stored settings stay, so they
        // work again once a capable display is back.
        Section {
          name: "dim"
          visible: root.dimSupported
          enabled: root.dimAvailable
          opacity: enabled ? 1 : 0.4
          title: root.tr("dim")
          summary: root.dimEnabled ? root.dimPercent + " %" : root.tr("offLower")
          checked: root.dimEnabled
          onToggled: root.persist({ screensaverDimEnabled: !root.dimEnabled, screensaverDimPercent: root.dimPercent })

          Stepper {
            inline: true
            width: parent.width
            enabled: root.dimEnabled
            opacity: enabled ? 1 : 0.4
            label: root.tr("dimTo")
            fieldWidth: Style.space(110)
            foreground: root.fg
            fontFamily: root.fontFamily
            from: 1
            to: 99
            value: root.dimPercent
            onModified: function(v) { root.persist({ screensaverDimEnabled: true, screensaverDimPercent: v }) }
          }
        }

        // ---------- Dim when idle ----------
        Section {
          name: "fade"
          visible: root.dimSupported
          title: root.tr("fade")
          summary: root.fadeEnabled ? root.fadeStart + " " + root.tr("minShort") + " → " + root.fadePercent + " %" : root.tr("offLower")
          checked: root.fadeEnabled
          onToggled: root.persist({ idleDimEnabled: !root.fadeEnabled, idleDimStartMinutes: root.fadeStart,
            idleDimStepSeconds: root.fadeStep, idleDimPercent: root.fadePercent })

          Column {
            width: parent.width
            spacing: Style.space(10)
            enabled: root.fadeEnabled
            opacity: enabled ? 1 : 0.4

            Stepper {
              inline: true
              width: parent.width
              label: root.tr("fadeStart")
              fieldWidth: Style.space(110)
              foreground: root.fg
              fontFamily: root.fontFamily
              from: Settings.FADE_START.min
              to: Settings.FADE_START.max
              value: root.fadeStart
              onModified: function(v) { root.persist({ idleDimEnabled: true, idleDimStartMinutes: v }) }
            }

            Stepper {
              inline: true
              width: parent.width
              label: root.tr("fadeStep")
              fieldWidth: Style.space(110)
              foreground: root.fg
              fontFamily: root.fontFamily
              from: Settings.FADE_STEP.min
              to: Settings.FADE_STEP.max
              value: root.fadeStep
              onModified: function(v) { root.persist({ idleDimEnabled: true, idleDimStepSeconds: v }) }
            }

            Stepper {
              inline: true
              width: parent.width
              label: root.tr("fadeTo")
              fieldWidth: Style.space(110)
              foreground: root.fg
              fontFamily: root.fontFamily
              from: 1
              to: 99
              value: root.fadePercent
              onModified: function(v) { root.persist({ idleDimEnabled: true, idleDimPercent: v }) }
            }
          }

          // Opening the screensaver restarts the idle clock, so a later start
          // only comes while the screensaver already dims.
          Note {
            visible: root.fadeEnabled && root.screensaverEnabled && root.fadeStart >= root.screensaverMinutes
            text: root.tr("fadeAfterSaver")
            color: Color.urgent
          }

          Note {
            visible: root.fadeEnabled && root.fadeEta !== ""
              && !(root.screensaverEnabled && root.fadeStart >= root.screensaverMinutes)
            text: root.fadeEta
            color: root.fg
          }

          Note { text: root.tr("fadeNote") }
        }

        // ---------- Screen off ----------
        // With a battery, AC and battery each get their own switch and time
        // in the open section; the row only summarises them.
        Section {
          name: "screenOff"
          title: root.tr("screenOff")
          summary: root.sourceSummary("screenOff")
          switchable: !root.hasBattery
          checked: root.screenOffEnabled
          onToggled: root.persistTiming("screenOff", !root.screenOffEnabled, root.screenOffMinutes, "ac")

          Stepper {
            visible: !root.hasBattery
            inline: true
            width: parent.width
            enabled: root.screenOffEnabled
            opacity: enabled ? 1 : 0.4
            label: root.tr("screenOffAfter")
            fieldWidth: Style.space(110)
            foreground: root.fg
            fontFamily: root.fontFamily
            from: 1
            to: Settings.MAX_MINUTES
            value: root.screenOffMinutes
            onModified: function(v) { root.persistTiming("screenOff", true, v, "ac") }
          }

          SourceRow { visible: root.hasBattery; name: "screenOff"; source: "ac" }
          SourceRow { visible: root.hasBattery; name: "screenOff"; source: "battery" }

          Note {
            visible: root.hasBattery && !Settings.batteryOwn(root.settings, "screenOff")
            text: root.tr("batteryFollows")
          }
        }

        // ---------- Sleep ----------
        // Sleep is paused while the shutdown timer runs, so it is greyed out
        // and locked until the timer ends or is cancelled.
        Section {
          name: "suspend"
          title: root.tr("sleep")
          summary: root.sourceSummary("suspend")
          switchable: !root.hasBattery
          checked: root.suspendEnabled
          onToggled: root.persistTiming("suspend", !root.suspendEnabled, root.suspendMinutes, "ac")

          Column {
            width: parent.width
            spacing: Style.space(10)
            enabled: !root.shutdownActive
            opacity: enabled ? 1 : 0.4

            Stepper {
              visible: !root.hasBattery
              inline: true
              width: parent.width
              enabled: root.suspendEnabled
              opacity: enabled ? 1 : 0.4
              label: root.tr("sleepAfter")
              fieldWidth: Style.space(110)
              foreground: root.fg
              fontFamily: root.fontFamily
              from: 1
              to: Settings.MAX_MINUTES
              value: root.suspendMinutes
              onModified: function(v) { root.persistTiming("suspend", true, v, "ac") }
            }

            SourceRow { visible: root.hasBattery; name: "suspend"; source: "ac" }
            SourceRow { visible: root.hasBattery; name: "suspend"; source: "battery" }

            Note {
              visible: root.hasBattery && !Settings.batteryOwn(root.settings, "suspend")
              text: root.tr("batteryFollows")
            }

            // Opening the screensaver restarts the idle clock; without one it
            // runs from the last input.
            Note { text: root.tr(root.screensaverEnabled ? "sleepNote" : "sleepNoteNoSaver") }
          }

          Note {
            visible: root.shutdownActive && root.suspendEnabled
            text: root.tr("sleepPaused")
          }
        }

        // ---------- Shutdown timer ----------
        // One-shot: the switch starts or cancels a countdown in real time.
        Section {
          name: "shutdown"
          title: root.tr("shutdown")
          summary: root.shutdownActive ? root.tr("timeLeft", root.shutdownLeft) : root.duration(root.shutdownMinutes)
          checked: root.shutdownActive
          onToggled: {
            if (!root.service) return
            if (root.shutdownActive) root.service.cancelShutdown()
            else root.service.startShutdown(root.shutdownMinutes)
          }

          // Hours and minutes side by side; stored as total minutes (1 to 24 h).
          Row {
            id: shutdownFields
            width: parent.width
            visible: !root.shutdownActive
            spacing: Style.space(10)

            readonly property real fieldWidth: (width - spacing) / 2

            Stepper {
              width: shutdownFields.fieldWidth
              label: root.tr("hours")
              fieldWidth: width
              foreground: root.fg
              fontFamily: root.fontFamily
              from: 0
              to: Settings.MAX_MINUTES / 60
              value: Math.floor(root.shutdownMinutes / 60)
              onModified: function(v) { root.persistShutdown(v, root.shutdownMinutes % 60) }
            }

            Stepper {
              width: shutdownFields.fieldWidth
              label: root.tr("minutes")
              fieldWidth: width
              foreground: root.fg
              fontFamily: root.fontFamily
              from: 0
              to: 59
              value: root.shutdownMinutes % 60
              onModified: function(v) { root.persistShutdown(Math.floor(root.shutdownMinutes / 60), v) }
            }
          }

          Text {
            width: parent.width
            visible: root.shutdownActive
            text: root.tr("shutdownAt", root.shutdownTime)
            elide: Text.ElideRight
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }
        }
      }
    }
  }
}
