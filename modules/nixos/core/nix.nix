{ ... }:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.builders-use-substitutes = true;
  nix.settings.max-jobs = 8;
  nix.settings.min-free = 5 * 1024 * 1024 * 1024;
  nix.settings.max-free = 20 * 1024 * 1024 * 1024;
  nix.settings.trusted-users = [ "jaren" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
}
