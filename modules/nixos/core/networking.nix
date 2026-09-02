{ ... }:
{
  networking.networkmanager.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
