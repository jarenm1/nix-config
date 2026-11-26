{ ... }:
{
  # systemd pets the hardware watchdog while PID 1 is responsive. If the kernel or PID 1 wedges, the watchdog
  # reboots the machine instead of leaving it unreachable until someone is physically there. The reboot itself is
  # also bounded, so a hung shutdown cannot stall forever. Hosts without a watchdog device just skip this.
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "30s";
    RebootWatchdogSec = "10min";
  };
}
