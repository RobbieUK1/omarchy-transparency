import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "robbie.transparency"
  ipcTarget: "robbie.transparency"

  readonly property string ctl:
    Quickshell.env("HOME") + "/.config/omarchy/plugins/robbie.transparency/scripts/transparency-ctl"
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property int captionPx: Style.font.caption
  readonly property int bodyPx: Style.font.body

  property real wOpacity: 0.90
  property bool excludeMedia: true
  property var excludedApps: []
  property var runningClasses: []
  property bool showSettings: false
  property string inputClass: ""

  readonly property int percent: Math.round((slider.dragging ? slider.liveValue : root.wOpacity) * 100)

  component MutedCaption: Text {
    property real tint: 0.6
    textFormat: Text.PlainText
    color: Util.alpha(Color.popups.text, tint)
    font.family: root.fontFamily
    font.pixelSize: root.captionPx
  }

  function startState(args) {
    stateProc.command = [root.ctl].concat(args)
    stateProc.running = true
  }

  function startRunning() { runningProc.running = true }

  function adoptState(text) {
    var res
    try { res = JSON.parse(String(text || "")) } catch (e) { return }
    if (!res) return
    if (res.apps !== undefined) {
      root.excludedApps = res.apps
      return
    }
    if (res.state) {
      if (res.state.opacity !== undefined) root.wOpacity = Number(res.state.opacity)
      if (res.state.ignoreVideoWeb !== undefined) root.excludeMedia = !!res.state.ignoreVideoWeb
      if (res.state.excludedApps !== undefined) root.excludedApps = res.state.excludedApps
    }
  }

  function adoptRunning(text) {
    var res
    try { res = JSON.parse(String(text || "")) } catch (e) { return }
    if (res && res.classes !== undefined) root.runningClasses = res.classes
  }

  function refresh() {
    root.startState(["readback"])
    root.startRunning()
  }

  function commit(v) { root.startState(["set", JSON.stringify({ opacity: v })]) }

  function toggleMedia() {
    root.excludeMedia = !root.excludeMedia
    root.startState(["set", JSON.stringify({ ignoreVideoWeb: root.excludeMedia })])
  }

  function addExclusion(cls) {
    if (!cls) return
    root.startState(["exclude", "add", cls])
    root.inputClass = ""
  }

  function removeExclusion(cls) {
    if (!cls) return
    root.startState(["exclude", "remove", cls])
  }

  Process {
    id: stateProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.adoptState(text)
    }
  }

  Process {
    id: runningProc
    command: [root.ctl, "running"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.adoptRunning(text)
    }
  }

  Component.onCompleted: root.refresh()
  onOpenedChanged: if (root.opened) { root.showSettings = false; root.refresh(); root.inputClass = "" }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\uf042"
    onPressed: function(b) { root.toggle() }
  }

  PopupCard {
    id: card
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    padding: Style.spacing.popupPadding
    contentWidth: card.fittedContentWidth(Style.space(330))
    contentHeight: card.fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      width: parent.width
      spacing: Style.spacing.sm

      PanelHero {
        width: parent.width
        title: "Window Transparency"
        meta: root.excludeMedia ? "Media & web pages kept opaque" : "Applied to all windows"
        foreground: Color.popups.text
        fontFamily: root.fontFamily
        iconComponent: Component {
          Text {
            text: "\uf042"
            color: Color.popups.text
            font.family: root.fontFamily
            font.pixelSize: root.captionPx
          }
        }
        trailingControl: Component {
          PanelActionButton {
            id: settingsBtn
            iconText: root.showSettings ? "\uf00d" : "\uf013"
            fontFamily: root.fontFamily
            bordered: true
            enabled: true
            onClicked: {
              root.showSettings = !root.showSettings
              if (root.showSettings) root.refresh()
            }
            tooltipText: root.showSettings ? "Close settings" : "Settings"
          }
        }
      }

      PanelSeparator { foreground: Color.popups.text }

      Item {
        width: parent.width
        implicitHeight: Math.max(sectionHeader.implicitHeight, percentText.implicitHeight)

        PanelSectionHeader {
          id: sectionHeader
          text: "GLOBAL OPACITY"
          foreground: Color.popups.text
          font.family: root.fontFamily
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          id: percentText
          textFormat: Text.PlainText
          text: root.percent + "%"
          color: Util.alpha(Color.popups.text, 0.55)
          font.family: root.fontFamily
          font.pixelSize: root.captionPx
          font.bold: true
          anchors.right: parent.right
          anchors.rightMargin: Style.spacing.xs
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      PanelSlider {
        id: slider
        bar: root.bar
        width: parent.width
        minimum: 0.30
        maximum: 1.0
        step: 0.05
        value: root.wOpacity
        onMoved: function(v) { root.wOpacity = v }
        onReleased: function(v) { root.commit(v) }
      }

      MutedCaption {
        tint: 0.5
        width: parent.width
        leftPadding: Style.spacing.xs
        text: "Lower is more transparent \u00b7 release to apply"
      }

      PanelSeparator { foreground: Color.popups.text; visible: !root.showSettings }

      Toggle {
        visible: !root.showSettings
        label: "Keep video & web pages opaque"
        description: "Applies to common browsers and video players"
        checked: root.excludeMedia
        hasCursor: false
        foreground: Color.popups.text
        accent: Color.accent
        fontFamily: root.fontFamily
        onClicked: root.toggleMedia()
      }

      // Settings view
      Column {
        id: settingsCol
        visible: root.showSettings
        width: parent.width
        spacing: Style.spacing.sm

        MutedCaption {
          text: "SETTINGS"
          font.bold: true
        }

        Toggle {
          label: "Keep video & web pages opaque"
          description: "Browsers and video players stay at 100% opacity"
          checked: root.excludeMedia
          hasCursor: false
          foreground: Color.popups.text
          accent: Color.accent
          fontFamily: root.fontFamily
          onClicked: root.toggleMedia()
        }

        PanelSeparator { foreground: Color.popups.text }

        MutedCaption {
          text: "EXCLUDE APPS (always opaque)"
          font.bold: true
        }

        MutedCaption {
          width: parent.width
          wrapMode: Text.WordWrap
          text: "Add window classes that should never be transparent. Matched exactly as the Hyprland class string."
        }

        Row {
          width: parent.width
          spacing: Style.spacing.xs

          TextField {
            id: classField
            placeholderText: "e.g. discord, spotify, vlc"
            foreground: Color.popups.text
            accent: Color.accent
            font.family: root.fontFamily
            font.pixelSize: root.bodyPx
            width: parent.width - addBtn.width - Style.spacing.xs
            text: root.inputClass
            onTextChanged: root.inputClass = text
            onAccepted: root.addExclusion(classField.text.trim())
          }

          Button {
            id: addBtn
            text: "Add"
            fontFamily: root.fontFamily
            fontSize: root.bodyPx
            onClicked: root.addExclusion(classField.text.trim())
          }
        }

        MutedCaption {
          text: "Currently running"
          visible: root.runningClasses.length > 0
        }

        Flow {
          width: parent.width
          spacing: Style.spacing.xs
          visible: root.runningClasses.length > 0

          Repeater {
            model: root.runningClasses
            delegate: Button {
              text: modelData
              fontFamily: root.fontFamily
              fontSize: root.captionPx
              onClicked: root.addExclusion(modelData)
              tooltipText: "Add " + modelData
            }
          }
        }

        MutedCaption {
          text: "Excluded (" + root.excludedApps.length + ")"
          visible: root.excludedApps.length > 0
        }

        Repeater {
          model: root.excludedApps
          delegate: Row {
            width: parent.width
            spacing: Style.spacing.xs

            Text {
              text: modelData
              color: Color.popups.text
              font.family: root.fontFamily
              font.pixelSize: root.bodyPx
              elide: Text.ElideRight
              width: parent.width - removeBtn.width - Style.spacing.xs
            }

            PanelActionButton {
              id: removeBtn
              iconText: "\uf00d"
              fontFamily: root.fontFamily
              bordered: true
              onClicked: root.removeExclusion(modelData)
              tooltipText: "Remove"
            }
          }
        }

        MutedCaption {
          tint: 0.5
          text: "No exclusions yet"
          visible: root.excludedApps.length === 0
        }

        PanelSeparator { foreground: Color.popups.text }

        MutedCaption {
          tint: 0.5
          width: parent.width
          wrapMode: Text.WordWrap
          text: "Tip: use 'hyprctl clients' to see exact class names."
        }
      }
    }
  }
}