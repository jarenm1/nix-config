{ pkgs, inputs, ... }:
{
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  home.username = "jaren";
  home.homeDirectory = "/home/jaren";

  home.stateVersion = "24.05";

  home.packages = [
    pkgs.git
    pkgs.neovim
    pkgs.firefox
    pkgs.zed-editor
    pkgs.wofi
    pkgs.ripgrep
    pkgs.ghostty
    pkgs.nixd
    pkgs.hyprpaper
    pkgs.hyprcursor
    pkgs.qt6.full
    pkgs.cmake
    pkgs.just
    pkgs.vesktop
    pkgs.hyprshot
    pkgs.grim
    pkgs.kdePackages.dolphin
    pkgs.gh
    inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
  ];

  programs.vscode.enable = true;
  programs.zed-editor.enable = true;
  programs.ghostty.enable = true;
  programs.zen-browser.enable = true;

  programs.ghostty.settings = {
    theme = "gruber-darker";
    font-size = 15;
    background-opacity = 0.8;
  };
}
