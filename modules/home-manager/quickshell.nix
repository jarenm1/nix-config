{ config, lib, pkgs, ... }:

let
  cfg = config.programs.quickshellBar;
in
{
  options.programs.quickshellBar = {
    enable = lib.mkEnableOption "a Quickshell top bar";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.quickshell;
      description = "Quickshell package used to run the bar.";
    };

    configName = lib.mkOption {
      type = lib.types.str;
      default = "top-bar";
      description = "Named Quickshell config directory under ~/.config/quickshell.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."quickshell/${cfg.configName}/shell.qml".text = ''
      import QtQuick
      import Quickshell
      import Quickshell.Wayland
      import Quickshell.Io
      import Quickshell.Services.UPower

      ShellRoot {
        id: root

        SystemClock {
          id: clock
          precision: SystemClock.Seconds
        }

        FileView {
          id: sysfsBat0Cap
          path: "/sys/class/power_supply/BAT0/capacity"
          printErrors: false
        }

        FileView {
          id: sysfsBat0Stat
          path: "/sys/class/power_supply/BAT0/status"
          printErrors: false
        }

        FileView {
          id: sysfsBat1Cap
          path: "/sys/class/power_supply/BAT1/capacity"
          printErrors: false
        }

        FileView {
          id: sysfsBat1Stat
          path: "/sys/class/power_supply/BAT1/status"
          printErrors: false
        }

        readonly property var upowerDev: {
          if (UPower.displayDevice && UPower.displayDevice.isPresent && (UPower.displayDevice.isLaptopBattery || UPower.displayDevice.type === UPowerDeviceType.Battery || UPower.displayDevice.type === 2)) {
            return UPower.displayDevice;
          }
          if (UPower.devices) {
            for (let i = 0; i < (UPower.devices.values ? UPower.devices.values.length : 0); i++) {
              let d = UPower.devices.values[i];
              if (d && d.isPresent && (d.isLaptopBattery || d.type === UPowerDeviceType.Battery || d.type === 2)) {
                return d;
              }
            }
          }
          return null;
        }

        readonly property bool hasSysfsBat: (sysfsBat0Cap.loaded && sysfsBat0Cap.text().trim().length > 0) ||
                                           (sysfsBat1Cap.loaded && sysfsBat1Cap.text().trim().length > 0)

        readonly property bool hasBattery: upowerDev !== null || hasSysfsBat

        readonly property int batteryPct: {
          if (upowerDev) {
            let p = upowerDev.percentage;
            if (p <= 1.0 && p > 0.0) return Math.round(p * 100);
            return Math.round(p);
          }
          if (sysfsBat0Cap.loaded && sysfsBat0Cap.text().trim().length > 0) {
            return parseInt(sysfsBat0Cap.text().trim(), 10) || 0;
          }
          if (sysfsBat1Cap.loaded && sysfsBat1Cap.text().trim().length > 0) {
            return parseInt(sysfsBat1Cap.text().trim(), 10) || 0;
          }
          return 0;
        }

        readonly property bool isCharging: {
          if (upowerDev) {
            return upowerDev.state === UPowerDeviceState.Charging || upowerDev.state === 1 ||
                   upowerDev.state === UPowerDeviceState.PendingCharge || upowerDev.state === 5;
          }
          if (sysfsBat0Stat.loaded && sysfsBat0Stat.text().trim().toLowerCase() === "charging") return true;
          if (sysfsBat1Stat.loaded && sysfsBat1Stat.text().trim().toLowerCase() === "charging") return true;
          return false;
        }

        component AnimatedDigit: Item {
          id: digit
          property string value: ""
          property color textColor: "#f0f0f0"
          property font font

          implicitWidth: measureText.implicitWidth
          implicitHeight: measureText.implicitHeight
          clip: true

          Text {
            id: measureText
            visible: false
            text: digit.value.length > 0 ? digit.value : "0"
            font: digit.font
          }

          property string curVal: value
          property string prevVal: ""

          onValueChanged: {
            if (value !== curVal) {
              prevVal = curVal;
              curVal = value;
              anim.restart();
            }
          }

          Text {
            id: prevTextItem
            text: digit.prevVal
            color: digit.textColor
            font: digit.font
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            opacity: 0
          }

          Text {
            id: curTextItem
            text: digit.curVal
            color: digit.textColor
            font: digit.font
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            opacity: 1
          }

          ParallelAnimation {
            id: anim
            NumberAnimation {
              target: prevTextItem
              property: "anchors.verticalCenterOffset"
              from: 0
              to: -digit.height * 0.7
              duration: 200
              easing.type: Easing.OutCubic
            }
            NumberAnimation {
              target: prevTextItem
              property: "opacity"
              from: 1
              to: 0
              duration: 150
            }
            NumberAnimation {
              target: curTextItem
              property: "anchors.verticalCenterOffset"
              from: digit.height * 0.7
              to: 0
              duration: 200
              easing.type: Easing.OutCubic
            }
            NumberAnimation {
              target: curTextItem
              property: "opacity"
              from: 0
              to: 1
              duration: 150
            }
          }
        }

        Variants {
          model: Quickshell.screens

          PanelWindow {
            id: bar
            property var modelData
            screen: modelData

            anchors {
              top: true
              left: true
              right: true
            }

            implicitHeight: 26
            color: "#161616"

            WlrLayershell.namespace: "top-bar"
            WlrLayershell.layer: WlrLayer.Top

            // Bottom border separator
            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              height: 1
              color: "#262626"
            }

            Item {
              anchors.fill: parent
              anchors.leftMargin: 16
              anchors.rightMargin: 16

              // Center: Date & Animated Time (hh:mm:ss)
              Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                  text: Qt.formatDateTime(clock.date, "ddd, MMM d")
                  color: "#8e8e8e"
                  font.pixelSize: 12
                  font.family: "Comic Mono, monospace"
                  anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                  text: "·"
                  color: "#444444"
                  font.pixelSize: 12
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                  id: digitsRow
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 0

                  property string timeStr: Qt.formatDateTime(clock.date, "hh:mm:ss")

                  Repeater {
                    model: 8
                    AnimatedDigit {
                      value: digitsRow.timeStr.length === 8 ? digitsRow.timeStr.charAt(index) : ""
                      textColor: "#f0f0f0"
                      font.pixelSize: 12
                      font.bold: true
                      font.family: "Comic Mono, monospace"
                      anchors.verticalCenter: parent.verticalCenter
                    }
                  }
                }
              }

              // Right: Battery (rendered if supported / present)
              Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                visible: root.hasBattery

                Item {
                  width: 20
                  height: 11
                  anchors.verticalCenter: parent.verticalCenter

                  Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width - 2
                    radius: 2
                    color: "transparent"
                    border.color: "#666666"
                    border.width: 1

                    Rectangle {
                      anchors.left: parent.left
                      anchors.top: parent.top
                      anchors.bottom: parent.bottom
                      anchors.margins: 1.5
                      width: Math.max(1, (parent.width - 3) * Math.min(100, Math.max(0, root.batteryPct)) / 100)
                      radius: 1
                      color: root.isCharging ? "#42dc00" : (root.batteryPct <= 20 ? "#ff5555" : "#e0e0e0")
                    }
                  }

                  Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: 5
                    radius: 0.5
                    color: "#666666"
                  }
                }

                Text {
                  text: (root.isCharging ? "⚡ " : "") + root.batteryPct + "%"
                  color: root.isCharging ? "#42dc00" : (root.batteryPct <= 20 ? "#ff5555" : "#cccccc")
                  font.pixelSize: 11
                  font.family: "Comic Mono, monospace"
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }
          }
        }
      }
    '';
  };
}
