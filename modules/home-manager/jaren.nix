{ inputs, lib, pkgs, config, ... }:
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

  hasMasterDiscord = pkgs ? master && pkgs.master ? discord;
  hasMasterDiscordCanary = pkgs ? master && builtins.hasAttr "discord-canary" pkgs.master;
  discordBasePackage =
    if hasMasterDiscord then
      pkgs.master.discord
    else if hasMasterDiscordCanary then
      pkgs.master."discord-canary"
    else
      pkgs.discord-canary;
  discordExecutable =
    if hasMasterDiscord then
      "Discord"
    else
      "DiscordCanary";
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
  masterCodex = pkgs.master.codex;

  theme = {
    background = "#181818";
    backgroundAlt = "#1f1f1f";
    surface = "#282828";
    border = "#54494e";
    foreground = "#e4e4e4";
    foregroundBright = "#f5f5f5";
    accent = "#92a7cb";
    accentStrong = "#ffdb00";
    success = "#42dc00";
    danger = "#ff3851";
    backgroundRgb = "24,24,24";
    backgroundAltRgb = "31,31,31";
    surfaceRgb = "40,40,40";
    borderRgb = "84,73,78";
    foregroundRgb = "228,228,228";
    foregroundBrightRgb = "245,245,245";
    accentRgb = "146,167,203";
    accentStrongRgb = "255,219,0";
    successRgb = "66,220,0";
    dangerRgb = "255,56,81";
  };
