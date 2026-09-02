{ inputs, lib, ... }:
let


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
    ./packages.nix
    ./shell.nix
    ./editors.nix
    ./browsers.nix
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


    programs.quickshellAudioVisualizer.enable = true;

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


    programs.ghostty.settings = {
      theme = "Gruber Darker";
      window-decoration = "none";
      window-padding-x = 12;
      window-padding-y = 10;
      font-size = 16;
      adjust-cell-height = "30%";
      background-opacity = 0.9;
      font-family = "Comic Mono";
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

  };
}
