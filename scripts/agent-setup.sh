#!/usr/bin/env bash
# One-time setup after adding the CI runner and the `agent` account. Idempotent: safe to rerun.
# Run as jaren from a real terminal (it asks for your sudo password, and optionally a GitHub token).
set -euo pipefail
repo=jarenm1/orthyra

echo "== CI runner registration token (valid one hour, used once at the switch)"
gh api -X POST "repos/$repo/actions/runners/registration-token" --jq .token |
  sudo install -D -m 0600 /dev/stdin /var/lib/orthyra-ci/runner.token

echo "== switch"
sudo nixos-rebuild switch --flake "$HOME/nix-config#desktop"

as_agent() { sudo -u agent -H "$@"; }

echo "== agent ssh key, registered as a push-capable deploy key on $repo only"
as_agent bash -c 'test -f ~/.ssh/id_ed25519 || { mkdir -p -m 700 ~/.ssh; ssh-keygen -q -t ed25519 -N "" -C agent@desktop -f ~/.ssh/id_ed25519; }'
pub=$(as_agent cat /home/agent/.ssh/id_ed25519.pub | cut -d' ' -f1,2)
if ! gh api "repos/$repo/keys" --jq '.[].key' | grep -qxF "$pub"; then
  gh api "repos/$repo/keys" -f title=agent@desktop -f key="$pub" -F read_only=false --silent
fi

echo "== agent git identity and orthyra clone"
as_agent git config --global user.name "Orthyra agent"
as_agent git config --global user.email "agent@desktop"
as_agent bash -c "test -d ~/orthyra || git clone git@github.com:$repo.git ~/orthyra"
as_agent bash -c 'cd ~/orthyra && { test -d .jj || jj git init --colocate; }'

echo "== omp settings (not credentials) copied from jaren"
sudo install -D -o agent -g users -m 0600 "$HOME/.omp/agent/config.yml" /home/agent/.omp/agent/config.yml

if ! as_agent gh auth status >/dev/null 2>&1; then
  cat <<'EOF'
== GitHub token for opening PRs (optional; skip with Enter)
Create a fine-grained token at https://github.com/settings/personal-access-tokens/new
  Repository access: only jarenm1/orthyra
  Permissions: Contents read/write, Pull requests read/write (nothing else)
EOF
  read -r -s -p "token: " token
  echo
  if [ -n "$token" ]; then
    printf '%s' "$token" | as_agent gh auth login --with-token
    as_agent gh auth setup-git
  fi
fi

echo "== done. Remaining: \`ssh agent@localhost\`, run omp, /login once for model access."
