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
    unreal-engine = import ./nixos/unreal-engine.nix;
    docker = import ./nixos/docker.nix;
    nvidia = import ./nixos/nvidia.nix;
    kestrel-devbox = import ./nixos/kestrel-devbox.nix;
    orthyra-delta = import ./nixos/orthyra-delta.nix;
    orthyra-ci = import ./nixos/orthyra-ci.nix;
    agents = import ./nixos/agents.nix;
  };

  flake.nixosModules.desktop.imports = [
    self.nixosModules.default
    self.nixosModules.home
    self.nixosModules.gaming
    self.nixosModules.unreal-engine
    self.nixosModules.docker
    self.nixosModules.nvidia
    self.nixosModules.remote-build-host
    self.nixosModules.kestrel-devbox
    self.nixosModules.orthyra-delta
    self.nixosModules.orthyra-ci
    self.nixosModules.agents
  ];

  flake.nixosModules.default.imports = [
    self.nixosModules.audio
    self.nixosModules.portals
    self.nixosModules.niri
  ];
}
