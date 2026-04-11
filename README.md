Idk if this works

# header

## Markdown preview over SSH

This config now installs `md-preview`, a tiny local Markdown preview server.

- Run `md-preview README.md` on the remote machine.
- If you're connected over SSH, forward the port with `ssh -L 6419:127.0.0.1:6419 <host>`.
- Open `http://127.0.0.1:6419` in your local browser.

It renders standard Markdown with Pandoc, supports Mermaid fences, and auto-reloads when the file changes.

## Sunshine + Moonlight

This config now includes:

- Sunshine on the NixOS host
- `moonlight-qt` plus helper commands in home-manager
- a `Prism Launcher` stream target in Sunshine

Host setup after switching:

- Run `sunshine-set-creds <username> <password>`
- Restart Sunshine with `systemctl --user restart sunshine`
- Open `https://<host>:47990`

Client helpers:

- `moonlight-pair-host [host]`
- `moonlight-stream-prism [host]`
- `moonlight-stream-desktop [host]`

If you add a laptop config to this repo later, import `modules/home-manager/streaming.nix` there and enable `programs.game-streaming.enable = true;`.

Host-side helpers:

- `prism-stream-launcher`
- `prism-stream-instance <instance-id>`
