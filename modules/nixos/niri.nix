# NixOS Niri Configuration
# System-level niri setup
{ config, pkgs, ... }:
{
  # Enable niri display manager session
  programs.niri = {
    enable = true;
    # v25.08 is still hitting PipeWire screencast negotiation failures on NVIDIA.
    # Use the newer already-locked niri build from the flake instead.
    package = pkgs.niri-unstable;
  };
  
  # Note: Hyprland is kept enabled separately
  # programs.hyprland.enable = true;  # managed in hyprland.nix
}
