{ inputs, ... }:
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    policies = {
      Preferences = {
        "dom.webgpu.enabled" = true;
        "gfx.webgpu.force-enabled" = true;
      };
    };
    extraPrefs = ''
      pref("dom.webgpu.enabled", true);
      pref("gfx.webgpu.force-enabled", true);
    '';
  };
}
