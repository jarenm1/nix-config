{ config, pkgs, ... }:
{
  imports = [
    ../../../modules/home-manager/ghostty.nix
    ../../../modules/home-manager/zen-browser.nix
  ];
  
  home.username = "jaren";
  home.homeDirectory = "/home/jaren";
  
  home.stateVersion = "25.05";
  
  home.packages = with pkgs; [
    git
    neovim
    firefox
    ghostty
    zed-editor
    vscode
  ];
}