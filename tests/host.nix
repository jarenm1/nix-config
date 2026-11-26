# Boots one host's real module set (profile + hosts/<host>) in a VM and checks that it comes up healthy, then runs
# `switch-to-configuration test` and checks again. Only hardware and network-bound services are replaced; see the
# comments in `nodes.machine`.
{ self, inputs, host }:
let
  # The desktop profile (used by box and desktop) imports the gaming module, which brings nix-flatpak. The laptop
  # profile does not.
  hasFlatpak = host != "laptop";

  # The managed flatpak install fetches flathub at activation, which the VM sandbox cannot reach.
  flatpakStub = { lib, ... }: {
    services.flatpak = {
      remotes = lib.mkForce [ ];
      packages = lib.mkForce [ ];
      update.onActivation = lib.mkForce false;
    };
  };

  # The CI runner registers with GitHub using a token file that exists only on the real machine.
  ciRunnerStub = { lib, ... }: {
    services.github-runners.orthyra.enable = lib.mkForce false;
  };
in
{
  name = "host-${host}";

  # Host modules set overlays and allowUnfree, so the test node must own its nixpkgs instance.
  node.pkgsReadOnly = false;
  node.specialArgs = { inherit inputs; };

  nodes.machine = { lib, ... }: {
    imports = [ self.nixosModules."host-${host}" ]
      ++ lib.optional hasFlatpak flatpakStub
      ++ lib.optional (host == "desktop") ciRunnerStub;

    # The VM has no disks, GPU, NPU, or microcode, so the host's hardware.nix is dropped and the test disk stands in
    # for it. The rest of the host configuration boots as written.
    disabledModules = [ (../hosts + "/${host}/hardware.nix") ];

    # The nvidia module loads kernel modules that only the real GPU driver build provides.
    boot.initrd.kernelModules = lib.mkForce [ ];
    services.xserver.videoDrivers = lib.mkForce [ ];

    # The test runs switch-to-configuration itself, so the script must be in the closure.
    system.switch.enable = true;

    virtualisation.memorySize = 4096;
  };

  testScript = { nodes, ... }:
    let
      toplevel = nodes.machine.system.build.toplevel;
    in
    ''
      # Units that need hardware this VM does not have. Empty: any failure is a real failure.
      hardware_bound_units = []

      def check_healthy(stage):
          machine.wait_for_unit("multi-user.target")
          failed = [
              line.split()[0]
              for line in machine.succeed("systemctl --failed --plain --no-legend").splitlines()
              if line.strip()
          ]
          unexpected = [unit for unit in failed if unit not in hardware_bound_units]
          assert not unexpected, f"{stage}: failed units: {unexpected}"
          machine.wait_for_open_port(22)
          machine.succeed("systemctl is-active --quiet tailscaled.service")
          # A umask leak in an activation snippet once left /etc/passwd unreadable. Activation must keep these modes.
          modes = machine.succeed("stat -L -c %a /etc/passwd /etc/group").split()
          assert modes == ["644", "644"], f"{stage}: /etc/passwd and /etc/group modes are {modes}"
          machine.succeed("runuser -u jaren -- getent passwd jaren")

      check_healthy("boot")
      machine.succeed("${toplevel}/bin/switch-to-configuration test")
      check_healthy("after switch-to-configuration test")
    '';
}
