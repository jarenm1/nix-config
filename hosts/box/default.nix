{ inputs, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    # Receives desktop's off-site Delta backup mirror (chrooted SFTP account, /srv/delta-backup).
    inputs.orthyra.nixosModules.backupTarget
  ];

  services.deltaBackupTarget.authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILcJpsh1yNC0J6XYHY6Bh1Nb1+6Z2zGypb9+2OT+eiAh delta-backup@desktop"
  ];

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
