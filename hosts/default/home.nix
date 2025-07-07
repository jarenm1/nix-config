{ config, pkgs, ... }:
{
  imports = [
    ../../../modules/home-manager/quickshell/default.nix
    ../../../modules/home-manager/ghostty.nix
    ../../../modules/home-manager/hyprland.nix
    ../../../modules/home-manager/zed-editor.nix
    ../../../modules/home-manager/zen-browser.nix
  ];
  
  home.username = "jaren";
  home.homeDirectory = "/home/jaren";
  
  home.stateVersion = "25.05";
  
  home.packages = with pkgs; [
    git
    neovim
  ];
  
  services.quickshell = {
    enable = true;
    startupWidgets = [ "statusbar" ];
  };

  programs.ghostty.enable = true;
  programs.zed-editor.enable = true;
  programs.zen-browser.enable = true;
}