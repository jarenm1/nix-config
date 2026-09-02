{ ... }:
{
  flake.nixosModules = {
    remote-build-host = import ./nixos/remote-build-host.nix;
    remote-build-client = import ./nixos/remote-build-client.nix;
  };
}
