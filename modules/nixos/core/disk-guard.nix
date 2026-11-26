{ lib, pkgs, ... }:
let
  # Only warns. Deciding what to delete belongs to the owner: a full root is usually Nix generations or build output,
  # and garbage collection can remove generations a rollback still needs.
  diskGuard = pkgs.writeShellApplication {
    name = "disk-guard";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.util-linux
    ];
    text = ''
      used=$(df --output=pcent / | tail -n 1 | tr -dc '0-9')
      free=$((100 - used))
      if [ "$free" -lt 10 ]; then
        logger -p user.warning -t disk-guard "/ has only ''${free}% free; review generations before running nix-collect-garbage"
      fi
      echo "disk-guard: / has ''${free}% free"
    '';
  };
in
{
  systemd.services.disk-guard = {
    description = "Warn in the journal when / is nearly full";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = lib.getExe diskGuard;
    };
  };

  systemd.timers.disk-guard = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
