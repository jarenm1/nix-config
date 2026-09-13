{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];

  hardware.graphics.enable32Bit = true;

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  services.flatpak = {
    enable = true;
    update.onActivation = true;
    packages = [
      "org.vinegarhq.Sober"
      "org.vinegarhq.Vinegar"
    ];
  };

  # Studio's detached Qt tool windows render black under Wine's Wayland
  # driver; force XWayland.
  services.flatpak.overrides."org.vinegarhq.Vinegar".Context.sockets = [ "!wayland" ];

  environment.systemPackages = [
    pkgs.sober
    pkgs.vinegar
  ];

  # Start GameMode outside the sandbox; portal registration can fail on the host.
  # Keep app-menu and Roblox URL launches on the same path as the CLI wrappers.
  home-manager.users.jaren.xdg.desktopEntries = {
    "org.vinegarhq.Vinegar" = {
      name = "Vinegar";
      genericName = "Roblox Studio";
      icon = "org.vinegarhq.Vinegar";
      exec = "${pkgs.vinegar}/bin/vinegar @@u %u @@";
      terminal = false;
      categories = [ "Development" "Game" ];
      mimeType = [
        "application/x-roblox-place"
        "application/x-roblox-model"
        "x-scheme-handler/roblox-studio"
        "x-scheme-handler/roblox-studio-auth"
      ];
      settings."X-Flatpak" = "org.vinegarhq.Vinegar";
      actions.manage = {
        name = "Manage";
        exec = "${pkgs.vinegar}/bin/vinegar manage";
      };
    };
    "org.vinegarhq.Sober" = {
      name = "Sober";
      genericName = "Roblox Player";
      icon = "org.vinegarhq.Sober";
      exec = "${pkgs.sober}/bin/sober -- @@u %u @@";
      terminal = false;
      categories = [ "Game" ];
      mimeType = [
        "x-scheme-handler/roblox"
        "x-scheme-handler/roblox-player"
      ];
      settings."X-Flatpak" = "org.vinegarhq.Sober";
      actions.open-settings = {
        name = "Settings";
        exec = "${pkgs.sober}/bin/sober config";
      };
    };
  };
}
