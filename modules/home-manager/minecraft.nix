{ config, lib, pkgs, ... }:

let
  cfg = config.programs.mcsr;
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
  packages =
    lib.optionals cfg.prism.enable [ cfg.prism.package ]
    ++ lib.optionals cfg.java.enable [ cfg.java.package ]
    ++ lib.optionals (ninjabrainLauncher != null) [ ninjabrainLauncher ]
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

      package = lib.mkPackageOption pkgs "prismlauncher" { };
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
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ inputs.toolscreen.packages.${pkgs.system}.default ]";
      description = "Additional Minecraft-related packages to install alongside the core MCSR tools.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = packages;
      }
      (lib.mkIf (ninjabrainLauncher != null) {
        xdg.desktopEntries.ninjabrain-bot = {
          name = "Ninjabrain Bot";
          exec = "ninjabrain-bot";
          terminal = false;
          categories = [ "Game" "Utility" ];
        };
      })
      (lib.mkIf (cfg.waywall.enable && cfg.waywall.configText != null) {
        xdg.configFile."waywall/init.lua".text = cfg.waywall.configText;
      })
    ]
  );
}
