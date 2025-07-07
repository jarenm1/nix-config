{ config, lib, pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      # Example configuration
      monitor = ",preferred,auto,auto";
      
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };
      
      decoration = {
        rounding = 10;
        blur = true;
        blur_size = 3;
        blur_passes = 1;
        blur_new_optimizations = true;
      };
      
      animations = {
        enabled = true;
      };
      
      # Add more Hyprland settings as needed
    };
  };
}
