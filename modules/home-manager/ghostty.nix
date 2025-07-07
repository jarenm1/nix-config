{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.ghostty;
  settingsFormat = pkgs.formats.toml { };
in
{
  options.programs.ghostty = {
    enable = mkEnableOption "ghostty terminal emulator";

    package = mkOption {
      type = types.package;
      default = pkgs.ghostty;
      description = "The ghostty package to use.";
    };

    settings = mkOption {
      type = types.submoduleWith { module = import ./ghostty-settings.nix; };
      default = { };
      description = "Configuration for ghostty";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."ghostty/config.toml" = {
      source = settingsFormat.generate "ghostty-settings" cfg.settings;
    };
  };
}