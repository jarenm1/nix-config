# NixOS Niri Configuration
# System-level niri setup
{ config, pkgs, ... }:
{
  # Enable niri display manager session
  programs.niri = {
    enable = true;
    package = pkgs.niri-stable;
  };
  
  # Note: Hyprland is kept enabled separately
  # programs.hyprland.enable = true;  # managed in hyprland.nix
}
