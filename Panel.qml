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
  readonly property bool screenOffEnabled: Settings.enabled(settings, "screenOff")
  readonly property int screenOffMinutes: Settings.minutes(settings, "screenOff")
  readonly property bool suspendEnabled: Settings.enabled(settings, "suspend")
  readonly property int suspendMinutes: Settings.minutes(settings, "suspend")

  function tr(key, arg) { return I18n.tr(root.lang, key, arg) }

  function intSetting(name, fallback, min) {
    var v = Math.floor(Number(setting(name, fallback)))
    return isFinite(v) ? Math.max(min, v) : fallback
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
  function persistTiming(name, on, minutes) {
    var values = {}
    values[Settings.timings[name].flag] = on
    values[Settings.timings[name].minutes] = minutes
    root.persist(values)
  }

  function persistScreensaver(on, minutes) {
    root.persist({ screensaverEnabled: on, screensaverMinutes: minutes })
  }

  function nextWallpaper() { Quickshell.execDetached(["omarchy-theme-bg-next"]) }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // Section title on the left, a small on/off switch on the right.
  component SwitchHeader: Item {
    id: header

    property string text: ""
    property bool checked: false
    signal toggled()

    width: parent ? parent.width : 0
    implicitHeight: Math.max(title.implicitHeight, toggle.implicitHeight)

    PanelSectionHeader {
      id: title
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: header.text
      foreground: root.fg
      fontFamily: root.fontFamily
    }

    ToggleSwitch {
      id: toggle
      anchors.right: parent.right
      anchors.verticalCenter: title.verticalCenter
      anchors.verticalCenterOffset: Math.round(title.topPadding / 2)
      trackHeight: Math.round(title.font.pixelSize * 1.2)
      cursorPad: Style.space(3)
      checked: header.checked
      foreground: root.fg
      onToggled: header.toggled()

      PanelToolTip {
        visible: toggle.containsMouse
        text: header.checked ? root.tr("on") : root.tr("offLower")
        fontFamily: root.fontFamily
      }
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: String.fromCodePoint(0xF0904)
    tooltipText: root.wallpaperEnabled
      ? root.tr("tooltipRotate", root.wallpaperMinutes)
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
        spacing: Style.space(14)

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
            anchors.right: parent.right
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
              text: (root.tr("sleepIn") + " "
                + (root.suspendEnabled ? root.suspendMinutes + " " + root.tr("min") : root.tr("off"))).toUpperCase()
              color: Qt.darker(root.fg, 1.4)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        // ---------- Wallpaper ----------
        PanelSeparator { foreground: root.fg }

        SwitchHeader {
          text: root.tr("wallpaper")
          checked: root.wallpaperEnabled
          onToggled: root.persistTiming("wallpaper", !root.wallpaperEnabled, root.wallpaperMinutes)
        }

        Row {
          width: parent.width
          spacing: Style.space(10)

          NumberField {
            visible: root.wallpaperEnabled
            label: root.tr("wallpaperEvery")
            width: parent.width - nextButton.width - parent.spacing
            fieldWidth: width
            foreground: root.fg
            fontFamily: root.fontFamily
            from: 1
            to: Settings.MAX_MINUTES
            value: root.wallpaperMinutes
            onModified: function(v) { root.persistTiming("wallpaper", true, v) }
          }

          Button {
            id: nextButton
            anchors.bottom: parent.bottom
            iconText: String.fromCodePoint(0xF04AD)
            text: root.tr("next")
            foreground: root.fg
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            bordered: true
            onClicked: root.nextWallpaper()
          }
        }

        // ---------- Screensaver ----------
        PanelSeparator { foreground: root.fg }

        SwitchHeader {
          text: root.tr("screensaver")
          checked: root.screensaverEnabled
          onToggled: root.persistScreensaver(!root.screensaverEnabled, root.screensaverMinutes)
        }

        NumberField {
          width: parent.width
          visible: root.screensaverEnabled
          label: root.tr("screensaverAfter")
          fieldWidth: width
          foreground: root.fg
          fontFamily: root.fontFamily
          from: 1
          to: Settings.MAX_MINUTES
          value: root.screensaverMinutes
          onModified: function(v) { root.persistScreensaver(true, v) }
        }

        // ---------- Screen off ----------
        PanelSeparator { foreground: root.fg }

        SwitchHeader {
          text: root.tr("screenOff")
          checked: root.screenOffEnabled
          onToggled: root.persistTiming("screenOff", !root.screenOffEnabled, root.screenOffMinutes)
        }

        NumberField {
          width: parent.width
          visible: root.screenOffEnabled
          label: root.tr("screenOffAfter")
          fieldWidth: width
          foreground: root.fg
          fontFamily: root.fontFamily
          from: 1
          to: Settings.MAX_MINUTES
          value: root.screenOffMinutes
          onModified: function(v) { root.persistTiming("screenOff", true, v) }
        }

        // ---------- Sleep ----------
        PanelSeparator { foreground: root.fg }

        SwitchHeader {
          text: root.tr("sleep")
          checked: root.suspendEnabled
          onToggled: root.persistTiming("suspend", !root.suspendEnabled, root.suspendMinutes)
        }

        NumberField {
          width: parent.width
          visible: root.suspendEnabled
          label: root.tr("sleepAfter")
          fieldWidth: width
          foreground: root.fg
          fontFamily: root.fontFamily
          from: 1
          to: Settings.MAX_MINUTES
          value: root.suspendMinutes
          onModified: function(v) { root.persistTiming("suspend", true, v) }
        }

        Text {
          width: parent.width
          text: root.tr("sleepNote")
          wrapMode: Text.WordWrap
          color: Qt.darker(root.fg, 1.4)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
