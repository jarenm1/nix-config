{ self, ... }:
{
  flake.nixosModules = {
    overlays = import ./nixos/overlays.nix;
    core = import ./nixos/core.nix;
    fonts = import ./nixos/fonts.nix;
    keyring = import ./nixos/keyring.nix;
    session = import ./nixos/session.nix;
  };

  flake.nixosModules.default.imports = [
    self.nixosModules.overlays
    self.nixosModules.core
    self.nixosModules.fonts
    self.nixosModules.keyring
    self.nixosModules.session
  ];
}
