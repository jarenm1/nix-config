{ inputs, self, ... }:
let
  system = "x86_64-linux";

  mkHost = name: profile: hostModule: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = [
      self.nixosModules.${profile}
      hostModule
      { networking.hostName = name; }
    ];
  };
in
{
  flake.nixosConfigurations = {
    desktop = mkHost "desktop" "desktop" ../hosts/desktop;
    laptop = mkHost "laptop" "laptop" ../hosts/laptop;
  };
}
