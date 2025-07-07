{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zen-browser;
in
{
  options.programs.zen-browser = {
    enable = mkEnableOption "Zen Browser";

    package = mkOption {
      type = types.package;
      default = config.nixpkgs.hostPlatform.system;
      description = "The Zen Browser package to use.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
