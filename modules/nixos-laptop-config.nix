# Flake Parts Module for NixOS Configuration
{ inputs, config, lib, flake-parts-lib, ... }:

let
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs.legacyPackages.${system};
in
{
  flake.nixosConfigurations.laptop = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = [
      # Apply overlays system-wide
      ({ lib, pkgs, ... }: {
        nixpkgs.overlays = [
          inputs.niri.overlays.niri
          (final: prev: {
            pi-acp = final.callPackage ../pkgs/pi-acp.nix { };
            master = import inputs.nixpkgs-master {
              system = prev.stdenv.hostPlatform.system;
              config = prev.config;
              overlays = [
                inputs.niri.overlays.niri
                (masterFinal: _: {
                  pi-acp = masterFinal.callPackage ../pkgs/pi-acp.nix { };
                })
              ];
            };
          })
        ];
      })
      
      # Import Niri NixOS module
      inputs.niri.nixosModules.niri
      
      # Enable niri
      ./nixos/niri.nix
      # System configuration
      ({ config, pkgs, ... }:
      let
        prismStreamLauncher = pkgs.writeShellApplication {
          name = "prism-stream-launcher";
          runtimeInputs = [ pkgs.gamemode pkgs.prismlauncher ];
          text = ''
            export GLFW_PLATFORM=x11
            exec gamemoderun prismlauncher "$@"
          '';
        };

        prismStreamInstance = pkgs.writeShellApplication {
          name = "prism-stream-instance";
          runtimeInputs = [ pkgs.gamemode pkgs.prismlauncher ];
          text = ''
            set -euo pipefail

            if [ "$#" -lt 1 ]; then
              echo "usage: prism-stream-instance <instance-id> [extra prism args...]" >&2
              exit 2
            fi

            instance_id="$1"
            shift

            export GLFW_PLATFORM=x11
            exec gamemoderun prismlauncher -l "$instance_id" "$@"
          '';
        };

        sunshineSetCreds = pkgs.writeShellApplication {
          name = "sunshine-set-creds";
          runtimeInputs = [ pkgs.sunshine ];
          text = ''
            set -euo pipefail

            if [ "$#" -ne 2 ]; then
              echo "usage: sunshine-set-creds <username> <password>" >&2
              exit 2
            fi

            sunshine --creds "$1" "$2"
          '';
        };
      in {
        imports = [
          ../hosts/laptop/hardware.nix
        ];

        boot.loader.systemd-boot.enable = true;
        boot.loader.systemd-boot.configurationLimit = 5;
        boot.loader.efi.canTouchEfiVariables = true;

        networking.hostName = "laptop";
        networking.networkmanager.enable = true;

        time.timeZone = "America/Chicago";
        i18n.defaultLocale = "en_US.UTF-8";

        i18n.extraLocaleSettings = {
          LC_ADDRESS = "en_US.UTF-8";
          LC_IDENTIFICATION = "en_US.UTF-8";
          LC_MEASUREMENT = "en_US.UTF-8";
          LC_MONETARY = "en_US.UTF-8";
          LC_NAME = "en_US.UTF-8";
          LC_NUMERIC = "en_US.UTF-8";
          LC_PAPER = "en_US.UTF-8";
          LC_TELEPHONE = "en_US.UTF-8";
          LC_TIME = "en_US.UTF-8";
        };

        users.users.jaren = {
          isNormalUser = true;
          description = "jaren";
          extraGroups = [ "networkmanager" "wheel" "ydotool" "uinput" ];
          shell = pkgs.nushell;
        };

        programs.ydotool.enable = true;

        nixpkgs.config.allowUnfree = true;
        programs._1password.enable = true;
        programs._1password-gui = {
          enable = true;
          polkitPolicyOwners = [ "jaren" ];
        };
        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };
        hardware.uinput.enable = true;

        hardware.bluetooth.enable = true;
        security.rtkit.enable = true;

        services.pulseaudio.enable = false;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          audio.enable = true;
          jack.enable = true;
          pulse.enable = true;
        };

        environment.systemPackages = [
          pkgs.vim
          pkgs.kitty
          pkgs.nushell
          pkgs.mesa-demos
          pkgs.vulkan-tools
          prismStreamLauncher
          prismStreamInstance
          sunshineSetCreds
        ];

        networking.firewall.allowedTCPPorts = [ 8081 22 19000 19001 19002 19003 19004 19005 19006 ];
        networking.firewall.allowedUDPPorts = [ 8081 22 19000 19001 19002 19003 19004 19005 19006 ];
        networking.firewall.trustedInterfaces = [ "tailscale0" ];

        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        nix.settings.builders-use-substitutes = true;
        nix.settings.max-jobs = 8;
        nix.settings.trusted-users = lib.mkForce [ "root" "jaren" ];
        nix.settings.system-features = lib.mkForce [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        programs.steam.enable = true;
        programs.steam.gamescopeSession.enable = true;

        programs.gamemode.enable = true;
        services.ratbagd.enable = true;
        services.tailscale.enable = true;
        services.openssh.enable = true;
        services.gnome.gnome-keyring.enable = true;
        services.sunshine = {
          enable = true;
          openFirewall = true;
          capSysAdmin = true;
          applications = {
            apps = [
              {
                name = "Prism Launcher";
                cmd = lib.getExe prismStreamLauncher;
                "auto-detach" = true;
                "wait-all" = true;
                "exit-timeout" = 5;
              }
            ];
          };
        };

        xdg.portal = {
          enable = true;
          xdgOpenUsePortal = true;
          extraPortals = [
            pkgs.xdg-desktop-portal-gnome
            pkgs.xdg-desktop-portal-gtk
          ];
          config = {
            common = {
              default = [
                "gnome"
                "gtk"
              ];
              "org.freedesktop.impl.portal.ScreenCast" = "gnome";
              "org.freedesktop.impl.portal.Screenshot" = "gnome";
            };
            niri = {
              default = [
                "gnome"
                "gtk"
              ];
              "org.freedesktop.impl.portal.Access" = "gtk";
              "org.freedesktop.impl.portal.FileChooser" = "gtk";
              "org.freedesktop.impl.portal.Notification" = "gtk";
              "org.freedesktop.impl.portal.ScreenCast" = "gnome";
              "org.freedesktop.impl.portal.Screenshot" = "gnome";
              "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
            };
          };
        };

        system.stateVersion = "25.05";
      })

      # Hyprland module
      ({ pkgs, ... }: {
        programs.hyprland = {
          enable = true;
          xwayland.enable = true;
        };
      })

      # Fonts module
      ({ pkgs, ... }: {
        fonts.packages = with pkgs; [
          roboto
          roboto-serif
          inter
        ];
      })

      # Home manager
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.jaren = { pkgs, inputs, ... }:
        let
          hermesBootstrap = pkgs.writeShellApplication {
            name = "hermes-bootstrap";
            runtimeInputs = [ pkgs.git pkgs.uv pkgs.python311 ];
            text = ''
              set -euo pipefail

              repo_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/hermes-agent"
              config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/hermes"
              venv_dir="$repo_dir/.venv"

              mkdir -p "$(dirname "$repo_dir")"

              if [ ! -d "$repo_dir/.git" ]; then
                git clone --recurse-submodules https://github.com/NousResearch/hermes-agent.git "$repo_dir"
              else
                git -C "$repo_dir" submodule update --init --recursive
              fi

              cd "$repo_dir"

              if [ ! -x "$venv_dir/bin/python" ]; then
                uv venv "$venv_dir" --python ${pkgs.python311}/bin/python3.11
              fi

              export VIRTUAL_ENV="$venv_dir"
              export PATH="$venv_dir/bin:$PATH"

              if [ ! -x "$venv_dir/bin/hermes" ]; then
                uv pip install -e ".[all]"

                if [ -d "$repo_dir/mini-swe-agent" ]; then
                  uv pip install -e "$repo_dir/mini-swe-agent"
                fi

                if [ -d "$repo_dir/tinker-atropos" ]; then
                  uv pip install -e "$repo_dir/tinker-atropos"
                fi
              fi

              mkdir -p "$config_dir"

              if [ ! -f "$config_dir/config.yaml" ] && [ -f "$repo_dir/cli-config.yaml.example" ]; then
                cp "$repo_dir/cli-config.yaml.example" "$config_dir/config.yaml"
              fi

              if [ ! -f "$config_dir/.env" ]; then
                touch "$config_dir/.env"
              fi

              mkdir -p "$HOME/.local/bin"
              ln -sf "$venv_dir/bin/hermes" "$HOME/.local/bin/hermes"
            '';
          };

          hermes = pkgs.writeShellApplication {
            name = "hermes";
            runtimeInputs = [ hermesBootstrap ];
            text = ''
              set -euo pipefail

              hermes-bootstrap

              repo_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/hermes-agent"
              exec "$repo_dir/.venv/bin/hermes" "$@"
            '';
          };

          hermesSetup = pkgs.writeShellApplication {
            name = "hermes-setup";
            runtimeInputs = [ hermesBootstrap ];
            text = ''
              set -euo pipefail

              hermes-bootstrap

              repo_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/hermes-agent"
              exec "$repo_dir/.venv/bin/hermes" setup "$@"
            '';
          };

          hermesUpdate = pkgs.writeShellApplication {
            name = "hermes-update";
            runtimeInputs = [ hermesBootstrap pkgs.git pkgs.uv pkgs.python311 ];
            text = ''
              set -euo pipefail

              hermes-bootstrap

              repo_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/hermes-agent"

              if [ ! -d "$repo_dir/.git" ]; then
                echo "Hermes repo is missing. Run: hermes-bootstrap" >&2
                exit 1
              fi

              git -C "$repo_dir" pull --ff-only
              git -C "$repo_dir" submodule update --init --recursive

              export VIRTUAL_ENV="$repo_dir/.venv"
              export PATH="$VIRTUAL_ENV/bin:$PATH"

              uv pip install -e "''${repo_dir}[all]"

              if [ -d "$repo_dir/mini-swe-agent" ]; then
                uv pip install -e "$repo_dir/mini-swe-agent"
              fi

              if [ -d "$repo_dir/tinker-atropos" ]; then
                uv pip install -e "$repo_dir/tinker-atropos"
              fi
            '';
          };

          discordCanary = pkgs.symlinkJoin {
            name = "discord-canary-wayland";
            paths = [ pkgs.discord-canary ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/DiscordCanary \
                --add-flags "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer" \
                --add-flags "--ozone-platform-hint=auto"
            '';
          };

          vesktopWayland = pkgs.symlinkJoin {
            name = "vesktop-wayland";
            paths = [ pkgs.vesktop ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/vesktop \
                --add-flags "--enable-features=UseOzonePlatform,WebRTCPipeWireCapturer" \
                --add-flags "--ozone-platform-hint=auto"
            '';
          };

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
        in {
          imports = [
            inputs.zen-browser.homeModules.beta
            ./home-manager/md-preview.nix
            ./home-manager/niri.nix
            ./home-manager/minecraft.nix
            ./home-manager/streaming.nix
          ];

          home.username = "jaren";
          home.homeDirectory = "/home/jaren";
          home.stateVersion = "25.05";
          home.sessionPath = [ "$HOME/.local/bin" ];

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
            pkgs.uv
            pkgs.python3
            pkgs.libreoffice
            pkgs.fastfetch
            pkgs.zathura
            pkgs.basedpyright
            pkgs.codex
            pkgs.codex-acp
            pkgs.piper
            pkgs.pavucontrol
            discordCanary
            pkgs.eza
            pkgs.yazi
            pkgs.ruff
            pkgs.blender
            pkgs.code-cursor
            pkgs.cargo
            pkgs.obsidian
            pkgs.pi-coding-agent
            pkgs.pi-acp
            hermes
            hermesBootstrap
            hermesSetup
            hermesUpdate
            inputs.rose-pine-hyprcursor.packages.${pkgs.stdenv.hostPlatform.system}.default
            inputs.canvas-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
          ];

          programs.mcsr = {
            enable = true;
            ninjabrain = {
              enable = true;
              jvmArgs = [ "-Dswing.defaultlaf=javax.swing.plaf.metal.MetalLookAndFeel" ];
            };
            obs.enable = true;
            waywall = {
              enable = true;
              configSource = ../config/waywall;
            };
          };
          programs.game-streaming.enable = true;

          programs.zed-editor = {
            enable = true;
            package = pkgs.master.zed-editor;
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
                pi-acp = {
                  type = "custom";
                  command = lib.getExe pkgs.pi-acp;
                  args = [ ];
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
        home-manager.extraSpecialArgs = { inherit inputs; };
      }
    ];
  };
}
