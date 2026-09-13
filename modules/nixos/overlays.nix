{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.niri.overlays.niri
    (final: prev: {
      bun_1_3_14 = prev.bun.overrideAttrs (_: {
        version = "1.3.14";
        src = final.fetchurl {
          url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.14/bun-linux-x64.zip";
          hash = "sha256-lR7iruhV8IWVruxiJSJqKY0/6oOj3NZGXAnLzN9+hI8=";
        };
      });
      t4-code = final.callPackage ../../pkgs/t4-code.nix { };
      tern = final.callPackage ../../pkgs/tern.nix { };
      sober = final.writeShellScriptBin "sober" ''
        exec ${final.gamemode}/bin/gamemoderun ${final.flatpak}/bin/flatpak run --system --file-forwarding org.vinegarhq.Sober "$@"
      '';
      vinegar = final.writeShellScriptBin "vinegar" ''
        exec ${final.gamemode}/bin/gamemoderun ${final.flatpak}/bin/flatpak run --system --file-forwarding org.vinegarhq.Vinegar "$@"
      '';
      herdr = prev.herdr.overrideAttrs (old: {
        NIX_LDFLAGS = (old.NIX_LDFLAGS or "") + " --no-eh-frame-hdr";
      });
      master = import inputs.nixpkgs-master {
        system = prev.stdenv.hostPlatform.system;
        config = prev.config;
        overlays = [ inputs.niri.overlays.niri ];
      };
    })
  ];
}
