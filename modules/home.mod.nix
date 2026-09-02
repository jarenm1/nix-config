{ inputs, self, ... }:
{
  flake.homeModules.jaren = import ./home-manager/jaren.nix;
  flake.homeModules.default.imports = [ self.homeModules.jaren ];

  flake.nixosModules.home = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = { inherit inputs; };
    home-manager.users.jaren.imports = [ self.homeModules.default ];
  };
}
