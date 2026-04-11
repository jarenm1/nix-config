{ config, lib, pkgs, ... }:

let
  cfg = config.programs.game-streaming;

  moonlightPairHost = pkgs.writeShellApplication {
    name = "moonlight-pair-host";
    runtimeInputs = [ cfg.package pkgs.coreutils ];
    text = ''
      set -euo pipefail

      host="''${1:-${cfg.host}}"
      pin="$(shuf -i 1000-9999 -n 1)"

      echo "Pairing with $host using PIN: $pin"
      exec moonlight pair "$host" --pin "$pin"
    '';
  };

  moonlightStreamDesktop = pkgs.writeShellApplication {
    name = "moonlight-stream-desktop";
    runtimeInputs = [ cfg.package ];
    text = ''
      set -euo pipefail

      host="''${1:-${cfg.host}}"
      exec moonlight stream "$host" "${cfg.desktopAppName}"
    '';
  };

  moonlightStreamPrism = pkgs.writeShellApplication {
    name = "moonlight-stream-prism";
    runtimeInputs = [ cfg.package ];
    text = ''
      set -euo pipefail

      host="''${1:-${cfg.host}}"
      exec moonlight stream "$host" "${cfg.prismAppName}"
    '';
  };
in
{
  options.programs.game-streaming = {
    enable = lib.mkEnableOption "Moonlight client tools for Sunshine hosts";

    package = lib.mkPackageOption pkgs "moonlight-qt" { };

    host = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "Default Sunshine host name or address used by the helper commands.";
    };

    desktopAppName = lib.mkOption {
      type = lib.types.str;
      default = "Desktop";
      description = "Moonlight application name for full-desktop streaming.";
    };

    prismAppName = lib.mkOption {
      type = lib.types.str;
      default = "Prism Launcher";
      description = "Moonlight application name for the Prism Launcher stream target.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Extra client-side streaming packages to install alongside Moonlight.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      moonlightPairHost
      moonlightStreamDesktop
      moonlightStreamPrism
    ] ++ cfg.extraPackages;
  };
}