in
{
  imports = [
    inputs.zen-browser.homeModules.beta
    ./md-preview.nix
    ./niri.nix
    ./quickshell.nix
  ];

  options.jaren.home.extraPackages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = "Extra packages to install only for this host.";
  };

  config = {
    home.username = "jaren";
    home.homeDirectory = "/home/jaren";
    home.stateVersion = "25.05";
    home.sessionPath = [ "$HOME/.local/bin" ];
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      GTK_USE_PORTAL = "1";
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";
    };

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
      pkgs.htop
      pkgs.acpi
      pkgs.mangohud
      pkgs.prismlauncher
      pkgs.spotify
      pkgs.wl-clipboard-rs
      pkgs.jujutsu
      pkgs.opencode
      pkgs.claude-code
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
      pkgs.oh-my-pi
      inputs.rose-pine-hyprcursor.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.canvas-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
    ] ++ cfg.extraPackages;

    programs.quickshellAudioVisualizer.enable = true;
    programs.zed-editor = {
      enable = true;
      package = pkgs.zed-editor;
      userSettings = {
        agent_servers = {
          codex-acp = {
            type = "registry";
          };
          "Cursor Agent" = {
            type = "custom";
            command = lib.getExe pkgs.cursor-cli;
            args = [ "acp" ];
          };
          oh-my-pi = {
            type = "custom";
            command = lib.getExe pkgs.oh-my-pi;
            args = [ "acp" ];
          };
        };
      };
    };

    programs.ghostty.enable = true;
    programs.wofi = {
      enable = true;
      settings = {
        allow_images = true;
        allow_markup = true;
        gtk_dark = true;
        hide_scroll = true;
        insensitive = true;
        lines = 8;
        matching = "fuzzy";
        no_actions = true;
        prompt = "run";
        show = "drun";
        term = "ghostty";
        width = "38%";
      };
      style = ''
        * {
          font-family: "Inter";
          font-size: 14px;
        }

        window {
          background-color: rgba(${theme.backgroundRgb}, 0.94);
          color: ${theme.foreground};
        }

        #outer-box {
          margin: 12px;
          padding: 14px;
          border: 1px solid ${theme.border};
          border-radius: 14px;
          background-color: ${theme.background};
        }

        #input {
          margin: 0 0 12px 0;
          padding: 10px 12px;
          border: 1px solid ${theme.border};
          border-radius: 10px;
          background-color: ${theme.backgroundAlt};
          color: ${theme.foregroundBright};
        }

        #scroll {
          margin: 0;
        }

        #entry {
          margin: 4px 0;
          padding: 10px 12px;
          border: 1px solid transparent;
          border-radius: 10px;
          background-color: transparent;
        }

        #entry:selected {
          background-color: rgba(${theme.accentRgb}, 0.16);
          border-color: ${theme.accent};
        }

        #text {
          color: ${theme.foreground};
        }

        #text:selected {
          color: ${theme.foregroundBright};
        }

        #img {
          margin-right: 10px;
        }
      '';
    };

    programs.zen-browser.enable = true;
    programs.nushell = {
      enable = true;
      package = null;
      settings = {
        show_banner = false;
      };
    };
    programs.direnv = {
      enable = true;
      enableNushellIntegration = true;
      nix-direnv.enable = true;
    };
    programs.zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };
    programs.atuin = {
      enable = true;
      enableNushellIntegration = true;
    };
    programs.starship = {
      enable = true;
      enableNushellIntegration = true;
      settings = {
        add_newline = false;
        command_timeout = 1000;
        format = "$directory$git_branch$nix_shell$character";
        right_format = "$battery$time";
        line_break.disabled = true;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[➜](bold red)";
        };
        directory = {
          truncation_length = 3;
          truncate_to_repo = false;
        };
        battery = {
          disabled = false;
          format = "[$symbol$percentage]($style) ";
          display = [
            {
              threshold = 100;
              style = "dimmed white";
            }
          ];
        };
        git_branch.symbol = " ";
        nix_shell.symbol = " ";
        time = {
          disabled = false;
          format = "[$time]($style)";
          time_format = "%m/%d %R";
          style = "dimmed white";
        };
      };
    };

    programs.ghostty.settings = {
      theme = "Gruber Darker";
      window-decoration = "none";
      window-padding-x = 12;
      window-padding-y = 10;
      font-size = 15;
      background-opacity = 0.9;
    };

    programs.tmux = {
      enable = true;
      baseIndex = 1;
      keyMode = "vi";
      mouse = true;
      terminal = "tmux-256color";
    };

    qt = {
      enable = true;
      platformTheme.name = "kde";
      style.name = "breeze";
    };

    home.file.".config/kdeglobals".text = ''
      [General]
      ColorScheme=GruberDarker
      Name=GruberDarker

      [KDE]
      contrast=4
      widgetStyle=Breeze

      [Colors:Button]
      BackgroundAlternate=${theme.backgroundAltRgb}
      BackgroundNormal=${theme.backgroundAltRgb}
      DecorationFocus=${theme.accentRgb}
      DecorationHover=${theme.accentStrongRgb}
      ForegroundActive=${theme.foregroundBrightRgb}
      ForegroundInactive=${theme.borderRgb}
      ForegroundLink=${theme.accentRgb}
      ForegroundNegative=${theme.dangerRgb}
      ForegroundNeutral=${theme.accentStrongRgb}
      ForegroundNormal=${theme.foregroundRgb}
      ForegroundPositive=${theme.successRgb}
      ForegroundVisited=175,175,218

      [Colors:Header]
      BackgroundAlternate=${theme.backgroundAltRgb}
      BackgroundNormal=${theme.backgroundAltRgb}
      DecorationFocus=${theme.accentRgb}
      DecorationHover=${theme.accentStrongRgb}
      ForegroundActive=${theme.foregroundBrightRgb}
      ForegroundInactive=${theme.borderRgb}
      ForegroundLink=${theme.accentRgb}
      ForegroundNegative=${theme.dangerRgb}
      ForegroundNeutral=${theme.accentStrongRgb}
      ForegroundNormal=${theme.foregroundRgb}
      ForegroundPositive=${theme.successRgb}
      ForegroundVisited=175,175,218

      [Colors:Selection]
      BackgroundAlternate=${theme.borderRgb}
      BackgroundNormal=${theme.accentRgb}
      DecorationFocus=${theme.accentRgb}
      DecorationHover=${theme.accentStrongRgb}
      ForegroundActive=${theme.foregroundBrightRgb}
      ForegroundInactive=${theme.foregroundBrightRgb}
      ForegroundLink=${theme.foregroundBrightRgb}
      ForegroundNegative=${theme.foregroundBrightRgb}
      ForegroundNeutral=${theme.foregroundBrightRgb}
      ForegroundNormal=${theme.foregroundBrightRgb}
      ForegroundPositive=${theme.foregroundBrightRgb}
      ForegroundVisited=${theme.foregroundBrightRgb}

      [Colors:Tooltip]
      BackgroundAlternate=${theme.backgroundAltRgb}
      BackgroundNormal=${theme.backgroundAltRgb}
      DecorationFocus=${theme.accentRgb}
      DecorationHover=${theme.accentStrongRgb}
      ForegroundActive=${theme.foregroundBrightRgb}
      ForegroundInactive=${theme.borderRgb}
      ForegroundLink=${theme.accentRgb}
      ForegroundNegative=${theme.dangerRgb}
      ForegroundNeutral=${theme.accentStrongRgb}
      ForegroundNormal=${theme.foregroundRgb}
      ForegroundPositive=${theme.successRgb}
      ForegroundVisited=175,175,218

      [Colors:View]
      BackgroundAlternate=${theme.backgroundAltRgb}
      BackgroundNormal=${theme.backgroundRgb}
      DecorationFocus=${theme.accentRgb}
      DecorationHover=${theme.accentStrongRgb}
      ForegroundActive=${theme.foregroundBrightRgb}
      ForegroundInactive=${theme.borderRgb}
      ForegroundLink=${theme.accentRgb}
      ForegroundNegative=${theme.dangerRgb}
      ForegroundNeutral=${theme.accentStrongRgb}
      ForegroundNormal=${theme.foregroundRgb}
      ForegroundPositive=${theme.successRgb}
      ForegroundVisited=175,175,218

      [Colors:Window]
      BackgroundAlternate=${theme.backgroundAltRgb}
      BackgroundNormal=${theme.backgroundRgb}
      DecorationFocus=${theme.accentRgb}
      DecorationHover=${theme.accentStrongRgb}
      ForegroundActive=${theme.foregroundBrightRgb}
      ForegroundInactive=${theme.borderRgb}
      ForegroundLink=${theme.accentRgb}
      ForegroundNegative=${theme.dangerRgb}
      ForegroundNeutral=${theme.accentStrongRgb}
      ForegroundNormal=${theme.foregroundRgb}
      ForegroundPositive=${theme.successRgb}
      ForegroundVisited=175,175,218
    '';

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
  };
}
