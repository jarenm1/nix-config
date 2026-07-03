{ lib, pkgs, ... }:
{
  imports = [
    ./audio.nix
    ./portals.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

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

  users.users.jaren = {
    isNormalUser = true;
    description = "jaren";
    extraGroups = [ "networkmanager" "wheel" "ydotool" "uinput" "video" ];
    shell = pkgs.nushell;
  };

  programs.ydotool.enable = true;

  nixpkgs.config.allowUnfree = true;

  hardware.graphics = {
    enable = true;
  };
  hardware.uinput.enable = true;
  hardware.bluetooth.enable = true;

  environment.systemPackages = [
    pkgs.vim
    pkgs.kitty
    pkgs.nushell
    pkgs.mesa-demos
    pkgs.vulkan-tools
  ];

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

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

  services.ratbagd.enable = true;
  services.tailscale.enable = true;
  services.openssh.enable = true;
  services.gnome.gnome-keyring.enable = true;

  system.stateVersion = "25.05";
}
