{ self, inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    checks = {
      host-box = pkgs.testers.runNixOSTest (import ../tests/host.nix { inherit self inputs; host = "box"; });
      host-desktop = pkgs.testers.runNixOSTest (import ../tests/host.nix { inherit self inputs; host = "desktop"; });
      host-laptop = pkgs.testers.runNixOSTest (import ../tests/host.nix { inherit self inputs; host = "laptop"; });
      safe-switch = pkgs.testers.runNixOSTest ../tests/safe-switch.nix;
    };
  };
}
