# Proves safe-switch on a real boot with a real bootloader: an unconfirmed switch that breaks sshd is rolled back by its
# deadline; a power cut before confirmation boots the previous generation; a confirmed switch becomes the boot default.
{
  name = "safe-switch";

  nodes.machine = { lib, ... }: {
    imports = [ ../modules/nixos/core/safe-switch.nix ];

    services.openssh.enable = true;
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = false;
    virtualisation.useBootLoader = true;
    virtualisation.useEFIBoot = true;

    specialisation = {
      # Drops sshd: the machine stays up but unreachable over the network, like the box incident.
      broken.configuration.services.openssh.enable = lib.mkForce false;
      good.configuration.environment.etc."safe-switch-test".text = "good\n";
    };
  };

  testScript = { nodes, ... }:
    let
      top = nodes.machine.system.build.toplevel;
    in
    ''
      def current():
          return machine.succeed("readlink -f /run/current-system").strip()

      machine.wait_for_unit("multi-user.target")
      machine.wait_for_open_port(22)
      base = current()
      broken = machine.succeed("readlink -f ${top}/specialisation/broken").strip()
      good = machine.succeed("readlink -f ${top}/specialisation/good").strip()

      # 1. Unconfirmed switch that drops sshd: the deadline restores the running system and sshd comes back.
      machine.succeed(f"safe-switch --minutes 1 {broken}")
      machine.wait_for_closed_port(22)
      assert current() == broken, current()
      machine.succeed("test -e /run/safe-switch/armed")
      machine.wait_until_succeeds(f"test \"$(readlink -f /run/current-system)\" = {base}", timeout=300)
      machine.wait_for_open_port(22)
      machine.fail("test -e /run/safe-switch/armed")

      # 2. Unconfirmed switch, then a power cut: the boot default was never changed, so the old generation boots.
      machine.succeed(f"safe-switch --minutes 30 {good}")
      assert current() == good, current()
      machine.crash()
      machine.start()
      machine.wait_for_unit("multi-user.target")
      assert current() == base, current()
      machine.fail("test -e /run/safe-switch/armed")

      # 3. Confirmed switch: it survives the original deadline and a reboot, and is the boot default.
      machine.succeed(f"safe-switch --minutes 1 {good}")
      machine.succeed(f"safe-switch confirm {good}")
      machine.sleep(90)
      assert current() == good, current()
      assert machine.succeed("readlink -f /nix/var/nix/profiles/system").strip() == good
      entry = machine.succeed("sed -n 's/^default //p' /boot/loader/loader.conf").strip()
      machine.succeed(f"grep -qF {good} /boot/loader/entries/{entry}")
      machine.shutdown()
      machine.start()
      machine.wait_for_unit("multi-user.target")
      assert current() == good, current()
    '';
}
