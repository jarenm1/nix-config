# Main NixOS Configuration - Flake Parts Module
{ inputs, config, lib, pkgs, ... }:

{
  flake.nixosConfigurations.nixos = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      # Import the dendritic nixos modules
      ./nixos/system.nix
      ./nixos/hyprland.nix
      ./nixos/fonts.nix
      
      # Home manager module
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.jaren = { pkgs, inputs, ... }: {
          imports = [
            # Import dendritic home-manager modules
            ./home-manager/base.nix
            ./home-manager/openclaw.nix
          ];
        };
        home-manager.extraSpecialArgs = { inherit inputs; };
      }
    ];
  };
}
