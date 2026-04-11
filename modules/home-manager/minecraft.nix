{ config, lib, pkgs, ... }:

let
  cfg = config.programs.mcsr;
  prismRuntimeLibraryPath = lib.makeLibraryPath cfg.prism.extraRuntimeLibraries;
  prismMinecraftWrapper = pkgs.writeShellApplication {
    name = "prismlauncher-minecraft-wrapper";
    text = ''
      export LD_LIBRARY_PATH="${prismRuntimeLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec "$@"
    '';
  };
  prismPackage =
    if cfg.prism.enable && (cfg.prism.forceX11 || cfg.prism.extraRuntimeLibraries != [ ]) then
      pkgs.symlinkJoin {
        name = "prismlauncher-x11";
        paths = [ cfg.prism.package ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/prismlauncher ${lib.escapeShellArgs (
            lib.optionals cfg.prism.forceX11 [
              "--set-default"
              "GLFW_PLATFORM"
              "x11"
            ]
            ++ lib.optionals (cfg.prism.extraRuntimeLibraries != [ ]) [
              "--prefix"
              "LD_LIBRARY_PATH"
              ":"
              prismRuntimeLibraryPath
            ]
          )}
        '';
      }
    else
      cfg.prism.package;
  defaultNinjabrainJar = pkgs.fetchurl {
    url = "https://github.com/Ninjabrain1/Ninjabrain-Bot/releases/download/1.5.1/Ninjabrain-Bot-1.5.1.jar";
    hash = "sha256-Rxu9A2EiTr69fLBUImRv+RLC2LmosawIDyDPIaRcrdw=";
  };
  ninjabrainLauncher =
    if cfg.ninjabrain.enable then
      pkgs.writeShellApplication {
        name = "ninjabrain-bot";
        runtimeInputs = [ cfg.ninjabrain.javaPackage ];
        text = ''
          exec ${lib.getExe cfg.ninjabrain.javaPackage} ${lib.escapeShellArgs cfg.ninjabrain.jvmArgs} -jar "${cfg.ninjabrain.jarPackage}" "$@"
        '';
      }
    else
      null;
  ninjabrainAngleLauncher =
    if cfg.ninjabrain.enable then
      pkgs.writeShellApplication {
        name = "ninjabrain-angle";
        runtimeInputs = [ pkgs.ydotool ];
        text = ''
          case "''${1:-}" in
            increment|inc|plus|up)
              keycode=191
              ;;
            decrement|dec|minus|down)
              keycode=190
              ;;
            *)
              echo "usage: ninjabrain-angle {increment|decrement}" >&2
              exit 2
              ;;
          esac

          exec ydotool key "$keycode:1" "$keycode:0"
        '';
      }
    else
      null;
  packages =
    lib.optionals cfg.prism.enable [ prismPackage ]
    ++ lib.optionals cfg.java.enable [ cfg.java.package ]
    ++ lib.optionals (ninjabrainLauncher != null) [ ninjabrainLauncher ]
    ++ lib.optionals (ninjabrainAngleLauncher != null) [ ninjabrainAngleLauncher ]
    ++ lib.optionals cfg.obs.enable [ cfg.obs.package ]
    ++ lib.optionals cfg.waywall.enable [ cfg.waywall.package cfg.waywall.xkbcompPackage ]
    ++ cfg.extraPackages;
