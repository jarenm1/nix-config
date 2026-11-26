# deploy <host>: the supported way to switch a host. Run from the repo root: nix run .#deploy -- <host>
#
# 1. The host's boot check (checks.x86_64-linux.host-<host>) must pass.
# 2. The new system closure is copied to the host (skipped when run on the host itself).
# 3. `safe-switch` activates it in test mode with a rollback deadline armed.
# 4. Once the host answers, `safe-switch confirm` makes the new system the boot default.
#
# If the host never answers, it rolls itself back at the deadline; this script needs nothing from it to do that.
# DEPLOY_USER (default jaren) and DEPLOY_ADDRESS (default: the host name) override the ssh target.

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  echo "usage: nix run .#deploy -- <host>" >&2
  exit 2
fi

host=$1
user=${DEPLOY_USER:-jaren}
address=${DEPLOY_ADDRESS:-$host}
ssh_target="$user@$address"
deadline_min=5
# Must stay below the deadline so the rollback cannot race a confirm this script is about to send.
wait_s=180

say() { echo "deploy: $*" >&2; }
die() { say "$*"; exit 1; }

say "checking host-$host"
nix build --no-link ".#checks.x86_64-linux.host-$host" \
  || die "host-$host check failed; nothing was copied or switched"

toplevel=$(nix build --no-link --print-out-paths ".#nixosConfigurations.$host.config.system.build.toplevel")

local=false
if [ "$(uname -n)" = "$host" ]; then
  local=true
fi

# Runs a root command on the host, locally or over ssh with a tty for the sudo prompt.
host_sudo() {
  if [ "$local" = true ]; then
    sudo "$@"
  else
    ssh -t "$ssh_target" sudo "$@"
  fi
}

# Reachability over ssh plus the two services a bad switch takes down. Read-only, so safe to repeat.
healthy() {
  if [ "$local" = true ]; then
    systemctl is-active --quiet sshd.service tailscaled.service
  else
    ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_target" \
      systemctl is-active --quiet sshd.service tailscaled.service 2>/dev/null
  fi
}

if [ "$local" = false ]; then
  say "copying $toplevel to $ssh_target"
  # Locally built paths are unsigned; the ssh connection is the trust boundary.
  nix copy --no-check-sigs --to "ssh-ng://$ssh_target" "$toplevel"
fi

say "arming $host: test-activating $toplevel, rolling back in $deadline_min min unless confirmed"
status=0
host_sudo safe-switch --minutes "$deadline_min" "$toplevel" || status=$?
if [ "$status" -ne 0 ]; then
  # 255 is ssh dropping the connection, which a switch that restarts sshd causes. Any other status means safe-switch
  # refused or failed; it rolls back a switch it started by itself.
  if [ "$local" = true ] || [ "$status" -ne 255 ]; then
    die "safe-switch exited $status on $host (see its output above)"
  fi
  say "ssh dropped during the switch; waiting for $host to answer"
fi

waited=0
until healthy; do
  if [ "$waited" -ge "$wait_s" ]; then
    die "$host did not answer within ${wait_s}s; it rolls back at the $deadline_min min deadline. Do not confirm."
  fi
  sleep 5
  waited=$((waited + 5))
done

# Units that crash right after activation show up a little later than the first answer.
sleep 15
healthy || die "$host stopped answering after the switch; it rolls back at the $deadline_min min deadline. Do not confirm."

say "$host answers; confirming $toplevel"
host_sudo safe-switch confirm "$toplevel" \
  || die "confirm failed on $host; check 'safe-switch' state there, since the rollback may already have run"
say "$host is on $toplevel and is the boot default"
