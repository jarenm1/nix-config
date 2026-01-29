{ pkgs, inputs, ... }:
{
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  home.username = "jaren";
  home.homeDirectory = "/home/jaren";

  home.stateVersion = "25.05";

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
    pkgs.cmake
    pkgs.just
    pkgs.vesktop
    pkgs.hyprshot
    pkgs.grim
    pkgs.kdePackages.dolphin
    pkgs.gh
    pkgs.playerctl
    pkgs.wayland
    pkgs.wayland-protocols
    pkgs.libxkbcommon
    pkgs.helix
    pkgs.vulkan-loader
    pkgs.wgsl-analyzer
    pkgs.niri
    pkgs.code-cursor
    pkgs.cursor-cli
    pkgs.tmux
    pkgs.htop
    pkgs.acpi
    pkgs.mangohud
    pkgs.spotify
    pkgs.wl-clipboard-rs
    pkgs.jujutsu
    pkgs.opencode
    pkgs.claude-code
    pkgs.unzip
    pkgs.gcc
    pkgs.clang-tools
    pkgs.md-tui
    pkgs.direnv
    pkgs.nix-direnv
    pkgs.libreoffice
    inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
    inputs.canvas-cli.packages.${pkgs.system}.default
  ];

  programs.vscode.enable = true;
  programs.zed-editor.enable = true;
  programs.ghostty.enable = true;
  programs.zen-browser.enable = true;

  programs.ghostty.settings = {
    theme = "Gruber Darker";
    font-size = 15;
    background-opacity = 0.8;
  };


  dconf.enable = true;

  dconf.settings = {
    "org.freedesktop.appearance" = {
      "color-scheme" = "prefer-dark";
    };
  };
  programs.helix.enable = true;
  programs.helix.settings = {
    theme = "gruber-darker";
    editor = {
      line-number = "relative";
    };
    editor.cursor-shape = {
      insert = "bar";
    };
  };
}
