{ ... }:
{
  imports = [
    ./core/boot.nix
    ./core/locale.nix
    ./core/users.nix
    ./core/nix.nix
    ./core/networking.nix
    ./core/hardware.nix
    ./core/packages.nix
    ./core/services.nix
  ];

  system.stateVersion = "25.05";
}
