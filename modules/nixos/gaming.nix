{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];

  hardware.graphics.enable32Bit = true;

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  services.flatpak = {
    enable = true;
    update.onActivation = true;
    packages = [
      "org.vinegarhq.Sober"
    ];
  };

  environment.systemPackages = [
    pkgs.sober
  ];
}
