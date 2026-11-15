{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim
    git
    kitty
    nushell
    mesa-demos
    vulkan-tools
  ];
}
