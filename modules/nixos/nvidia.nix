{ config, ... }:
{
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  boot.kernelParams = [
    "rd.driver.blacklist=nouveau"
    "modprobe.blacklist=nouveau"
    "nvidia-drm.modeset=1"
  ];
  boot.extraModprobeConfig = ''
    blacklist nouveau
    options nouveau modeset=0
  '';

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
