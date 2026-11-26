# Coding agents get their own account. They run as `agent`, not jaren: no wheel, no docker (root-equivalent),
# no access to jaren's home or keys. Production is read-only to them (a Postgres reader role, granted in
# orthyra-delta.nix); everything they write goes to disposable sandboxes (`nix run .#sandbox`), which need
# /dev/kvm. jaren enters the account with `ssh agent@localhost`.
#
# Their slice yields to everything else: production capture and jaren's own work keep CPU, IO and memory.
{ inputs, pkgs, ... }:
let
  uid = 1100;
in
{
  users.users.agent = {
    isNormalUser = true;
    inherit uid;
    description = "Coding agents";
    extraGroups = [ "kvm" ];
    # Same omp build as jaren's; the repo's `nix develop` supplies everything project-specific.
    packages = [
      (import ../../pkgs/omp.nix { inherit inputs pkgs; })
      pkgs.git
      pkgs.jujutsu
      pkgs.gh
      pkgs.just
      pkgs.tern
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIATNVX7O7yskFbJEuLellnTZRbpnweyh4lWEjya7hMCw jaren@claude-byob-testing"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINpEQ7RlZpS47hbqbObr3y1O9FjNeN3/34e41Wd1gmit tern@laptop"
    ];
    # Agent services and sandboxes keep running after the ssh session ends.
    linger = true;
  };

  # Agents push over ssh with a deploy key; pin GitHub's host key instead of trusting on first use.
  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  # Tern reaches agent sessions through the agent's own Tern remote service: jaren's Tern (here or on the
  # laptop over the tailnet) opens tabs that run as `agent`. UDP 8377 is reachable only where the firewall
  # trusts the interface (lo, tailscale0); no relay; jaren's ssh key is the only login. The host key lives
  # in the state dir, so the fingerprint pinned in jaren's ~/.config/tern/known_hosts stays valid.
  systemd.user.services.tern-remote-agent = {
    description = "Tern remote sessions (agent)";
    unitConfig = {
      ConditionUser = "agent";
      StartLimitIntervalSec = 60;
      StartLimitBurst = 10;
    };
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.tern}/bin/tern remote serve --user --listen [::]:8377 --relay none --authorized-keys /etc/ssh/authorized_keys.d/agent --state-dir %h/.config/tern";
      Restart = "on-failure";
      RestartSec = 2;
      RestartPreventExitStatus = 2;
      # Session daemons (and the agents in them) outlive a service restart.
      KillMode = "process";
      TimeoutStopSec = 10;
    };
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
