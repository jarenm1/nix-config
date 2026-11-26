{ pkgs, ... }:
{
  # Metadata chunks can't grow without unallocated device space. When metadata
  # hits 100% every write stalls (ENOSPC, processes stuck in D state). A weekly
  # data balance repacks mostly-empty data chunks back into unallocated space.
  systemd.services.btrfs-balance-root = {
    description = "Reclaim unallocated btrfs space for metadata";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.btrfs-progs}/bin/btrfs balance start --full-balance -dusage=50 /";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.btrfs-balance-root = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
}
