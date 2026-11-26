{ ... }:
{
  imports = [
    ./core/boot.nix
    ./core/locale.nix
    ./core/users.nix
    ./core/nix.nix
    ./core/btrfs.nix
    ./core/networking.nix
    ./core/hardware.nix
    ./core/packages.nix
    ./core/services.nix
    ./core/safe-switch.nix
    ./core/watchdog.nix
    ./core/disk-guard.nix
  ];

  system.stateVersion = "25.05";
}
