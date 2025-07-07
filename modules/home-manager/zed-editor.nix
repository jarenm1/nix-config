{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.zed-editor;
in
{
  options.programs.zed-editor = {
    enable = mkEnableOption "Zed editor";

    package = mkOption {
      type = types.package;
      default = pkgs.zed-editor;
      description = "The Zed package to use.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
