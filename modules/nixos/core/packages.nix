{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    vim
    kitty
    nushell
    mesa-demos
    vulkan-tools
  ];
}
