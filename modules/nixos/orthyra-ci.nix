# Self-hosted GitHub Actions runner for jarenm1/orthyra. CI jobs (`nix flake check`, including the NixOS
# VM tests) run here instead of on paid GitHub minutes.
#
# The runner is a sandboxed DynamicUser service (the upstream module's hardening): no access to /home, the
# docker socket, or production data (Postgres peer auth has no role for it; S3 keys are root-only). Builds
# go through the Nix daemon, so VM tests get /dev/kvm via the daemon's `kvm` system feature.
#
# Registration: the token file holds a one-hour registration token, used once; the runner keeps its own
# credentials in its state directory afterwards. To (re)register:
#   gh api -X POST repos/jarenm1/orthyra/actions/runners/registration-token -q .token \
#     | sudo install -D -m 0600 /dev/stdin /var/lib/orthyra-ci/runner.token
#   sudo systemctl restart github-runner-orthyra
{ pkgs, ... }:
{
  services.github-runners.orthyra = {
    enable = true;
    url = "https://github.com/jarenm1/orthyra";
    tokenFile = "/var/lib/orthyra-ci/runner.token";
    tokenType = "registration";
    replace = true;
    extraLabels = [
      "nix"
      "kvm"
    ];
    extraPackages = with pkgs; [
      git
      jujutsu
    ];
    # Production shares this machine: CI yields CPU and disk to it.
    serviceOverrides = {
      Nice = 10;
      CPUWeight = 20;
      IOWeight = 20;
    };
  };
}
