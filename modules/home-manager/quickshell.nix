{ inputs, config, lib, pkgs, ... }:

let
  cfg = config.programs.quickshellAudioVisualizer;
  system = pkgs.stdenv.hostPlatform.system;
  quickshellPackage =
    inputs.quickshell.packages.${system}.default or pkgs.quickshell;
in
{
  options.programs.quickshellAudioVisualizer = {
    enable = lib.mkEnableOption "a Quickshell+CAVA ambient audio visualizer layer";

    package = lib.mkOption {
      type = lib.types.package;
      default = quickshellPackage;
      description = "Quickshell package used to run the visualizer.";
    };

    configName = lib.mkOption {
      type = lib.types.str;
      default = "audio-wall";
      description = "Named Quickshell config directory under ~/.config/quickshell.";
    };

    bars = lib.mkOption {
      type = lib.types.ints.positive;
      default = 72;
      description = "Number of CAVA frequency bars to render.";
    };

    framerate = lib.mkOption {
      type = lib.types.ints.positive;
      default = 60;
      description = "CAVA output framerate.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      pkgs.cava
    ];

    xdg.configFile."quickshell/${cfg.configName}/cava.conf".text = ''
      [general]
      bars = ${toString cfg.bars}
      framerate = ${toString cfg.framerate}
      autosens = 1
      sensitivity = 110
      lower_cutoff_freq = 30
      higher_cutoff_freq = 18000

      [input]
      method = pipewire
      source = auto

      [output]
      method = raw
      channels = mono
      raw_target = /dev/stdout
      data_format = ascii
      ascii_max_range = 1000
      bar_delimiter = 44
      frame_delimiter = 10

      [smoothing]
      monstercat = 1
      waves = 0
      noise_reduction = 78
    '';

    xdg.configFile."quickshell/${cfg.configName}/shell.qml".text = ''
      import QtQuick
      import Quickshell
      import Quickshell.Io
      import Quickshell.Wayland

      ShellRoot {
        id: root

        property int barCount: ${toString cfg.bars}
        property var levels: Array(barCount).fill(0)
        property real energy: 0
        property int frame: 0

        function parseFrame(frameText) {
          const trimmed = frameText.trim();
          if (trimmed.length === 0) {
            return;
          }

          const parts = trimmed.split(",");
          const next = [];
          let total = 0;

          for (let i = 0; i < root.barCount; i++) {
            const raw = i < parts.length ? Number(parts[i]) : 0;
            const clamped = Math.max(0, Math.min(1, isNaN(raw) ? 0 : raw / 1000));
            next.push(clamped);
            total += clamped;
          }

          root.levels = next;
          root.energy = total / Math.max(1, next.length);
          root.frame += 1;
        }

        Timer {
          id: restartCava
          interval: 1200
          repeat: false
          onTriggered: cava.running = true
        }

        Process {
          id: cava
          running: true
          command: [ "cava", "-p", Quickshell.shellDir + "/cava.conf" ]

          stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => root.parseFrame(data)
          }

          stderr: SplitParser {
            splitMarker: "\n"
            onRead: data => {
              if (data.trim().length > 0) {
                console.warn("cava: " + data)
              }
            }
          }

          onRunningChanged: {
            if (!running) {
              restartCava.restart()
            }
          }
        }

        Variants {
          model: Quickshell.screens

          PanelWindow {
            id: panel

            property var modelData

            screen: modelData
            color: "transparent"
            aboveWindows: false
            focusable: false
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            surfaceFormat.opaque: false

            WlrLayershell.namespace: "audio-wall"
            WlrLayershell.layer: WlrLayer.Bottom

            anchors {
              top: true
              bottom: true
              left: true
              right: true
            }

            Canvas {
              id: visualizer
              anchors.fill: parent
              antialiasing: true

              onPaint: {
                const ctx = getContext("2d");
                const w = width;
                const h = height;
                const values = root.levels;

                ctx.clearRect(0, 0, w, h);

                if (!values || values.length === 0 || w <= 0 || h <= 0) {
                  return;
                }

                const cx = w * 0.5;
                const cy = h * 0.52;
                const size = Math.min(w, h);
                const baseRadius = size * 0.18;
                const amplitude = size * 0.115;
                const idlePulse = 1 + Math.sin(root.frame * 0.045) * 0.012;
                const rotation = root.frame * 0.006;
                const points = [];

                for (let i = 0; i < values.length; i++) {
                  const previous = values[(i - 1 + values.length) % values.length];
                  const current = values[i];
                  const next = values[(i + 1) % values.length];
                  const smoothed = previous * 0.22 + current * 0.56 + next * 0.22;
                  const value = Math.pow(smoothed, 0.54);
                  const angle = -Math.PI * 0.5 + rotation + (i / values.length) * Math.PI * 2;
                  const radius = baseRadius * idlePulse + value * amplitude;

                  points.push({
                    x: cx + Math.cos(angle) * radius,
                    y: cy + Math.sin(angle) * radius
                  });
                }

                function traceClosedShape(offset) {
                  const first = points[0];
                  const second = points[1];
                  ctx.beginPath();
                  ctx.moveTo((first.x + second.x) * 0.5, (first.y + second.y) * 0.5 + offset);

                  for (let i = 1; i <= points.length; i++) {
                    const point = points[i % points.length];
                    const nextPoint = points[(i + 1) % points.length];
                    const midpointX = (point.x + nextPoint.x) * 0.5;
                    const midpointY = (point.y + nextPoint.y) * 0.5 + offset;
                    ctx.quadraticCurveTo(point.x, point.y + offset, midpointX, midpointY);
                  }

                  ctx.closePath();
                }

                const aura = ctx.createRadialGradient(cx, cy, baseRadius * 0.2, cx, cy, baseRadius + amplitude * 1.6);
                aura.addColorStop(0.00, "rgba(255, 255, 255, 0.025)");
                aura.addColorStop(0.56, "rgba(255, 255, 255, 0.018)");
                aura.addColorStop(1.00, "rgba(255, 255, 255, 0)");
                ctx.fillStyle = aura;
                ctx.fillRect(0, 0, w, h);

                ctx.strokeStyle = "rgba(255, 255, 255, 0.12)";
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.arc(cx, cy, baseRadius * idlePulse, 0, Math.PI * 2);
                ctx.stroke();

                traceClosedShape(0);
                ctx.strokeStyle = "rgba(255, 255, 255, 0.16)";
                ctx.lineWidth = 9;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                ctx.stroke();

                traceClosedShape(0);
                ctx.strokeStyle = "rgba(255, 255, 255, 0.82)";
                ctx.lineWidth = 2.2;
                ctx.stroke();

                traceClosedShape(size * 0.0025);
                ctx.strokeStyle = "rgba(255, 255, 255, 0.20)";
                ctx.lineWidth = 1;
                ctx.stroke();
              }

              Connections {
                target: root
                function onFrameChanged() {
                  visualizer.requestPaint()
                }
              }
            }
          }
        }
      }
    '';
  };
}
