{ pkgs, ... }:
{
  users.users.jaren = {
    isNormalUser = true;
    description = "jaren";
    extraGroups = [ "networkmanager" "wheel" "ydotool" "uinput" "video" ];
    shell = pkgs.nushell;
  };

  programs.ydotool.enable = true;
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "jaren" ];
  };
}
