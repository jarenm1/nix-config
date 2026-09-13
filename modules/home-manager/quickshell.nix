{ config, lib, pkgs, ... }:

let
  cfg = config.programs.quickshellClock;
in
{
  options.programs.quickshellClock = {
    enable = lib.mkEnableOption "a Quickshell corner clock overlay";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.quickshell;
      description = "Quickshell package used to run the clock.";
    };

    configName = lib.mkOption {
      type = lib.types.str;
      default = "corner-clock";
      description = "Named Quickshell config directory under ~/.config/quickshell.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."quickshell/${cfg.configName}/shell.qml".text = ''
      import QtQuick
      import Quickshell
      import Quickshell.Wayland

      ShellRoot {
        id: root

        SystemClock {
          id: clock
          precision: SystemClock.Seconds
        }

        Variants {
          model: Quickshell.screens

          Scope {
            id: scope

            property var modelData
            property bool expanded: hoverArea.containsMouse || retractDelay.running

            Timer {
              id: retractDelay
              interval: 350
            }

            // The only input surface: a small corner square.
            PanelWindow {
              id: trigger

              screen: scope.modelData
              color: "transparent"
              focusable: false
              exclusionMode: ExclusionMode.Ignore
              exclusiveZone: 0
              surfaceFormat.opaque: false

              WlrLayershell.namespace: "corner-clock-trigger"
              WlrLayershell.layer: WlrLayer.Top

              anchors {
                bottom: true
                right: true
              }
              implicitWidth: 56
              implicitHeight: 56

              MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton

                onContainsMouseChanged: {
                  if (containsMouse) {
                    retractDelay.stop()
                  } else {
                    retractDelay.restart()
                  }
                }
              }

              // Subtle hint that the corner is live.
              Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: 7
                anchors.rightMargin: 7
                width: 26
                height: 3
                radius: 1.5
                color: Qt.rgba(146 / 255, 167 / 255, 203 / 255, 0.4)
                opacity: scope.expanded ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 150 } }
              }
            }

            // Clock pill. Empty mask: always fully click-through.
            PanelWindow {
              id: pillWin

              screen: scope.modelData
              color: "transparent"
              focusable: false
              exclusionMode: ExclusionMode.Ignore
              exclusiveZone: 0
              surfaceFormat.opaque: false
              mask: Region {}

              WlrLayershell.namespace: "corner-clock"
              WlrLayershell.layer: WlrLayer.Top

              anchors {
                bottom: true
                right: true
              }
              margins {
                bottom: 18
                right: 18
              }
              implicitWidth: pill.implicitWidth
              implicitHeight: pill.implicitHeight

              Rectangle {
                id: pill

                width: parent.width
                height: parent.height
                y: scope.expanded ? 0 : parent.height + 4
                opacity: scope.expanded ? 1 : 0

                Behavior on y {
                  NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                  }
                }
                Behavior on opacity { NumberAnimation { duration: 160 } }

                implicitWidth: content.implicitWidth + 40
                implicitHeight: content.implicitHeight + 30
                radius: 14
                color: Qt.rgba(24 / 255, 24 / 255, 24 / 255, 0.88)
                border.color: Qt.rgba(146 / 255, 167 / 255, 203 / 255, 0.30)
                border.width: 1

                Column {
                  id: content

                  anchors.centerIn: parent
                  anchors.verticalCenterOffset: -2
                  spacing: 1

                  Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 7

                    Text {
                      id: timeText
                      text: Qt.formatDateTime(clock.date, "hh:mm")
                      color: "#f5f5f5"
                      font.family: "Comic Mono"
                      font.pixelSize: 38
                      font.bold: true
                    }

                    Text {
                      text: Qt.formatDateTime(clock.date, "ss")
                      color: "#92a7cb"
                      font.family: "Comic Mono"
                      font.pixelSize: 15
                      anchors.baseline: timeText.baseline
                    }
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "ddd · MMM d")
                    color: "#8f8f8f"
                    font.family: "Comic Mono"
                    font.pixelSize: 13
                  }
                }

                Rectangle {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.bottom: parent.bottom
                  anchors.leftMargin: 14
                  anchors.rightMargin: 14
                  anchors.bottomMargin: 9
                  height: 2
                  radius: 1
                  color: Qt.rgba(146 / 255, 167 / 255, 203 / 255, 0.14)

                  Rectangle {
                    id: fill

                    property real progress: (clock.date.getSeconds() + clock.date.getMilliseconds() / 1000) / 60
                    property real targetWidth: parent.width * progress

                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: targetWidth
                    radius: 1
                    color: "#92a7cb"

                    // Only animate forward steps; the 59->0 reset snaps.
                    Behavior on width {
                      enabled: fill.targetWidth > fill.width
                      NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    '';
  };
}
