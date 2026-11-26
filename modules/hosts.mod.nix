{ inputs, self, ... }:
let
  system = "x86_64-linux";

  # Each host is one module, so the boot check in checks.mod.nix runs exactly what `nixosConfigurations` builds.
  hostModule = name: profile: hostPath: {
    imports = [
      self.nixosModules.${profile}
      hostPath
      { networking.hostName = name; }
    ];
  };

  mkHost = module: inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = [ module ];
  };
in
{
  flake.nixosModules = {
    host-box = hostModule "box" "desktop" ../hosts/box;
    host-desktop = hostModule "desktop" "desktop" ../hosts/desktop;
    host-laptop = hostModule "laptop" "laptop" ../hosts/laptop;
  };

  flake.nixosConfigurations = {
    box = mkHost self.nixosModules.host-box;
    desktop = mkHost self.nixosModules.host-desktop;
    laptop = mkHost self.nixosModules.host-laptop;
  };
}
