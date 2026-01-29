{ pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/hyprland.nix
    ../../modules/nixos/fonts.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  users.users.jaren= {
    isNormalUser = true;
    description = "jaren";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.nushell;
  };

  nixpkgs.config.allowUnfree = true;

  hardware.bluetooth.enable = true;

  environment.systemPackages = [
    pkgs.vim
    pkgs.kitty
    pkgs.nushell
  ];

  networking.firewall.allowedTCPPorts = [ 8081 22 19000 19001 19002 19003 19004 19005 19006 ];
  networking.firewall.allowedUDPPorts = [ 8081 22 19000 19001 19002 19003 19004 19005 19006 ];
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;

  programs.gamemode.enable = true;
  services.tailscale.enable = true;
  services.openssh.enable = true;

  system.stateVersion = "25.05";
}
