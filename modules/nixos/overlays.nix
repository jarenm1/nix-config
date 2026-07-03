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
      oh-my-pi = final.callPackage ../../pkgs/oh-my-pi.nix {
        bun = final.bun_1_3_14;
      };
      master = import inputs.nixpkgs-master {
        system = prev.stdenv.hostPlatform.system;
        config = prev.config;
        overlays = [ inputs.niri.overlays.niri ];
      };
    })
  ];
}
