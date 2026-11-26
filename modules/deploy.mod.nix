{ ... }:
{
  perSystem = { pkgs, ... }:
    let
      deploy = pkgs.writeShellApplication {
        name = "deploy";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.nix
          pkgs.openssh
        ];
        text = builtins.readFile ../scripts/deploy.sh;
      };
    in
    {
      apps.deploy = {
        type = "app";
        program = pkgs.lib.getExe deploy;
      };
    };
}
