{ inputs, config, pkgs, ... }:
let
  cfg = config.jaren.home;

  mkElectronWaylandPackage =
    { name, package, executable }:
    pkgs.symlinkJoin {
      inherit name;
      paths = [ package ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram "$out/bin/${executable}" \
          --set NIXOS_OZONE_WL 1 \
          --set ELECTRON_OZONE_PLATFORM_HINT wayland \
          --add-flags "--enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer" \
          --add-flags "--ozone-platform=wayland"
      '';
    };

  discordBasePackage =
    if pkgs ? master && pkgs.master ? discord then pkgs.master.discord
    else if pkgs ? master && builtins.hasAttr "discord-canary" pkgs.master then pkgs.master."discord-canary"
    else pkgs.discord-canary;
  discordExecutable = if pkgs ? master && pkgs.master ? discord then "Discord" else "DiscordCanary";

  discordWayland = mkElectronWaylandPackage {
    name = "discord-wayland";
    package = discordBasePackage;
    executable = discordExecutable;
  };
  vesktopWayland = mkElectronWaylandPackage {
    name = "vesktop-wayland";
    package = pkgs.vesktop;
    executable = "vesktop";
  };
  slackWayland = mkElectronWaylandPackage {
    name = "slack-wayland";
    package = pkgs.slack;
    executable = "slack";
  };
  masterCodex = pkgs.master.codex;
in
{
  home.packages = [
    pkgs.git
    pkgs.neovim
    pkgs.firefox
    pkgs.wofi
    pkgs.ripgrep
    pkgs.ghostty
    pkgs.nixd
    pkgs.hyprpaper
    pkgs.hyprcursor
    pkgs.cmake
    pkgs.just
    vesktopWayland
    slackWayland
    pkgs.hyprshot
    pkgs.grim
    pkgs.kdePackages.dolphin
    pkgs.gh
    pkgs.awscli2
    pkgs.playerctl
    pkgs.wayland
    pkgs.wayland-protocols
    pkgs.libxkbcommon
    pkgs.helix
    pkgs.vulkan-loader
    pkgs.wgsl-analyzer
    pkgs.htop
    pkgs.acpi
    pkgs.mangohud
    pkgs.prismlauncher
    pkgs.spotify
    pkgs.wl-clipboard-rs
    pkgs.jujutsu
    pkgs.opencode
    pkgs.claude-code
    pkgs.herdr
    pkgs.unzip
    pkgs.gcc
    pkgs.clang-tools
    pkgs.ocaml
    pkgs.dune_3
    pkgs.opam
    pkgs.ocamlPackages.findlib
    pkgs.ocamlPackages.ocaml-lsp
    pkgs.ocamlPackages.ocamlformat
    pkgs.ocamlPackages.utop
    pkgs.md-tui
    pkgs.uv
    pkgs.python3
    pkgs.libreoffice
    pkgs.fastfetch
    pkgs.zathura
    pkgs.basedpyright
    pkgs.obs-studio
    masterCodex
    pkgs.codex-acp
    pkgs.piper
    pkgs.pavucontrol
    pkgs.v4l-utils
    pkgs.guvcview
    pkgs.master.ani-cli
    discordWayland
    pkgs.eza
    pkgs.yazi
    pkgs.ruff
    pkgs.blender
    pkgs.krita
    pkgs.code-cursor
    pkgs.cargo
    pkgs.obsidian
    (inputs.oh-my-pi.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      withWaylandScreencast = true;
    })
    pkgs.t4-code
    pkgs.tern
    inputs.rose-pine-hyprcursor.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.canvas-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
  ] ++ cfg.extraPackages;
}
