{ config, lib, pkgs, ... }: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  
  environment.systemPackages = with pkgs; [
    rofi-wayland
    hyprpaper
    wl-clipboard
  ];
  
  xdg.portal.enable = true;
  hardware.opengl.enable = true;
  
}