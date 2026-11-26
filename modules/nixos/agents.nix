# Coding agents get their own account. They run as `agent`, not jaren: no wheel, no docker (root-equivalent),
# no access to jaren's home or keys. Production is read-only to them (a Postgres reader role, granted in
# orthyra-delta.nix); everything they write goes to disposable sandboxes (`nix run .#sandbox`), which need
# /dev/kvm. jaren enters the account with `ssh agent@localhost`.
#
# Their slice yields to everything else: production capture and jaren's own work keep CPU, IO and memory.
{ ... }:
let
  uid = 1100;
in
{
  users.users.agent = {
    isNormalUser = true;
    inherit uid;
    description = "Coding agents";
    extraGroups = [ "kvm" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIATNVX7O7yskFbJEuLellnTZRbpnweyh4lWEjya7hMCw jaren@claude-byob-testing"
    ];
    # Agent services and sandboxes keep running after the ssh session ends.
    linger = true;
  };

  systemd.slices."user-${toString uid}" = {
    overrideStrategy = "asDropin";
    sliceConfig = {
      CPUWeight = 20;
      IOWeight = 20;
      MemoryHigh = "60%";
      MemoryMax = "75%";
    };
  };
}
