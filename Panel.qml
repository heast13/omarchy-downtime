import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "I18n.js" as I18n

Panel {
  id: root
  moduleName: "heast13.downtime"
  ipcTarget: "downtime.panel"

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string lang: I18n.language(setting("language", "auto"), Qt.locale().name)

  readonly property int wallpaperMinutes: intSetting("wallpaperMinutes", 0, 0)
  readonly property bool screensaverEnabled: setting("screensaverEnabled", true) !== false
  readonly property int screensaverMinutes: intSetting("screensaverMinutes", 5, 1)
  readonly property int screenOffMinutes: intSetting("screenOffMinutes", 10, 0)
  readonly property int suspendMinutes: intSetting("suspendMinutes", 0, 0)

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

  function nextWallpaper() { Quickshell.execDetached(["omarchy-theme-bg-next"]) }

  function minutesText(m) {
    return m <= 0 ? root.tr("off") : m + " " + root.tr("min")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: String.fromCodePoint(0xF04B2)
    tooltipText: root.wallpaperMinutes > 0
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
            text: String.fromCodePoint(0xF04B2)
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
              text: (root.tr("sleepIn") + " " + root.minutesText(root.suspendMinutes)).toUpperCase()
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

        PanelSectionHeader {
          text: root.tr("wallpaper")
          foreground: root.fg
          fontFamily: root.fontFamily
        }

        Row {
          width: parent.width
          spacing: Style.space(10)

          NumberField {
            label: root.tr("wallpaperEvery")
            width: parent.width - nextButton.width - parent.spacing
            fieldWidth: width
            foreground: root.fg
            fontFamily: root.fontFamily
            from: 0
            to: 1440
            value: root.wallpaperMinutes
            onModified: function(v) { root.persist({ wallpaperMinutes: v }) }
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

        PanelSectionHeader {
          text: root.tr("screensaver")
          foreground: root.fg
          fontFamily: root.fontFamily
        }

        Toggle {
          width: parent.width
          label: root.tr("screensaverToggle")
          description: root.screensaverEnabled ? root.tr("screensaverOn") : root.tr("screensaverOff")
          checked: root.screensaverEnabled
          foreground: root.fg
          fontFamily: root.fontFamily
          onClicked: root.persist({ screensaverEnabled: !root.screensaverEnabled })
        }

        NumberField {
          width: parent.width
          visible: root.screensaverEnabled
          label: root.tr("screensaverAfter")
          fieldWidth: width
          foreground: root.fg
          fontFamily: root.fontFamily
          from: 1
          to: 1440
          value: root.screensaverMinutes
          onModified: function(v) { root.persist({ screensaverMinutes: v }) }
        }

        // ---------- Screen off ----------
        PanelSeparator { foreground: root.fg }

        PanelSectionHeader {
          text: root.tr("screenOff")
          foreground: root.fg
          fontFamily: root.fontFamily
        }

        NumberField {
          width: parent.width
          label: root.tr("screenOffAfter")
          fieldWidth: width
          foreground: root.fg
          fontFamily: root.fontFamily
          from: 0
          to: 1440
          value: root.screenOffMinutes
          onModified: function(v) { root.persist({ screenOffMinutes: v }) }
        }

        // ---------- Sleep ----------
        PanelSeparator { foreground: root.fg }

        PanelSectionHeader {
          text: root.tr("sleep")
          foreground: root.fg
          fontFamily: root.fontFamily
        }

        NumberField {
          width: parent.width
          label: root.tr("sleepAfter")
          fieldWidth: width
          foreground: root.fg
          fontFamily: root.fontFamily
          from: 0
          to: 1440
          value: root.suspendMinutes
          onModified: function(v) { root.persist({ suspendMinutes: v }) }
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
