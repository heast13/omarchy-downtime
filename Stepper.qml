import QtQuick
import qs.Commons
import qs.Ui

// Number control with − and + buttons, built to look like the shell's NumberField.
// It has no text input on purpose: an editable TextInput reads the Wayland
// clipboard on every change, with no size or time limit. Values change with the
// buttons (hold to repeat), the mouse wheel or the arrow keys.
Column {
  id: root

  property string label: ""
  property int value: 0
  property int from: 0
  property int to: 100
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.body
  property real fieldWidth: Style.spacing.numberFieldWidth

  // Shown value. Follows `value`, but runs ahead while the user is stepping;
  // the change is reported once, when stepping stops.
  property int current: value
  property int _repeatDir: 0
  property int _repeats: 0
  property real _wheel: 0

  signal modified(int value)

  spacing: Style.spacing.md

  onValueChanged: if (!commitTimer.running && _repeatDir === 0) current = value

  // Bigger steps after holding a button for a while, snapped to round numbers.
  function stepBy(dir, size) {
    var next = size > 1
      ? (dir > 0 ? Math.floor(current / size) + 1 : Math.ceil(current / size) - 1) * size
      : current + dir
    current = Math.max(from, Math.min(to, next))
  }

  function nudge(dir, size) {
    stepBy(dir, size)
    commitTimer.restart()
  }

  function commit() {
    commitTimer.stop()
    if (current !== value) modified(current)
  }

  function startRepeat(dir) {
    _repeatDir = dir
    _repeats = 0
    stepBy(dir, 1)
    repeatTimer.interval = 400
    repeatTimer.restart()
  }

  function stopRepeat() {
    if (_repeatDir === 0) return
    _repeatDir = 0
    repeatTimer.stop()
    commit()
  }

  // Do not lose a step if the panel closes right after a wheel turn.
  Component.onDestruction: if (commitTimer.running) commit()

  Timer {
    id: commitTimer
    interval: 600
    onTriggered: root.commit()
  }

  Timer {
    id: repeatTimer
    repeat: true
    onTriggered: {
      interval = 80
      root._repeats++
      var big = root.to - root.from > 120 ? 15 : 5
      root.stepBy(root._repeatDir, root._repeats < 10 ? 1 : (root._repeats < 30 ? 5 : big))
    }
  }

  Text {
    textFormat: Text.PlainText
    visible: root.label !== ""
    text: root.label
    color: Qt.darker(root.foreground, 1.4)
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  BorderSurface {
    id: box
    width: root.fieldWidth
    height: Math.max(Style.spacing.controlHeight, root.fontSize + Style.spacing.controlPaddingY * 2)
    activeFocusOnTab: true
    radius: Style.cornerRadius

    readonly property bool _hot: hover.hovered
    readonly property var _spec: Border.controlSpec(activeFocus ? "focus" : (_hot ? "hover-cursor" : "normal"), root.foreground, root.accent)

    color: Style.controlFill(activeFocus, _hot, root.foreground, root.accent)
    borderSpec: _spec

    Keys.onUpPressed: root.nudge(1, 1)
    Keys.onDownPressed: root.nudge(-1, 1)
    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_PageUp) { root.nudge(1, 10); event.accepted = true }
      else if (event.key === Qt.Key_PageDown) { root.nudge(-1, 10); event.accepted = true }
    }
    onActiveFocusChanged: if (!activeFocus && commitTimer.running) root.commit()

    HoverHandler { id: hover }

    WheelHandler {
      acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
      onWheel: function(event) {
        root._wheel += event.angleDelta.y
        while (Math.abs(root._wheel) >= 120) {
          var dir = root._wheel > 0 ? 1 : -1
          root._wheel -= dir * 120
          root.nudge(dir, 1)
        }
      }
    }

    Repeater {
      model: [-1, 1]

      Item {
        required property int modelData
        width: box.height
        height: box.height
        anchors.left: modelData < 0 ? parent.left : undefined
        anchors.right: modelData > 0 ? parent.right : undefined
        opacity: (modelData < 0 ? root.current > root.from : root.current < root.to) ? 1 : 0.35

        Text {
          anchors.centerIn: parent
          text: parent.modelData < 0 ? "−" : "+"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: root.fontSize
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onPressed: root.startRepeat(parent.modelData)
          onReleased: root.stopRepeat()
          onCanceled: root.stopRepeat()
        }
      }
    }

    Text {
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: String(root.current)
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
    }
  }
}
