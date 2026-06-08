{ inputs, ... }:
{
  nixpkgs.overlays = [
    inputs.niri.overlays.niri
    (final: prev: {
      pi-acp = final.callPackage ../../pkgs/pi-acp.nix { };
      master = import inputs.nixpkgs-master {
        system = prev.stdenv.hostPlatform.system;
        config = prev.config;
        overlays = [
          inputs.niri.overlays.niri
          (masterFinal: _: {
            pi-acp = masterFinal.callPackage ../../pkgs/pi-acp.nix { };
          })
        ];
      };
    })
  ];
}
