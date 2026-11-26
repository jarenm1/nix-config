{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
    # This machine is the Delta production host. Box shares the desktop profile and must not run these.
    ../../modules/nixos/orthyra-delta.nix
    ../../modules/nixos/orthyra-ci.nix
    ../../modules/nixos/agents.nix
  ];

  systemd.slices.user.sliceConfig.ManagedOOMSwap = "kill";

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
