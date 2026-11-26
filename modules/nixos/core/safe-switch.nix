{ config, pkgs, ... }:
let
  stateDir = "/run/safe-switch";
  timer = "safe-switch-rollback";

  # `switch-to-configuration test` leaves the boot default alone, so a reboot at any point before `confirm` lands on
  # the generation that was running before. The rollback timer is a transient unit: it outlives this shell, the ssh
  # session that started it, and a switch that drops that session.
  safeSwitch = pkgs.writeShellApplication {
    name = "safe-switch";
    runtimeInputs = [
      config.nix.package
      config.systemd.package
      pkgs.coreutils
      pkgs.util-linux
    ];
    text = ''
      state=${stateDir}
      timer=${timer}
      self=$(readlink -f "$0")

      log() { echo "safe-switch: $*" >&2; }
      die() { log "$*"; exit 1; }
      usage() {
        cat >&2 <<'EOF'
      usage: safe-switch [--minutes N] <toplevel>   test-activate <toplevel>; roll back unless confirmed (default 5 min)
             safe-switch confirm [<toplevel>]       make the armed system the boot default
      EOF
        exit 2
      }

      # Children get fd 9 closed so the lock is not held by anything this script starts.
      switch() { "$1/bin/switch-to-configuration" "$2" 9>&-; }

      rollback_now() {
        local previous
        previous=$(<"$state/previous")
        rm -f "$state/armed"
        log "rolling back to $previous"
        if ! switch "$previous" test; then
          log "ROLLBACK FAILED: $previous did not activate cleanly; see the journal"
          return 1
        fi
        log "rolled back to $previous"
      }

      arm() {
        local minutes=5 toplevel previous
        while [ "$#" -gt 1 ]; do
          case "$1" in
            --minutes) minutes=$2; shift 2 ;;
            *) usage ;;
          esac
        done
        [ "$#" -eq 1 ] || usage
        case "$minutes" in
          ""|*[!0-9]*) die "--minutes takes a whole number" ;;
        esac
        [ "$minutes" -ge 1 ] || die "--minutes must be at least 1"

        toplevel=$(readlink -f "$1")
        [ -x "$toplevel/bin/switch-to-configuration" ] || die "$1 is not a NixOS system"
        [ ! -e "$state/armed" ] || die "a switch is already armed; confirm it or let it roll back first"

        previous=$(readlink -f /run/current-system)
        printf '%s\n' "$previous" >"$state/previous"
        printf '%s\n' "$toplevel" >"$state/target"
        rm -f "$state/confirmed"
        : >"$state/armed"

        systemctl stop "$timer.timer" "$timer.service" 2>/dev/null || true
        if ! systemd-run --quiet --unit="$timer" --description="safe-switch rollback" \
          --on-active="$minutes"m --timer-property=AccuracySec=1s --collect "$self" rollback 9>&-; then
          rm -f "$state/armed"
          die "cannot arm the rollback timer; nothing was switched"
        fi
        log "armed: $previous comes back in $minutes min unless confirmed"

        if ! switch "$toplevel" test; then
          log "switch to $toplevel failed"
          rollback_now || true
          exit 1
        fi
        log "$toplevel is running; run 'safe-switch confirm' within $minutes min"
      }

      rollback() {
        if [ -e "$state/confirmed" ] || [ ! -e "$state/armed" ]; then
          log "nothing to roll back"
          return 0
        fi
        rollback_now
      }

      confirm() {
        local target
        if [ -e "$state/armed" ]; then
          target=$(<"$state/target")
          if [ "$#" -gt 0 ] && [ "$(readlink -f "$1")" != "$target" ]; then
            die "the armed system is $target, not $1"
          fi
          : >"$state/confirmed"
          rm -f "$state/armed"
          systemctl stop "$timer.timer" 2>/dev/null || true
        elif [ -e "$state/confirmed" ]; then
          target=$(<"$state/target")
          log "already confirmed; making $target the boot default again"
        else
          die "nothing is armed: the switch was rolled back or never started"
        fi

        nix-env --profile /nix/var/nix/profiles/system --set "$target"
        switch "$target" boot
        log "$target is the boot default"
      }

      [ "$#" -ge 1 ] || usage
      [ "$(id -u)" -eq 0 ] || die "run as root (sudo safe-switch ...)"
      mkdir -p "$state"
      chmod 0700 "$state"
      exec 9>"$state/lock"
      flock 9

      case "$1" in
        confirm) shift; confirm "$@" ;;
        rollback) rollback ;;
        -h|--help) usage ;;
        *) arm "$@" ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [ safeSwitch ];
}
