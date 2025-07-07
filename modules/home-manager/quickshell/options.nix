{ config, lib, pkgs, ... }:

with lib;

{
  options.services.quickshell = {
    enable = mkEnableOption "QuickShell widgets for desktop";
    
    package = mkOption {
      type = types.package;
      default = pkgs.quickshell;
      description = "The QuickShell package to use";
    };
    
    autostart = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to autostart QuickShell widgets";
    };
    
    startupWidgets = mkOption {
      type = types.listOf types.str;
      default = [ "statusbar" ];
      description = "List of QuickShell widgets to autostart";
    };
  };
}
