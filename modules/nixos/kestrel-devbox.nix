# Kestrel hackathon: lets teammates develop on this machine.
# - One unprivileged Linux account per teammate (no wheel/sudo). `video` covers the GPU for NVENC.
# - Tailscale SSH: teammates log in through the tailnet; the tailnet policy decides who maps to which user.
# - The production Kestrel box listens on 127.0.0.1:8787 without auth; only jaren's processes may reach it.
{ pkgs, ... }:
let
  # Linux names must be lowercase; map GitHub logins to these in the Tailscale SSH policy.
  devs = [ "caayd" "stinkycat0" ];
  prodBoxPort = "8787";
  rule = "OUTPUT -o lo -p tcp --dport ${prodBoxPort} -m owner ! --uid-owner jaren -j REJECT";
in
{
  users.users = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = {
        isNormalUser = true;
        description = "kestrel dev";
        extraGroups = [ "video" ];
        shell = pkgs.bash;
      };
    }) devs
  );

  services.tailscale.extraSetFlags = [ "--ssh" ];

  networking.firewall.extraCommands = ''
    iptables -w -C ${rule} 2>/dev/null || iptables -w -I ${rule}
  '';
  networking.firewall.extraStopCommands = ''
    iptables -w -D ${rule} 2>/dev/null || true
  '';
}
