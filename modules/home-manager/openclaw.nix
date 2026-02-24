# Openclaw AI Assistant Gateway Module
# This module properly packages the config and documents in the nix store

{ pkgs, inputs, config, lib, ... }:

let
  # Package the documents in the nix store
  openclawDocuments = pkgs.stdenv.mkDerivation {
    name = "openclaw-documents";
    src = ../openclaw-documents;
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out/
    '';
  };

  # Create the openclaw config as a nix store package
  openclawConfig = pkgs.writeTextFile {
    name = "openclaw-config.json";
    text = builtins.toJSON {
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
  };
in
{
  imports = [
    inputs.nix-openclaw.homeManagerModules.openclaw
  ];

  # Apply the nix-openclaw overlay
  nixpkgs.overlays = [ inputs.nix-openclaw.overlays.default ];

  programs.openclaw = {
    enable = true;
    # Use the packaged documents from nix store
    documents = openclawDocuments;
    
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
      plugins = [
        # Add plugins here as needed
      ];
    };
  };

  # Ensure the config file is properly linked
  home.file.".openclaw/openclaw.json" = {
    source = openclawConfig;
    force = true;
  };
}
