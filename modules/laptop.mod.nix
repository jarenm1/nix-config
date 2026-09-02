{ self, ... }:
{
  flake.nixosModules.laptop.imports = [
    self.nixosModules.default
    self.nixosModules.home
    self.nixosModules.remote-build-client
  ];
}
