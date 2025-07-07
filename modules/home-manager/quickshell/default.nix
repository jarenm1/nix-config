{ config, lib, pkgs, ... }:

let
  cfg = config.services.quickshell;
in
{
  imports = [
    ./options.nix  # Import the options definitions
  ];

  config = lib.mkIf cfg.enable {
    # Install QuickShell and dependencies
    home.packages = with pkgs; [
      cfg.package
      
      # Qt dependencies for better QuickShell experience
      qt6.qtsvg
      qt6.qtimageformats
      qt6.qtmultimedia
      qt6.qt5compat
    ];

    # Generate QML configuration files from the configs directory
    home.file = builtins.listToAttrs (
      map (file: {
        name = ".config/quickshell/${file}";
        value = { source = ./configs/${file}; };
      }) (builtins.attrNames (builtins.readDir ./configs))
    );

    # Autostart configuration for Hyprland
    wayland.windowManager.hyprland.settings = lib.mkIf (cfg.autostart && config.wayland.windowManager.hyprland.enable) {
      exec-once = map (widget: "quickshell -c $HOME/.config/quickshell/${widget}.qml") cfg.startupWidgets;
    };
  };
}
