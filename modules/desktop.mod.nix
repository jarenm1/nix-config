{ inputs, self, ... }:
{
  flake.nixosModules = {
    audio = import ./nixos/audio.nix;
    portals = import ./nixos/portals.nix;
    niri = {
      imports = [
        inputs.niri.nixosModules.niri
        (import ./nixos/niri.nix)
      ];
    };
    gaming = import ./nixos/gaming.nix;
    docker = import ./nixos/docker.nix;
    nvidia = import ./nixos/nvidia.nix;
  };

  flake.nixosModules.desktop.imports = [
    self.nixosModules.default
    self.nixosModules.home
    self.nixosModules.gaming
    self.nixosModules.docker
    self.nixosModules.nvidia
    self.nixosModules.remote-build-host
  ];

  flake.nixosModules.default.imports = [
    self.nixosModules.audio
    self.nixosModules.portals
    self.nixosModules.niri
  ];
}
