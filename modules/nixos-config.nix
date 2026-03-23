# Flake Parts Module for NixOS Configuration
{ inputs, config, lib, flake-parts-lib, ... }:

let
  system = "x86_64-linux";
  pkgs = inputs.nixpkgs.legacyPackages.${system};
in
{
  flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = [
      # Apply overlays system-wide
      ({ lib, pkgs, ... }: {
        nixpkgs.overlays = [
          inputs.niri.overlays.niri
        ];
      })
      
      # Import Niri NixOS module
      inputs.niri.nixosModules.niri
      
      # Enable niri
      ./nixos/niri.nix
      # System configuration
      ({ pkgs, ... }: {
        imports = [
          ../hosts/nixos/hardware-configuration.nix
        ];

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        networking.hostName = "nixos";
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
          extraGroups = [ "networkmanager" "wheel" ];
          shell = pkgs.nushell;
        };

        nixpkgs.config.allowUnfree = true;

        hardware.bluetooth.enable = true;

        environment.systemPackages = [
          pkgs.vim
          pkgs.kitty
          pkgs.nushell
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
        services.tailscale.enable = true;
        services.openssh.enable = true;

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
        in {
          imports = [
            inputs.zen-browser.homeModules.beta
            ./home-manager/niri.nix
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
            pkgs.pavucontrol
            pkgs.discord
            pkgs.eza
            pkgs.yazi
            hermes
            hermesBootstrap
            hermesSetup
            hermesUpdate
            inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
            inputs.canvas-cli.packages.${pkgs.system}.default
          ];

          programs.zed-editor.enable = true;
          programs.ghostty.enable = true;
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
        };
        home-manager.extraSpecialArgs = { inherit inputs; };
      }
    ];
  };
}
