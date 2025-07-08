{ config, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/default.nix
  ];
  
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    useOSProber = true;
    efiSupport = true;
  };
  
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
    packages = with pkgs; [];
    shell = pkgs.nushell;  
  };
  
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "jaren" = import ./home.nix;
    };
  };
  
  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = with pkgs; [
    vim
    kitty
    nushell
  ];
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  system.stateVersion = "25.05";
}