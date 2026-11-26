# NixOS configuration

Pure NixOS configuration for two machines:

- `desktop`: Nvidia, gaming, Unreal Engine, Docker, and remote build host.
- `laptop`: remote build client without desktop gaming packages.

The desktop enables systemd-oomd swap monitoring for user applications. Under
severe memory and swap pressure, it may terminate an application to preserve responsiveness.

## Structure

- `hosts/`: hardware and machine-specific facts.
- `modules/*.mod.nix`: recursively discovered flake-parts registration and composition modules.
- `modules/nixos/`: reusable NixOS implementations.
- `modules/home-manager/`: reusable Home Manager implementations.
- `pkgs/`: local packages.

The module graph follows NCC's pattern: leaf modules register named `flake.nixosModules` or `flake.homeModules`, aggregate modules compose them, and host declarations select the `desktop` or `laptop` aggregate. Add or remove a capability in the corresponding aggregate instead of duplicating a `nixosSystem` module list.

Build or inspect a host with:

```sh
nix build .#nixosConfigurations.desktop.config.system.build.toplevel
nix build .#nixosConfigurations.laptop.config.system.build.toplevel
```

## Checks and safe switching

- `nix flake check` boots each host's real module set in a VM (`checks.x86_64-linux.host-<name>`), with only the
  hardware replaced by the VM's disk, then runs `switch-to-configuration test` and checks again. Checks that
  pass here do not prove the GPU, NPU, or firmware work on real hardware.
- `safe-switch` (installed on every host) tests a new system with a rollback deadline: `sudo safe-switch <toplevel>`
  rolls back unless `sudo safe-switch confirm` runs in time. A reboot before confirmation boots the old generation.
- `nix run .#deploy -- <host>` runs the host check, copies the closure, switches with the deadline armed, and
  confirms only after the host answers. A host that stops answering rolls itself back.
- Hardware watchdog reboots a wedged machine; `disk-guard` logs a journal warning when `/` drops below 10% free.

Bootstrap: a host must already run `safe-switch` before `deploy` can use it. Switch each host once by hand
(`sudo nixos-rebuild switch --flake .#<host>`) and watch it come back before relying on `deploy`.
