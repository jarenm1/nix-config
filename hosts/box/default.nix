{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  home-manager.users.jaren.jaren.home.extraPackages = with pkgs; [
    ardour
    blockbench
    surge-XT
    carla
    qpwgraph
    marimo
    dbeaver-bin
    cursor-cli
    zellij
    visualvm
  ];
}
