# NixOS configuration

Pure NixOS configuration for two machines:

- `desktop`: Nvidia, gaming, Docker, and remote build host.
- `laptop`: remote build client without desktop gaming packages.

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