in
{
  options.programs.mcsr = {
    enable = lib.mkEnableOption "Minecraft speedrunning environment";

    prism = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install Prism Launcher.";
      };

      forceX11 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Wrap Prism Launcher to force Minecraft's GLFW backend to X11, which avoids Wayland window-position crashes in some modpacks.";
      };

      package = lib.mkPackageOption pkgs "prismlauncher" { };

      extraRuntimeLibraries = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          alsa-lib
          atk
          at-spi2-atk
          at-spi2-core
          cairo
          cups
          dbus
          expat
          glib
          gtk3
          libdrm
          libgbm
          libxkbcommon
          mesa
          nspr
          nss
          pango
          stdenv.cc.cc.lib
          libx11
          libxcomposite
          libxdamage
          libxext
          libxfixes
          libxrandr
          libxrender
          libxtst
          libxcb
          libxshmfence
        ];
        description = "Runtime libraries exposed to Prism Launcher via LD_LIBRARY_PATH so downloaded native Minecraft libraries like MCEF/CEF can resolve Chromium dependencies on NixOS.";
      };
    };

    java = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install a Java 8 runtime for older Minecraft speedrunning instances.";
      };

      package = lib.mkPackageOption pkgs "temurin-jre-bin-8" { };
    };

    obs = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install OBS Studio for capture and recording.";
      };

      package = lib.mkPackageOption pkgs "obs-studio" { };
    };

    ninjabrain = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install a launcher for Ninjabrain Bot.";
      };

      jarPackage = lib.mkOption {
        type = lib.types.package;
        default = defaultNinjabrainJar;
        example = lib.literalExpression ''
          pkgs.fetchurl {
            url = "https://github.com/Ninjabrain1/Ninjabrain-Bot/releases/download/1.5.1/Ninjabrain-Bot-1.5.1.jar";
            hash = "sha256-Rxu9A2EiTr69fLBUImRv+RLC2LmosawIDyDPIaRcrdw=";
          }
        '';
        description = "The Ninjabrain Bot jar to launch.";
      };

      javaPackage = lib.mkPackageOption pkgs "temurin-jre-bin-17" { };

      jvmArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "-Dswing.defaultlaf=javax.swing.plaf.metal.MetalLookAndFeel" ];
        description = "Extra JVM arguments passed to Ninjabrain Bot.";
      };
    };

    waywall = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Install waywall and companion tools for Wayland MCSR workflows.";
      };

      package = lib.mkPackageOption pkgs "waywall" { };

      xkbcompPackage = lib.mkPackageOption pkgs "xkbcomp" { };

      configText = lib.mkOption {
        type = lib.types.nullOr lib.types.lines;
        default = null;
        example = lib.literalExpression "''\n  return {}\n''";
        description = "Optional contents for ~/.config/waywall/init.lua.";
      };

      configSource = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "./config/waywall";
        description = "Optional source directory for ~/.config/waywall.";
      };

      xkbConfigSource = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "./config/xkb";
        description = "Optional source directory for ~/.config/xkb used by waywall keymaps.";
      };
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ inputs.toolscreen.packages.${pkgs.stdenv.hostPlatform.system}.default ]";
      description = "Additional Minecraft-related packages to install alongside the core MCSR tools.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = !(cfg.waywall.configText != null && cfg.waywall.configSource != null);
            message = "programs.mcsr.waywall.configText and configSource are mutually exclusive.";
          }
        ];

        home.packages = packages;
      }
      (lib.mkIf cfg.prism.enable {
        home.activation.configurePrismLauncherWrapper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          config_file="$HOME/.local/share/PrismLauncher/prismlauncher.cfg"
          mkdir -p "$(dirname "$config_file")"

          if [ ! -f "$config_file" ]; then
            cat > "$config_file" <<'EOF'
[General]
WrapperCommand=
EOF
          fi

          ${lib.getExe pkgs.python3} - <<'PY'
from pathlib import Path

config_file = Path.home() / ".local" / "share" / "PrismLauncher" / "prismlauncher.cfg"
wrapper = "${lib.getExe prismMinecraftWrapper}"
text = config_file.read_text()
lines = text.splitlines()

for index, line in enumerate(lines):
    if line.startswith("WrapperCommand="):
        value = line.removeprefix("WrapperCommand=")
        if value == wrapper:
            break
        lines[index] = f"WrapperCommand={wrapper}"
        break
else:
    for index, line in enumerate(lines):
        if line == "[General]":
            insert_at = index + 1
            while insert_at < len(lines) and not lines[insert_at].startswith("["):
                insert_at += 1
            lines.insert(insert_at, f"WrapperCommand={wrapper}")
            break
    else:
        if lines and lines[-1] != "":
            lines.append("")
        lines.extend(["[General]", f"WrapperCommand={wrapper}"])

config_file.write_text("\n".join(lines) + "\n")
PY
        '';
      })
      (lib.mkIf (ninjabrainLauncher != null) {
        xdg.desktopEntries.ninjabrain-bot = {
          name = "Ninjabrain Bot";
          exec = "ninjabrain-bot";
          terminal = false;
          categories = [ "Game" "Utility" ];
        };

        home.activation.configureNinjabrainPrefs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          prefs_dir="$HOME/.java/.userPrefs/ninjabrainbot"
          prefs_file="$prefs_dir/prefs.xml"

          mkdir -p "$prefs_dir"

          if [ ! -f "$prefs_file" ]; then
            cat > "$prefs_file" <<'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE map SYSTEM "http://java.sun.com/dtd/preferences.dtd">
<map MAP_XML_VERSION="1.0">
</map>
EOF
          fi

          ${lib.getExe pkgs.python3} - <<'PY'
from pathlib import Path
import re

prefs_file = Path.home() / ".java" / ".userPrefs" / "ninjabrainbot" / "prefs.xml"
text = prefs_file.read_text()

patterns = [
    r'\n\s*<entry key="enable_http_server" value="[^"]*"/>',
    r'\n\s*<entry key="hotkey_increment_modifier" value="[^"]*"/>',
    r'\n\s*<entry key="hotkey_increment_code" value="[^"]*"/>',
    r'\n\s*<entry key="hotkey_decrement_modifier" value="[^"]*"/>',
    r'\n\s*<entry key="hotkey_decrement_code" value="[^"]*"/>',
]

for pattern in patterns:
    text = re.sub(pattern, "", text)

entries = """
  <entry key="hotkey_increment_modifier" value="0"/>
  <entry key="hotkey_increment_code" value="65640"/>
  <entry key="hotkey_decrement_modifier" value="0"/>
  <entry key="hotkey_decrement_code" value="65639"/>
""".rstrip()

if "</map>" not in text:
    raise SystemExit("ninjabrain prefs.xml missing </map>")

text = text.replace("</map>", entries + "\n</map>")
prefs_file.write_text(text)
PY
        '';
      })
      (lib.mkIf (cfg.waywall.enable && cfg.waywall.configText != null) {
        xdg.configFile."waywall/init.lua".text = cfg.waywall.configText;
      })
      (lib.mkIf (cfg.waywall.enable && cfg.waywall.configSource != null) {
        xdg.configFile."waywall".source = cfg.waywall.configSource;
      })
      (lib.mkIf (cfg.waywall.enable && cfg.waywall.xkbConfigSource != null) {
        xdg.configFile."xkb".source = cfg.waywall.xkbConfigSource;
      })
    ]
  );
}
