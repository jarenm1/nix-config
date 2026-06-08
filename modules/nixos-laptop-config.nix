{ inputs, ... }:

let
  system = "x86_64-linux";
in
{
  flake.nixosConfigurations.laptop = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = [
      ./nixos/overlays.nix
      inputs.niri.nixosModules.niri
      ./nixos/niri.nix
      ./nixos/base.nix
      ./nixos/fonts.nix
      ./nixos/gaming.nix
      ../hosts/laptop/hardware.nix
      inputs.home-manager.nixosModules.home-manager
      {
        networking.hostName = "laptop";

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.jaren.imports = [ ./home-manager/jaren.nix ];
        home-manager.extraSpecialArgs = { inherit inputs; };
      }
    ];
  };
}
