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
      ({ pkgs, ... }: {
        nixpkgs.overlays = [
          inputs.nix-openclaw.overlays.default
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
        home-manager.users.jaren = { pkgs, inputs, ... }: {
          imports = [
            inputs.zen-browser.homeModules.beta
            inputs.nix-openclaw.homeManagerModules.openclaw
            ./home-manager/niri.nix
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
            pkgs.fastfetch
            pkgs.zathura
            pkgs.basedpyright
            inputs.codex.packages.${pkgs.system}.default
            inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default
            inputs.canvas-cli.packages.${pkgs.system}.default
          ];

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

          # Openclaw with properly packaged config
          nixpkgs.overlays = [ inputs.nix-openclaw.overlays.default ];
          
          programs.openclaw = {
            enable = true;
            # Package documents in nix store - use string path relative to flake root
            documents = "${inputs.self}/openclaw-documents";
            
            config = {
              gateway = {
                mode = "local";
                auth = {
                  token = "fee62b8b128be2dabeef4ed6e38ba1fbcba2064f17a753b95e0ee48274d7375f7129259c229646afc9d2a2ea621a11fcc78e951e2ccb36cd1c430bfbcc74684c";
                };
              };
              channels.telegram = {
                tokenFile = "/home/jaren/.secrets/telegram-bot-token";
                allowFrom = [ "8545827554" ];
                groups = {
                  "*" = { requireMention = true; };
                };
              };
            };

            instances.default = {
              enable = true;
              plugins = [];
            };
          };
        };
        home-manager.extraSpecialArgs = { inherit inputs; };
      }
    ];
  };
}
