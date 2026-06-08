{ inputs, ... }:

let
  system = "x86_64-linux";
in
{
  flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = [
      ./nixos/overlays.nix
      inputs.niri.nixosModules.niri
      ./nixos/niri.nix
      ./nixos/base.nix
      ./nixos/fonts.nix
      ./nixos/gaming.nix
      ./nixos/desktop-nvidia.nix
      ./nixos/docker.nix
      ../hosts/nixos/hardware.nix
      inputs.home-manager.nixosModules.home-manager
      ({ pkgs, ... }: {
        networking.hostName = "nixos";

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.jaren = {
          imports = [ ./home-manager/jaren.nix ];
          jaren.home.extraPackages = with pkgs; [
            dbeaver-bin
            cursor-cli
            zellij
          ];
        };
        home-manager.extraSpecialArgs = { inherit inputs; };
      })
    ];
  };
}
