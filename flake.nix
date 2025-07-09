{
  description = "my nixos config";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = inputs@{ nixpks, home-manager, ... }: {
  nixosConfigurations = {
    system = "x86_64-linux";
    modules = [
      ./hosts/default/configuration.nix
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.jaren = ./hosts/default/home.nix;
        home-manager.extraSpecialArgs = { inherit inputs; };
      }
    ]
  }
  }
}
